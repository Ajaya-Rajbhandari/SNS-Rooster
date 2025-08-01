const mongoose = require('mongoose');

const subscriptionPlanSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  price: {
    monthly: {
      type: Number,
      required: true,
      min: 0
    },
    yearly: {
      type: Number,
      required: true,
      min: 0
    }
  },
  // Flutter app fields
  employeeLimit: {
    type: Number,
    min: 1,
    default: function() {
      return this.features?.maxEmployees || 10;
    }
  },
  storageLimit: {
    type: Number,
    min: 1,
    default: 5
  },
  apiCallLimit: {
    type: Number,
    min: 0,
    default: 1000
  },
  // Admin portal fields
  features: {
    maxEmployees: {
      type: Number,
      required: true,
      min: 1
    },
    maxDepartments: {
      type: Number,
      required: true,
      min: 1
    },
    analytics: {
      type: Boolean,
      default: false
    },
    advancedReporting: {
      type: Boolean,
      default: false
    },
    customBranding: {
      type: Boolean,
      default: false
    },
    apiAccess: {
      type: Boolean,
      default: false
    },
    dataExport: {
      type: Boolean,
      default: false
    },
    profile: {
      type: Boolean,
      default: true
    },
    companyInfo: {
      type: Boolean,
      default: true
    },
    prioritySupport: {
      type: Boolean,
      default: false
    },
    dataRetention: {
      type: Number, // Days
      default: 365
    },
    backupFrequency: {
      type: String,
      enum: ['daily', 'weekly', 'monthly'],
      default: 'weekly'
    },
    // Enterprise Features
    locationBasedAttendance: {
      type: Boolean,
      default: false
    },
    multiLocationSupport: {
      type: Boolean,
      default: false
    },
    expenseManagement: {
      type: Boolean,
      default: false
    },
    performanceReviews: {
      type: Boolean,
      default: false
    },
    trainingManagement: {
      type: Boolean,
      default: false
    },
    // Core HR Features
    payroll: {
      type: Boolean,
      default: false
    },
    documentManagement: {
      type: Boolean,
      default: false
    },
    attendance: {
      type: Boolean,
      default: true
    },
    leaveManagement: {
      type: Boolean,
      default: true
    },
    timesheet: {
      type: Boolean,
      default: true
    },
    notifications: {
      type: Boolean,
      default: true
    },
    timeTracking: {
      type: Boolean,
      default: true
    },
    // Employee Features
    events: {
      type: Boolean,
      default: false
    },
    // Admin Features
    employeeManagement: {
      type: Boolean,
      default: true
    },
    timesheetApprovals: {
      type: Boolean,
      default: true
    },
    attendanceManagement: {
      type: Boolean,
      default: true
    },
    breakManagement: {
      type: Boolean,
      default: true
    },
    breakTypes: {
      type: Boolean,
      default: true
    },
    userManagement: {
      type: Boolean,
      default: true
    },
    settings: {
      type: Boolean,
      default: true
    },
    companySettings: {
      type: Boolean,
      default: true
    },
    featureManagement: {
      type: Boolean,
      default: false
    },
    helpSupport: {
      type: Boolean,
      default: true
    },
    // Location Management Features
    locationManagement: {
      type: Boolean,
      default: false
    },
    locationSettings: {
      type: Boolean,
      default: false
    },
    locationNotifications: {
      type: Boolean,
      default: false
    },
    locationGeofencing: {
      type: Boolean,
      default: false
    },
    locationCapacity: {
      type: Boolean,
      default: false
    }
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isDefault: {
    type: Boolean,
    default: false
  },
  sortOrder: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Ensure only one default plan exists
subscriptionPlanSchema.pre('save', async function(next) {
  if (this.isDefault) {
    await this.constructor.updateMany(
      { _id: { $ne: this._id } },
      { isDefault: false }
    );
  }
  next();
});

// Static method to get default plan
subscriptionPlanSchema.statics.getDefaultPlan = async function() {
  return await this.findOne({ isDefault: true, isActive: true });
};

// Static method to get active plans
subscriptionPlanSchema.statics.getActivePlans = async function() {
  return await this.find({ isActive: true }).sort('sortOrder');
};

module.exports = mongoose.model('SubscriptionPlan', subscriptionPlanSchema); 