const mongoose = require('mongoose');

const activitySchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  type: {
    type: String,
    enum: [
      'login', 'logout', 'clock_in', 'clock_out', 'break_start', 'break_end',
      'leave_request', 'leave_approved', 'leave_rejected', 'profile_update',
      'password_change', 'attendance_edit', 'payslip_view', 'event_created',
      'event_updated', 'event_deleted', 'notification_sent', 'file_upload',
      'report_generated', 'settings_changed', 'employee_added', 'employee_updated',
      'employee_deleted', 'system_maintenance', 'backup_created', 'error_logged'
    ],
    required: true
  },
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true,
    trim: true
  },
  details: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  ipAddress: {
    type: String,
    trim: true
  },
  userAgent: {
    type: String,
    trim: true
  },
  location: {
    type: String,
    trim: true
  },
  severity: {
    type: String,
    enum: ['low', 'medium', 'high', 'critical'],
    default: 'low'
  },
  isPublic: {
    type: Boolean,
    default: true
  },
  relatedEntity: {
    type: {
      type: String,
      enum: ['user', 'event', 'attendance', 'leave', 'payslip', 'employee', 'system']
    },
    id: mongoose.Schema.Types.ObjectId
  },
  tags: [String],
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes for efficient queries
activitySchema.index({ user: 1, createdAt: -1 });
activitySchema.index({ type: 1, createdAt: -1 });
activitySchema.index({ 'relatedEntity.type': 1, 'relatedEntity.id': 1 });
activitySchema.index({ severity: 1 });
activitySchema.index({ isPublic: 1, createdAt: -1 });

// Virtual for formatted date
activitySchema.virtual('formattedDate').get(function() {
  return this.createdAt.toLocaleDateString();
});

// Virtual for formatted time
activitySchema.virtual('formattedTime').get(function() {
  return this.createdAt.toLocaleTimeString();
});

// Static method to create activity
activitySchema.statics.createActivity = function(data) {
  return this.create(data);
};

// Static method to get recent activities for a user
activitySchema.statics.getRecentActivities = function(userId, limit = 10) {
  return this.find({ user: userId })
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate('user', 'firstName lastName email')
    .exec();
};

// Static method to get public activities
activitySchema.statics.getPublicActivities = function(limit = 20) {
  return this.find({ isPublic: true })
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate('user', 'firstName lastName email')
    .exec();
};

// Static method to get activities by type
activitySchema.statics.getActivitiesByType = function(type, limit = 10) {
  return this.find({ type: type })
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate('user', 'firstName lastName email')
    .exec();
};

module.exports = mongoose.model('Activity', activitySchema); 