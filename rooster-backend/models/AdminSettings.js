const mongoose = require('mongoose');

const adminSettingsSchema = new mongoose.Schema({
  // Company Association
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true,
    index: true
  },
  // Profile feature settings
  educationSectionEnabled: {
    type: Boolean,
    default: true,
  },
  certificatesSectionEnabled: {
    type: Boolean,
    default: true,
  },
  
  // Other admin settings
  notificationsEnabled: {
    type: Boolean,
    default: true,
  },
  darkModeEnabled: {
    type: Boolean,
    default: false,
  },
  
  // System settings
  maxFileUploadSize: {
    type: Number,
    default: 5 * 1024 * 1024, // 5MB in bytes
  },
  allowedFileTypes: {
    type: [String],
    default: ['pdf', 'jpg', 'jpeg', 'png'],
  },
  
  // Payroll cycle settings (nested object)
  payrollCycle: {
    frequency: {
      type: String,
      default: 'Monthly',
    },
    cutoffDay: {
      type: Number,
      default: 25,
    },
    payDay: {
      type: Number,
      default: 30,
    },
    payDay1: {
      type: Number,
      default: 15, // First pay day for semi-monthly (1st-15th period)
    },
    payWeekday: {
      type: Number,
      default: 5, // Day of week for weekly payroll (1=Mon, 5=Fri)
    },
    payOffset: {
      type: Number,
      default: 0,
    },
    overtimeEnabled: {
      type: Boolean,
      default: true,
    },
    overtimeMultiplier: {
      type: Number,
      default: 1.5,
    },
    autoGenerate: {
      type: Boolean,
      default: true,
    },
    notifyCycleClose: {
      type: Boolean,
      default: true,
    },
    notifyPayslip: {
      type: Boolean,
      default: true,
    },
    defaultHourlyRate: {
      type: Number,
      default: 0,
      min: 0,
    },
  },

  // Tax configuration settings
  taxSettings: {
    enabled: {
      type: Boolean,
      default: false,
    },
    incomeTaxEnabled: {
      type: Boolean,
      default: false,
    },
    socialSecurityEnabled: {
      type: Boolean,
      default: false,
    },
    // Progressive tax brackets for income tax
    incomeTaxBrackets: [{
      minAmount: {
        type: Number,
        default: 0,
      },
      maxAmount: {
        type: Number,
        default: null, // null means no upper limit
      },
      rate: {
        type: Number,
        default: 0,
        min: 0,
        max: 100, // percentage
      },
      description: {
        type: String,
        default: '',
      }
    }],
    // Flat rates for social security contributions
    socialSecurityRate: {
      type: Number,
      default: 0,
      min: 0,
      max: 100, // percentage
    },
    socialSecurityCap: {
      type: Number,
      default: null, // null means no cap
    },
    // Other flat tax rates
    flatTaxRates: [{
      name: {
        type: String,
        required: true,
      },
      rate: {
        type: Number,
        required: true,
        min: 0,
        max: 100, // percentage
      },
      enabled: {
        type: Boolean,
        default: true,
      }
    }],
    // Tax calculation method
    taxCalculationMethod: {
      type: String,
      enum: ['percentage', 'flat', 'progressive'],
      default: 'percentage',
    },
    // Currency settings
    currency: {
      type: String,
      default: 'NPR',
    },
    currencySymbol: {
      type: String,
      default: 'Rs.',
    },
    },

  // Company information settings
  companyInfo: {
    name: {
      type: String,
      default: 'Your Company Name',
    },
    legalName: {
      type: String,
      default: '',
    },
    address: {
      type: String,
      default: '',
    },
    city: {
      type: String,
      default: '',
    },
    state: {
      type: String,
      default: '',
    },
    postalCode: {
      type: String,
      default: '',
    },
    country: {
      type: String,
      default: 'Nepal',
    },
    phone: {
      type: String,
      default: '',
    },
    email: {
      type: String,
      default: '',
    },
    website: {
      type: String,
      default: '',
    },
    taxId: {
      type: String,
      default: '',
    },
    registrationNumber: {
      type: String,
      default: '',
    },
    logoUrl: {
      type: String,
      default: '', // Path to uploaded company logo
    },
    description: {
      type: String,
      default: '',
    },
    industry: {
      type: String,
      default: '',
    },
    establishedYear: {
      type: Number,
      default: null,
    },
    employeeCount: {
      type: String,
      enum: ['1-10', '11-50', '51-200', '201-500', '500+'],
      default: '1-10',
    },
  },

  // Profile completion requirements
  requiredProfileFields: {
    type: [String],
    default: [
      'firstName',
      'lastName', 
      'email',
      'phone',
      'address',
      'emergencyContact',
      'emergencyPhone'
    ],
  },
}, {
  timestamps: true,
});

// Ensure only one settings document exists
adminSettingsSchema.statics.getSettings = async function() {
  let settings = await this.findOne();
  if (!settings) {
    settings = await this.create({});
  }
  return settings;
};

// Update settings
adminSettingsSchema.statics.updateSettings = async function(updates) {
  let settings = await this.findOne();
  if (!settings) {
    settings = await this.create(updates);
  } else {
    Object.assign(settings, updates);
    await settings.save();
  }
  return settings;
};

const AdminSettings = mongoose.model('AdminSettings', adminSettingsSchema);

module.exports = AdminSettings; 