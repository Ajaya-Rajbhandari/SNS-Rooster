const mongoose = require('mongoose');

const LeaveSchema = new mongoose.Schema({
  // Company Association
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true,
    index: true
  },
  // Support both employee and user references
  employee: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee' },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  // Ensure at least one of employee or user is provided
  leaveType: { type: String, required: true },
  startDate: { type: Date, required: true },
  endDate: { type: Date, required: true },
  reason: { type: String },
  status: { type: String, enum: ['Pending', 'Approved', 'Rejected'], default: 'Pending' },
  appliedAt: { type: Date, default: Date.now },
  // Track who approved/rejected the leave
  approvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  approvedAt: { type: Date }
});

// Add validation to ensure either employee or user is provided
LeaveSchema.pre('save', function(next) {
  if (!this.employee && !this.user) {
    return next(new Error('Either employee or user must be provided'));
  }
  if (this.employee && this.user) {
    return next(new Error('Cannot provide both employee and user'));
  }
  next();
});

module.exports = mongoose.model('Leave', LeaveSchema);
