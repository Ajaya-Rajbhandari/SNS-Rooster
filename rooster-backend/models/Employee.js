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
  // Add other employee-related fields as needed
});

const Employee = mongoose.model('Employee', employeeSchema);

module.exports = Employee; 