const mongoose = require('mongoose');

const breakTypeSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    unique: true
  },
  displayName: {
    type: String,
    required: true
  },
  description: {
    type: String,
    maxlength: 500
  },
  color: {
    type: String,
    default: '#6B7280' // Default gray color
  },
  icon: {
    type: String,
    default: 'free_breakfast' // Material icon name
  },
  // Duration limits in minutes
  minDuration: {
    type: Number,
    default: 1, // Minimum 1 minute
    min: 1
  },
  maxDuration: {
    type: Number,
    default: 60, // Maximum 60 minutes
    min: 1
  },
  // Daily quotas
  dailyLimit: {
    type: Number,
    default: null, // null means unlimited
    min: 0
  },
  // Weekly quotas
  weeklyLimit: {
    type: Number,
    default: null, // null means unlimited
    min: 0
  },
  // Whether this break type requires approval
  requiresApproval: {
    type: Boolean,
    default: false
  },
  // Whether this break type is paid or unpaid
  isPaid: {
    type: Boolean,
    default: true
  },
  // Whether this break type is active
  isActive: {
    type: Boolean,
    default: true
  },
  // Priority for display order (lower number = higher priority)
  priority: {
    type: Number,
    default: 100
  }
}, { timestamps: true });

const BreakType = mongoose.model('BreakType', breakTypeSchema);

module.exports = BreakType;