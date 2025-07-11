const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  // Company Association
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true,
    index: true
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null, // null means broadcast or role-based
  },
  role: {
    type: String,
    enum: ['admin', 'employee', 'all'],
    default: 'all',
  },
  title: {
    type: String,
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  type: {
    type: String,
    enum: ['info', 'alert', 'action', 'system', 'payroll', 'leave', 'timesheet', 'review'],
    default: 'info',
  },
  link: {
    type: String,
    default: '',
  },
  isRead: {
    type: Boolean,
    default: false,
  },
  expiresAt: {
    type: Date,
    default: null,
  },
}, { timestamps: true });

const Notification = mongoose.model('Notification', notificationSchema);

module.exports = Notification; 