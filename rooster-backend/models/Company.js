const mongoose = require('mongoose');

const companySchema = new mongoose.Schema({
  // Basic Information
  name: { 
    type: String, 
    required: true,
    trim: true
  },
  domain: { 
    type: String, 
    unique: true, 
    required: true,
    trim: true,
    lowercase: true
  },
  subdomain: { 
    type: String, 
    unique: true, 
    required: true,
    trim: true,
    lowercase: true
  },
  
  // Contact Information
  adminEmail: { 
    type: String, 
    required: true,
    trim: true,
    lowercase: true
  },
  contactPhone: {
    type: String,
    trim: true
  },
  // Additional company details
  phone: {
    type: String,
    trim: true
  },
  email: {
    type: String,
    trim: true,
    lowercase: true
  },
  website: {
    type: String,
    trim: true
  },
  industry: {
    type: String,
    trim: true
  },
  size: {
    type: String,
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  contactPerson: {
    type: String,
    trim: true
  },
  contactEmail: {
    type: String,
    trim: true,
    lowercase: true
  },
  address: {
    street: { type: String, trim: true },
    city: { type: String, trim: true },
    state: { type: String, trim: true },
    postalCode: { type: String, trim: true },
    country: { type: String, trim: true, default: 'Nepal' }
  },
  
  // Subscription & Billing
  subscriptionPlan: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'SubscriptionPlan',
    required: false // Allow null for custom plans
  },
  isCustomPlan: {
    type: Boolean,
    default: false
  },
  customPlanData: {
    features: {
      attendance: { type: Boolean, default: true },
      payroll: { type: Boolean, default: true },
      leaveManagement: { type: Boolean, default: true },
      analytics: { type: Boolean, default: false },
      documentManagement: { type: Boolean, default: true },
      notifications: { type: Boolean, default: true },
      customBranding: { type: Boolean, default: false },
      apiAccess: { type: Boolean, default: false },
      multiLocation: { type: Boolean, default: false },
      advancedReporting: { type: Boolean, default: false },
      timeTracking: { type: Boolean, default: true },
      expenseManagement: { type: Boolean, default: false },
      performanceReviews: { type: Boolean, default: false },
      trainingManagement: { type: Boolean, default: false }
    },
    limits: {
      maxEmployees: { type: Number, default: 10 },
      maxStorageGB: { type: Number, default: 5 },
      maxApiCallsPerDay: { type: Number, default: 1000 },
      maxLocations: { type: Number, default: 1 }
    }
  },
  subscriptionId: String, // Stripe subscription ID
  billingCycle: {
    type: String,
    enum: ['monthly', 'yearly'],
    default: 'monthly'
  },
  nextBillingDate: Date,
  trialEndDate: Date,
  
  // Super Admin Management
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  assignedSuperAdmin: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  notes: {
    type: String,
    trim: true
  },
  
  // Feature Configuration
  features: {
    attendance: { type: Boolean, default: true },
    payroll: { type: Boolean, default: true },
    leaveManagement: { type: Boolean, default: true },
    analytics: { type: Boolean, default: false },
    documentManagement: { type: Boolean, default: true },
    notifications: { type: Boolean, default: true },
    customBranding: { type: Boolean, default: false },
    apiAccess: { type: Boolean, default: false },
    multiLocation: { type: Boolean, default: false },
    advancedReporting: { type: Boolean, default: false },
    timeTracking: { type: Boolean, default: true },
    expenseManagement: { type: Boolean, default: false },
    performanceReviews: { type: Boolean, default: false },
    trainingManagement: { type: Boolean, default: false }
  },
  
  // Usage Limits
  limits: {
    maxEmployees: { type: Number, default: 50 },
    maxStorageGB: { type: Number, default: 5 },
    retentionDays: { type: Number, default: 365 },
    maxApiCallsPerDay: { type: Number, default: 1000 },
    maxLocations: { type: Number, default: 1 }
  },

  // Usage Tracking - NEW FIELDS
  usage: {
    currentEmployeeCount: { 
      type: Number, 
      default: 0,
      min: 0 
    },
    currentStorageGB: { 
      type: Number, 
      default: 0,
      min: 0 
    },
    currentApiCallsToday: { 
      type: Number, 
      default: 0,
      min: 0 
    },
    lastUsageUpdate: { 
      type: Date, 
      default: Date.now 
    },
    lastApiCallReset: { 
      type: Date, 
      default: Date.now 
    },
    // Daily usage tracking for analytics
    dailyUsage: {
      employeeCount: { type: Number, default: 0 },
      storageGB: { type: Number, default: 0 },
      apiCalls: { type: Number, default: 0 },
      date: { type: Date, default: Date.now }
    }
  },
  
  // Company Settings
  settings: {
    timezone: { type: String, default: 'UTC' },
    currency: { type: String, default: 'NPR' },
    dateFormat: { type: String, default: 'MM/DD/YYYY' },
    timeFormat: { type: String, default: '12' }, // 12 or 24
    workingDays: [{ 
      type: String, 
      default: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'] 
    }],
    workingHours: {
      start: { type: String, default: '09:00' },
      end: { type: String, default: '17:00' }
    },
    attendanceGracePeriod: { type: Number, default: 15 }, // minutes
    overtimeThreshold: { type: Number, default: 8 }, // hours
    leaveApprovalRequired: { type: Boolean, default: true },
    autoApproveLeave: { type: Boolean, default: false }
  },
  
  // Branding
  branding: {
    logo: String,
    primaryColor: { type: String, default: '#1976D2' },
    secondaryColor: { type: String, default: '#424242' },
    companyName: String,
    tagline: String
  },
  
  // Integrations
  integrations: {
    slack: {
      enabled: { type: Boolean, default: false },
      webhook: String,
      channel: String
    },
    email: {
      provider: { type: String, default: 'resend' },
      apiKey: String,
      fromEmail: String
    },
    calendar: {
      type: { 
        type: String, 
        enum: ['google', 'outlook', 'none'], 
        default: 'none' 
      },
      credentials: Object
    }
  },
  
  // Status & Metadata
  status: {
    type: String,
    enum: ['active', 'suspended', 'trial', 'expired', 'cancelled', 'archived'],
    default: 'trial' // Reverted back to trial for proper trial system
  },
  archived: {
    type: Boolean,
    default: false
  },
  archivedAt: {
    type: Date
  },
  archivedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  archiveReason: {
    type: String,
    trim: true
  },
  trialStartDate: { type: Date, default: Date.now },
  trialEndDate: { type: Date, default: function() {
    // Default to 1 week from creation
    const oneWeekFromNow = new Date();
    oneWeekFromNow.setDate(oneWeekFromNow.getDate() + 7);
    return oneWeekFromNow;
  }},
  trialDurationDays: { type: Number, default: 7 }, // 1 week trial
  trialExpired: { type: Boolean, default: false },
  trialExpiredDate: Date,
  trialSubscriptionPlan: { type: String, default: 'basic' }, // Which plan the trial is for
  trialPlanName: { type: String, default: 'Basic Trial' }, // Human-readable trial plan name
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
}, {
  timestamps: true
});

