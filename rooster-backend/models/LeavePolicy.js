const mongoose = require('mongoose');

const LeavePolicySchema = new mongoose.Schema({
  // Company Association
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true,
    index: true
  },
  
  // Policy Name (e.g., "Standard Policy", "Executive Policy")
  name: {
    type: String,
    required: true,
    trim: true
  },
  
  // Policy Description
  description: {
    type: String,
    trim: true
  },
  
  // Leave Type Entitlements
  leaveTypes: {
    annualLeave: {
      totalDays: { type: Number, default: 12, min: 0 },
      description: { type: String, default: 'Annual Leave' },
      isActive: { type: Boolean, default: true }
    },
    sickLeave: {
      totalDays: { type: Number, default: 10, min: 0 },
      description: { type: String, default: 'Sick Leave' },
      isActive: { type: Boolean, default: true }
    },
    casualLeave: {
      totalDays: { type: Number, default: 5, min: 0 },
      description: { type: String, default: 'Casual Leave' },
      isActive: { type: Boolean, default: true }
    },
    maternityLeave: {
      totalDays: { type: Number, default: 90, min: 0 },
      description: { type: String, default: 'Maternity Leave' },
      isActive: { type: Boolean, default: true }
    },
    paternityLeave: {
      totalDays: { type: Number, default: 10, min: 0 },
      description: { type: String, default: 'Paternity Leave' },
      isActive: { type: Boolean, default: true }
    },
    unpaidLeave: {
      totalDays: { type: Number, default: 0, min: 0 },
      description: { type: String, default: 'Unpaid Leave' },
      isActive: { type: Boolean, default: true }
    }
  },
  
  // Policy Rules
  rules: {
    // Minimum notice period (in days)
    minNoticeDays: { type: Number, default: 1, min: 0 },
    
    // Maximum consecutive leave days
    maxConsecutiveDays: { type: Number, default: 30, min: 1 },
    
    // Whether leave can be taken in half days
    allowHalfDays: { type: Boolean, default: false },
    
    // Whether leave can be cancelled after approval
    allowCancellation: { type: Boolean, default: true },
    
    // Whether leave balance carries over to next year
    carryOverBalance: { type: Boolean, default: false },
    
    // Maximum carry over days
    maxCarryOverDays: { type: Number, default: 5, min: 0 },
    
    // Leave year start month (1-12)
    leaveYearStartMonth: { type: Number, default: 1, min: 1, max: 12 },
    
    // Leave year start day (1-31)
    leaveYearStartDay: { type: Number, default: 1, min: 1, max: 31 }
  },
  
  // Policy Status
  isActive: {
    type: Boolean,
    default: true
  },
  
  // Whether this is the default policy for the company
  isDefault: {
    type: Boolean,
    default: false
  },
  
  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now
  },
  
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Update the updatedAt field before saving
LeavePolicySchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

// Index for efficient queries
LeavePolicySchema.index({ companyId: 1, isActive: 1 });
LeavePolicySchema.index({ companyId: 1, isDefault: 1 });

module.exports = mongoose.model('LeavePolicy', LeavePolicySchema); 