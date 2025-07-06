const mongoose = require('mongoose');

const fcmTokenSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
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

// Index for efficient queries
fcmTokenSchema.index({ userId: 1 });
fcmTokenSchema.index({ fcmToken: 1 });

module.exports = mongoose.model('FCMToken', fcmTokenSchema); 