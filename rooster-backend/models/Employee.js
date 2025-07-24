const mongoose = require('mongoose');

const employeeSchema = new mongoose.Schema({
  // Company Association
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true,
    index: true
  },
  firstName: {
    type: String,
    required: true,
    trim: true
  },
  lastName: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    trim: true,
    lowercase: true
  },
  employeeId: {
    type: String,
    required: true,
    trim: true
  },
  hireDate: {
    type: Date,
    default: Date.now
  },
  position: {
    type: String,
    trim: true
  },
  department: {
    type: String,
    trim: true
  },
  hourlyRate: {
    type: Number,
    default: 0,
    min: 0,
  },
  monthlySalary: {
    type: Number,
    default: 0,
    min: 0,
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
  },
  isActive: {
    type: Boolean,
    default: true
  },
  employeeType: {
    type: String,
    enum: ['Permanent', 'Temporary'],
    default: 'Permanent',
  },
  employeeSubType: {
    type: String,
    enum: ['Full-time', 'Part-time', 'Casual', null],
    default: null,
  },
  
  // Enterprise Features - Multi-Location Support
  locationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Location',
    index: true
  },
  
  // Enterprise Features - Performance Management
  performanceLevel: {
    type: String,
    enum: ['entry', 'junior', 'intermediate', 'senior', 'expert', 'lead'],
    default: 'entry'
  },
  lastPerformanceReview: {
    type: Date
  },
  nextPerformanceReview: {
    type: Date
  },
  
  // Enterprise Features - Training Management
  trainingHistory: [{
    trainingId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Training'
    },
    status: {
      type: String,
      enum: ['assigned', 'enrolled', 'in_progress', 'completed', 'failed', 'dropped'],
      default: 'assigned'
    },
    enrolledAt: Date,
    completedAt: Date,
    score: Number,
    certificate: {
      filename: String,
      url: String,
      issuedAt: Date
    }
  }],
  
  // Enterprise Features - Expense Management
  expenseLimit: {
    type: Number,
    min: 0,
    default: 0
  },
  expenseApprover: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  
  // Additional employee fields
  manager: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  emergencyContact: {
    name: String,
    relationship: String,
    phone: String,
    email: String
  },
  skills: [{
    type: String,
    trim: true
  }],
  certifications: [{
    name: String,
    issuer: String,
    issueDate: Date,
    expiryDate: Date,
    certificateUrl: String
  }],
  notes: {
    type: String,
    trim: true
  }
});

// Compound unique indexes for company-specific uniqueness
employeeSchema.index({ companyId: 1, email: 1 }, { unique: true });
employeeSchema.index({ companyId: 1, employeeId: 1 }, { unique: true });

const Employee = mongoose.model('Employee', employeeSchema);

module.exports = Employee; 