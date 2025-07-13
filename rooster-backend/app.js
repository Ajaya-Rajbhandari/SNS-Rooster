// app.js: Defines and exports the Express app, routes, and middleware.
// Do NOT run this file directly. Use server.js as the entry point for the backend.

const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const path = require('path');
const authRoutes = require('./routes/authRoutes');
const attendanceRoutes = require('./routes/attendanceRoutes');
const adminAttendanceRoutes = require('./routes/adminAttendanceRoutes');
const employeeRoutes = require('./routes/employeeRoutes');
const payrollRoutes = require('./routes/payrollRoutes');
const leaveRoutes = require('./routes/leaveRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');
const adminSettingsRoutes = require('./routes/adminSettingsRoutes');
const fcmRoutes = require('./routes/fcmRoutes');

const app = express();

// Middleware
app.use(cors({
  origin: [
    'https://sns-rooster-8cca5.web.app',
    'https://sns-rooster.onrender.com',
    'http://localhost:3000',
    'http://192.168.1.119:8080' // <-- add this line!
  ],
  credentials: true, // Only needed if you use cookies/auth
}));
app.use(express.json()); // For parsing application/json
app.use(express.urlencoded({ extended: true })); // For parsing application/x-www-form-urlencoded

// Serve static files from uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// MongoDB Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
mongoose.connect(MONGODB_URI)
  .then(() => console.log('Connected to MongoDB'))
  .catch((err) => console.error('MongoDB connection error:', err));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/admin', adminAttendanceRoutes);
app.use('/api/employees', employeeRoutes);
app.use('/api/payroll', payrollRoutes);
app.use('/api/leave', leaveRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/admin/settings', adminSettingsRoutes);
app.use('/api', fcmRoutes);

// Basic route for testing
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to SNS Rooster API' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!' });
});

module.exports = app;