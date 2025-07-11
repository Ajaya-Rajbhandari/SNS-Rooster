const mongoose = require('mongoose');

const companySchema = new mongoose.Schema({
  // Basic Information
  name: { type: String, required: true },
  domain: { type: String, unique: true, required: true },
  subdomain: { type: String, required: true },
  
  // Contact Information
  adminEmail: { type: String, required: true },
  contactPhone: String,
  address: {
    street: String,
    city: String,
    state: String,
    postalCode: String,
    country: String
  },
  
  // Subscription & Billing
  subscriptionPlan: {
    type: String,
    enum: ['basic', 'professional', 'enterprise'],
    default: 'basic'
  },
  subscriptionId: String, // Stripe subscription ID
  billingCycle: {
    type: String,
    enum: ['monthly', 'yearly'],
    default: 'monthly'
  },
  nextBillingDate: Date,
  trialEndDate: Date,
  
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
  
  // Company Settings
  settings: {
    timezone: { type: String, default: 'UTC' },
    currency: { type: String, default: 'USD' },
    dateFormat: { type: String, default: 'MM/DD/YYYY' },
    timeFormat: { type: String, default: '12' }, // 12 or 24
    workingDays: [{ type: String, default: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'] }],
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
      type: { type: String, enum: ['google', 'outlook', 'none'], default: 'none' },
      credentials: Object
    }
  },
  
  // Status & Metadata
  status: {
    type: String,
    enum: ['active', 'suspended', 'trial', 'expired', 'cancelled'],
    default: 'trial'
  },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
}, {
  timestamps: true
});

// Indexes for efficient querying
companySchema.index({ domain: 1 });
companySchema.index({ subdomain: 1 });
companySchema.index({ status: 1 });
companySchema.index({ 'subscriptionPlan': 1 });

// Pre-save hook to update the updatedAt field
companySchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

// Static method to find company by domain
companySchema.statics.findByDomain = function(domain) {
  return this.findOne({ domain: domain, status: { $in: ['active', 'trial'] } });
};

// Static method to find company by subdomain
companySchema.statics.findBySubdomain = function(subdomain) {
  return this.findOne({ subdomain: subdomain, status: { $in: ['active', 'trial'] } });
};

// Instance method to check if feature is enabled
companySchema.methods.isFeatureEnabled = function(featureName) {
  return this.features[featureName] === true;
};

// Instance method to check if company is active
companySchema.methods.isActive = function() {
  return ['active', 'trial'].includes(this.status);
};

// Instance method to get company context for API responses
companySchema.methods.getCompanyContext = function() {
  return {
    id: this._id,
    name: this.name,
    domain: this.domain,
    subdomain: this.subdomain,
    features: this.features,
    settings: this.settings,
    branding: this.branding,
    status: this.status
  };
};

module.exports = mongoose.model('Company', companySchema); 