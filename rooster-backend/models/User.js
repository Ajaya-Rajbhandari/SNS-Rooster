const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const fs = require('fs');
const path = require('path');

const userSchema = new mongoose.Schema({
  // Company Association
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: function() {
      // Super admins don't need to belong to a company
      return this.role !== 'super_admin';
    },
    index: true
  },
  document: {
    type: String, // File path or URL for uploaded document
    trim: true,
  },
  email: {
    type: String,
    required: true,
    trim: true,
    lowercase: true,
  },
  password: {
    type: String,
    required: true,
  },
  firstName: {
    type: String,
    required: true,
    trim: true,
  },
  lastName: {
    type: String,
    required: true,
    trim: true,
  },
  role: {
    type: String,
    enum: ['super_admin', 'admin', 'employee'],
    default: 'employee',
  },
  department: {
    type: String,
    trim: true,
  },
  position: {
    type: String,
    trim: true,
  },
  phone: {
    type: String,
    trim: true,
  },
  address: {
    type: String,
    trim: true,
  },
  emergencyContact: {
    type: String,
    trim: true,
  },
  emergencyPhone: {
    type: String,
    trim: true,
  },
  emergencyRelationship: {
    type: String,
    trim: true,
  },
  avatar: {
    type: String, // File path or URL
    trim: true,
  },
  
  // Email verification fields
  isEmailVerified: {
    type: Boolean,
    default: false,
  },
  emailVerificationToken: {
    type: String,
  },
  emailVerificationExpires: {
    type: Date,
  },
  
  // Password reset fields (enhanced)
  resetPasswordToken: String,
  resetPasswordExpires: Date,
  resetPasswordAttempts: {
    type: Number,
    default: 0,
  },
  resetPasswordLastAttempt: Date,
  
  // Account security
  failedLoginAttempts: {
    type: Number,
    default: 0,
  },
  accountLockedUntil: Date,
  
  documents: [
    {
      type: { type: String, trim: true }, // e.g., 'idCard', 'passport'
      path: { type: String, trim: true },
      status: { type: String, enum: ['pending', 'verified', 'rejected'], default: 'pending' },
      verifiedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      verifiedAt: { type: Date }
    }
  ],
  education: [
    {
      institution: { type: String, trim: true },
      degree: { type: String, trim: true },
      fieldOfStudy: { type: String, trim: true },
      startDate: { type: Date },
      endDate: { type: Date },
      certificate: { type: String, trim: true } // File path or URL
    }
  ],
  certificates: [
    {
      name: { type: String, trim: true },
      file: { type: String, trim: true } // File path or URL
    }
  ],
  isProfileComplete: {
    type: Boolean,
    default: false,
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  lastLogin: {
    type: Date,
  },
}, {
  timestamps: true,
});

// Hash password before saving (only if not already hashed)
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  // Skip if password is already hashed (starts with $2b$)
  if (this.password && this.password.startsWith('$2b$')) {
    return next();
  }
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Method to compare password
userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Method to get public profile (exclude sensitive data)
userSchema.methods.getPublicProfile = function() {
  const userObject = this.toObject();
  delete userObject.password;
  delete userObject.resetPasswordToken;
  delete userObject.resetPasswordExpires;
  delete userObject.name;

  userObject.isProfileComplete = this.isProfileComplete;
  userObject.firstName = this.firstName;
  userObject.lastName = this.lastName;
  userObject.name = this.firstName && this.lastName ? `${this.firstName} ${this.lastName}` : (this.firstName || this.lastName || null);

  // Always use the DB value, fallback only if missing
  userObject.avatar = this.avatar && this.avatar.trim() !== '' ? this.avatar : '/uploads/avatars/default-avatar.png';
  userObject.profilePicture = this.profilePicture && this.profilePicture.trim() !== '' ? this.profilePicture : '/uploads/avatars/default-avatar.png';

  return userObject;
};

