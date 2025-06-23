const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const fs = require('fs');
const path = require('path');

const userSchema = new mongoose.Schema({
  document: {
    type: String, // File path or URL for uploaded document
    trim: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
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
    enum: ['admin', 'employee'],
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
  avatar: {
    type: String, // File path or URL
    trim: true,
  },
  passport: {
    type: String, // File path or URL
    trim: true,
  },
  idCard: {
    type: String, // File path or URL for uploaded ID card
    trim: true,
  },
  documents: [
    {
      type: { type: String, trim: true }, // e.g., 'idCard', 'passport'
      path: { type: String, trim: true },
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
  resetPasswordToken: String,
  resetPasswordExpires: Date,
}, {
  timestamps: true,
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
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

userSchema.methods.recalculateProfileComplete = function() {
  // Only require fields employees can fill themselves
  const requiredFields = [
    'firstName',
    'lastName',
    'email',
    'phone',
    'address',
    'emergencyContact',
    'emergencyPhone'
  ];
  this.isProfileComplete = requiredFields.every(field => {
    return this[field] && String(this[field]).trim().length > 0;
  });
};
const User = mongoose.model('User', userSchema);

module.exports = User;