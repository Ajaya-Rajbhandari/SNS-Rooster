const mongoose = require('mongoose');

const fcmTokenSchema = new mongoose.Schema({
  // Company Association
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true,
    index: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  fcmToken: {
    type: String,
    required: true
  },
  deviceInfo: {
    platform: String,
    appVersion: String,
    deviceModel: String
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastUsed: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes for efficient queries
fcmTokenSchema.index({ fcmToken: 1 });
fcmTokenSchema.index({ companyId: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model('FCMToken', fcmTokenSchema); 