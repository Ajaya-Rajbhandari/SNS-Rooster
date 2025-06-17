const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

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
  // Ensure name is not sent if it was part of the old schema and not cleaned up
  delete userObject.name; 
  userObject.isProfileComplete = this.isProfileComplete;
  // Add firstName and lastName to the public profile
  userObject.firstName = this.firstName;
  userObject.lastName = this.lastName;
  // Add combined name field for frontend compatibility
  userObject.name = this.firstName && this.lastName ? `${this.firstName} ${this.lastName}` : (this.firstName || this.lastName || null);
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