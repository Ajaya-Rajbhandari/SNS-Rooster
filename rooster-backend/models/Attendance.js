const mongoose = require('mongoose');

const BreakSchema = new mongoose.Schema({
  type: { type: mongoose.Schema.Types.ObjectId, ref: 'BreakType', required: true },
  start: { type: Date, required: true },
  end:   { type: Date },
  duration: { type: Number }, // ms
});

const AttendanceSchema = new mongoose.Schema({
  // Company Association
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true,
    index: true
  },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  date: { type: Date, required: true },
  checkInTime:  { type: Date, required: true, default: Date.now },
  checkOutTime: { type: Date },
  breaks: [BreakSchema],
  totalBreakDuration: { type: Number, default: 0 },
  status: { 
    type: String, 
    enum: ['pending', 'approved', 'rejected'], 
    default: 'pending' 
  },
  adminComment: { type: String, default: '' },
  approvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  approvedAt: { type: Date },
  
  // Location tracking
  checkInLocation: {
    latitude: { type: Number },
    longitude: { type: Number }
  },
  checkOutLocation: {
    latitude: { type: Number },
    longitude: { type: Number }
  },
  locationValidation: {
    isValid: { type: Boolean },
    distance: { type: Number },
    geofenceRadius: { type: Number },
    locationName: { type: String }
  }
});

// Updated compound index to include company context
AttendanceSchema.index({ companyId: 1, user: 1, date: 1 }, { unique: true });

// Pre-save hook to ensure the date is stored as UTC midnight
AttendanceSchema.pre('save', function(next) {
  if (this.isModified('date')) {
    this.date.setUTCHours(0, 0, 0, 0);
  }
  next();
});

module.exports = mongoose.model('Attendance', AttendanceSchema);