// Indexes for efficient queries
// Note: domain and subdomain already have unique indexes from schema definition
companySchema.index({ status: 1 });
companySchema.index({ archived: 1 });
companySchema.index({ 'subscriptionPlan': 1 });
companySchema.index({ createdAt: -1 });

// NEW INDEXES for usage tracking
companySchema.index({ 'usage.currentEmployeeCount': 1 });
companySchema.index({ 'usage.currentStorageGB': 1 });
companySchema.index({ 'usage.currentApiCallsToday': 1 });
companySchema.index({ 'usage.lastUsageUpdate': 1 });
companySchema.index({ 'usage.lastApiCallReset': 1 });

// Pre-save middleware to update the updatedAt field
companySchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

// Static method to find company by domain
companySchema.statics.findByDomain = function(domain) {
  return this.findOne({ 
    $or: [
      { domain: domain.toLowerCase() },
      { subdomain: domain.toLowerCase() }
    ]
  });
};

// Static method to find active companies
companySchema.statics.findActive = function() {
  return this.find({ status: 'active' });
};

// Instance method to check if feature is enabled
companySchema.methods.isFeatureEnabled = function(featureName) {
  return this.features[featureName] === true;
};

// Instance method to check if company is within limits
companySchema.methods.isWithinLimits = function(limitType, currentValue) {
  const limit = this.limits[limitType];
  return limit === null || currentValue <= limit;
};

// NEW METHODS for usage tracking
// Instance method to get current usage percentage
companySchema.methods.getUsagePercentage = function(usageType) {
  const currentUsage = this.usage[`current${usageType.charAt(0).toUpperCase() + usageType.slice(1)}`];
  const limit = this.limits[`max${usageType.charAt(0).toUpperCase() + usageType.slice(1)}`];
  
  if (!limit || limit === 0) return 0;
  return Math.round((currentUsage / limit) * 100);
};

// Instance method to check if usage is approaching limits (80% threshold)
companySchema.methods.isUsageWarning = function(usageType) {
  return this.getUsagePercentage(usageType) >= 80;
};

// Instance method to check if usage exceeds limits
companySchema.methods.isUsageExceeded = function(usageType) {
  return this.getUsagePercentage(usageType) >= 100;
};

// Instance method to update usage
companySchema.methods.updateUsage = function(usageType, value) {
  const usageField = `current${usageType.charAt(0).toUpperCase() + usageType.slice(1)}`;
  this.usage[usageField] = value;
  this.usage.lastUsageUpdate = new Date();
  return this.save();
};

// Instance method to increment usage
companySchema.methods.incrementUsage = function(usageType, increment = 1) {
  const usageField = `current${usageType.charAt(0).toUpperCase() + usageType.slice(1)}`;
  this.usage[usageField] += increment;
  this.usage.lastUsageUpdate = new Date();
  return this.save();
};

// Instance method to reset daily API calls
companySchema.methods.resetDailyApiCalls = function() {
  this.usage.currentApiCallsToday = 0;
  this.usage.lastApiCallReset = new Date();
  return this.save();
};

// Instance method to get usage summary
companySchema.methods.getUsageSummary = function() {
  return {
    employeeCount: {
      current: this.usage.currentEmployeeCount,
      limit: this.limits.maxEmployees,
      percentage: this.getUsagePercentage('employeeCount'),
      warning: this.isUsageWarning('employeeCount'),
      exceeded: this.isUsageExceeded('employeeCount')
    },
    storageGB: {
      current: this.usage.currentStorageGB,
      limit: this.limits.maxStorageGB,
      percentage: this.getUsagePercentage('storageGB'),
      warning: this.isUsageWarning('storageGB'),
      exceeded: this.isUsageExceeded('storageGB')
    },
    apiCallsToday: {
      current: this.usage.currentApiCallsToday,
      limit: this.limits.maxApiCallsPerDay,
      percentage: this.getUsagePercentage('apiCallsPerDay'),
      warning: this.isUsageWarning('apiCallsPerDay'),
      exceeded: this.isUsageExceeded('apiCallsPerDay')
    },
    lastUpdated: this.usage.lastUsageUpdate
  };
};

const Company = mongoose.model('Company', companySchema);

module.exports = Company; 