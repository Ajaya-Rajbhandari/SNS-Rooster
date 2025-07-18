const mongoose = require('mongoose');

const employeeSchema = new mongoose.Schema({
  firstName: {
    type: String,
    required: true,
    trim: true
  },
  lastName: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true
  },
  employeeId: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  hireDate: {
    type: Date,
    default: Date.now
  },
  position: {
    type: String,
    trim: true
  },
  department: {
    type: String,
    trim: true
  },
  hourlyRate: {
    type: Number,
    default: 0,
    min: 0,
  },
  monthlySalary: {
    type: Number,
    default: 0,
    min: 0,
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
  },
  isActive: {
    type: Boolean,
    default: true
  },
  employeeType: {
    type: String,
    enum: ['Permanent', 'Temporary'],
    default: 'Permanent',
  },
  employeeSubType: {
    type: String,
    enum: ['Full-time', 'Part-time', 'Casual', null],
    default: null,
  },
  // Add other employee-related fields as needed
});

const Employee = mongoose.model('Employee', employeeSchema);

module.exports = Employee; 