userSchema.methods.recalculateProfileComplete = async function() {
  // Get admin settings to determine what sections are required
  const AdminSettings = require('./AdminSettings');
  let settings;
  try {
    settings = await AdminSettings.getSettings();
  } catch (error) {
    console.log('Could not load admin settings, using defaults');
    // Fallback to defaults if settings can't be loaded
    settings = {
      educationSectionEnabled: true,
      certificatesSectionEnabled: true,
      requiredProfileFields: [
        'firstName',
        'lastName',
        'email',
        'phone',
        'address',
        'emergencyContact',
        'emergencyPhone'
      ]
    };
  }

  // Base required fields that employees can fill themselves
  const requiredFields = settings.requiredProfileFields || [
    'firstName',
    'lastName',
    'email',
    'phone',
    'address',
    'emergencyContact',
    'emergencyPhone'
  ];

  // Check if base fields are complete
  let isComplete = requiredFields.every(field => {
    return this[field] && String(this[field]).trim().length > 0;
  });

  // If education section is enabled and user has education entries,
  // require at least basic information for each entry
  if (isComplete && settings.educationSectionEnabled && this.education && this.education.length > 0) {
    isComplete = this.education.every(edu => {
      return edu.institution && edu.degree && edu.fieldOfStudy &&
             edu.institution.trim().length > 0 && 
             edu.degree.trim().length > 0 && 
             edu.fieldOfStudy.trim().length > 0;
    });
  }

  // If certificates section is enabled and user has certificate entries,
  // require at least basic information for each entry
  if (isComplete && settings.certificatesSectionEnabled && this.certificates && this.certificates.length > 0) {
    isComplete = this.certificates.every(cert => {
      return cert.name && cert.name.trim().length > 0;
    });
  }

  this.isProfileComplete = isComplete;
};

// Account security methods
userSchema.virtual('isLocked').get(function() {
  return !!(this.accountLockedUntil && this.accountLockedUntil > Date.now());
});

userSchema.methods.incrementLoginAttempts = function() {
  // If we have previous failed attempts and now we're past the lock time
  if (this.accountLockedUntil && this.accountLockedUntil < Date.now()) {
    return this.updateOne({
      $unset: {
        failedLoginAttempts: 1,
        accountLockedUntil: 1
      }
    });
  }
  
  const updates = { $inc: { failedLoginAttempts: 1 } };
  
  // Lock account after 4 failed attempts for 2 hours
  if (this.failedLoginAttempts + 1 >= 4 && !this.isLocked) {
    updates.$set = {
      accountLockedUntil: Date.now() + 2 * 60 * 60 * 1000 // 2 hours
    };
  }
  
  return this.updateOne(updates);
};

userSchema.methods.resetLoginAttempts = function() {
  return this.updateOne({
    $unset: {
      failedLoginAttempts: 1,
      accountLockedUntil: 1
    }
  });
};

// Email verification methods
userSchema.methods.generateEmailVerificationToken = function() {
  const crypto = require('crypto');
  const token = crypto.randomBytes(32).toString('hex');
  this.emailVerificationToken = token;
  this.emailVerificationExpires = Date.now() + 24 * 60 * 60 * 1000; // 24 hours
  return token;
};

userSchema.methods.verifyEmail = function() {
  this.isEmailVerified = true;
  this.emailVerificationToken = undefined;
  this.emailVerificationExpires = undefined;
  return this.save();
};

// Password reset security
userSchema.methods.canRequestPasswordReset = function() {
  const now = Date.now();
  const oneHour = 60 * 60 * 1000;
  
  // Limit to 3 reset attempts per hour
  if (this.resetPasswordAttempts >= 3 && 
      this.resetPasswordLastAttempt && 
      (now - this.resetPasswordLastAttempt.getTime()) < oneHour) {
    return false;
  }
  
  return true;
};

userSchema.methods.incrementPasswordResetAttempts = function() {
  const now = Date.now();
  const oneHour = 60 * 60 * 1000;
  
  // Reset counter if more than an hour has passed
  if (this.resetPasswordLastAttempt && 
      (now - this.resetPasswordLastAttempt.getTime()) >= oneHour) {
    this.resetPasswordAttempts = 1;
  } else {
    this.resetPasswordAttempts = (this.resetPasswordAttempts || 0) + 1;
  }
  
  this.resetPasswordLastAttempt = new Date();
  return this.save();
};

// Compound unique index for email within company
userSchema.index({ companyId: 1, email: 1 }, { unique: true });

const User = mongoose.model('User', userSchema);

module.exports = User;