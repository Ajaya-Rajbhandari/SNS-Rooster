const mongoose = require('mongoose');

const adminSettingsSchema = new mongoose.Schema({
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