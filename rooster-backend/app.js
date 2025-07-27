// app.js: Defines and exports the Express app, routes, and middleware.
// Do NOT run this file directly. Use server.js as the entry point for the backend.

const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const path = require('path');

// Security middleware
const {
  helmetConfig,
  apiLimiter,
  authValidationLimiter,
  validateEnvironmentVariables
} = require('./middleware/security');

// Error tracking middleware
const {
  errorTrackingMiddleware,
  performanceTrackingMiddleware
} = require('./middleware/errorTracking');

// Performance optimization middleware
const {
  compressionMiddleware,
  performanceMonitor,
  cacheMiddleware
} = require('./middleware/performance');
const authRoutes = require('./routes/authRoutes');
const attendanceRoutes = require('./routes/attendanceRoutes');
const adminAttendanceRoutes = require('./routes/adminAttendanceRoutes');
const employeeRoutes = require('./routes/employeeRoutes');
const payrollRoutes = require('./routes/payrollRoutes');
const leaveRoutes = require('./routes/leaveRoutes');
const dataExportRoutes = require('./routes/dataExportRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');
const adminSettingsRoutes = require('./routes/adminSettingsRoutes');
const fcmRoutes = require('./routes/fcmRoutes');
const eventRoutes = require('./routes/event-routes');
const companyRoutes = require('./routes/companyRoutes');
const superAdminRoutes = require('./routes/superAdminRoutes');
const trialRoutes = require('./routes/trialRoutes');
const healthRoutes = require('./routes/healthRoutes');

// Enterprise Features Routes
const locationRoutes = require('./routes/locationRoutes');
const expenseRoutes = require('./routes/expenseRoutes');
const performanceRoutes = require('./routes/performanceRoutes');
const trainingRoutes = require('./routes/trainingRoutes');

// Performance monitoring routes
const performanceMonitoringRoutes = require('./routes/performanceRoutes');

// Mobile optimization routes
const mobileOptimizationRoutes = require('./routes/mobileOptimizationRoutes');

// Monitoring routes
const monitoringRoutes = require('./routes/monitoringRoutes');

const app = express();

// Validate environment variables on startup
validateEnvironmentVariables();

// Manual CORS handler for OPTIONS requests
app.options('*', cors());

// Debug middleware to log all requests
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path} - Origin: ${req.headers.origin}`);
  next();
});

// CORS middleware (must be before security middleware for preflight requests)
app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) {
      console.log('CORS: Allowing request with no origin');
      return callback(null, true);
    }
    
    const allowedOrigins = [
      'https://sns-rooster-8cca5.web.app',
      'https://sns-rooster-admin.web.app',  // Admin portal
      'https://sns-rooster.onrender.com',
      'http://localhost:3000',  // Flutter web app
      'http://localhost:3001',  // Admin portal
      'http://192.168.1.119:8080'
    ];
    
    // Allow any localhost port for development (Flutter web uses random ports)
    if (origin.startsWith('http://localhost:') || origin.startsWith('https://localhost:')) {
      console.log('CORS: Allowing localhost origin:', origin);
      return callback(null, true);
    }
    
    // Allow specific origins
    if (allowedOrigins.indexOf(origin) !== -1) {
      console.log('CORS: Allowing origin:', origin);
      return callback(null, true);
    }
    
    // TEMPORARY: Allow all origins for debugging (remove in production)
    console.log('CORS: TEMPORARILY allowing origin:', origin);
    return callback(null, true);
    
    // Log blocked origins for debugging
    // console.log('CORS: Blocked origin:', origin);
    // console.log('CORS: Allowed origins:', allowedOrigins);
    // return callback(new Error('Not allowed by CORS'));
  },
  credentials: true, // Only needed if you use cookies/auth
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'companyId', 'x-company-id'],
  optionsSuccessStatus: 200 // Some legacy browsers (IE11, various SmartTVs) choke on 204
}));

// Security middleware (apply after CORS)
app.use(helmetConfig);

// Specific CORS handler for problematic routes
app.use('/api/auth/me', (req, res, next) => {
  if (req.method === 'OPTIONS') {
    res.header('Access-Control-Allow-Origin', req.headers.origin || '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, companyId, x-company-id');
    res.status(200).end();
    return;
  }
  next();
});

app.use('/api/companies/features', (req, res, next) => {
  if (req.method === 'OPTIONS') {
    res.header('Access-Control-Allow-Origin', req.headers.origin || '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, companyId, x-company-id');
    res.status(200).end();
    return;
  }
  next();
});

app.use('/api/admin/settings', (req, res, next) => {
  if (req.method === 'OPTIONS') {
    res.header('Access-Control-Allow-Origin', req.headers.origin || '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, companyId, x-company-id');
    res.status(200).end();
    return;
  }
  next();
});

// Rate limiting for all API routes (but not for OPTIONS requests)
app.use('/api', (req, res, next) => {
  if (req.method === 'OPTIONS') {
    console.log('Skipping rate limiting for OPTIONS request');
    return next(); // Skip rate limiting for preflight requests
  }
  return apiLimiter(req, res, next);
});

// Performance optimization middleware
app.use(compressionMiddleware);
app.use(performanceMonitor);
app.use(performanceTrackingMiddleware);
app.use(express.json()); // For parsing application/json
app.use(express.urlencoded({ extended: true })); // For parsing application/x-www-form-urlencoded

// Serve static files from uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// MongoDB Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
mongoose.connect(MONGODB_URI)
  .then(() => console.log('Connected to MongoDB'))
  .catch((err) => console.error('MongoDB connection error:', err));

// Health check routes (no rate limiting, with caching)
app.use('/health', cacheMiddleware(60), healthRoutes); // Cache health checks for 1 minute

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/admin', adminAttendanceRoutes);
app.use('/api/employees', employeeRoutes);
app.use('/api/payroll', payrollRoutes);
app.use('/api/leave', leaveRoutes);
app.use('/api/export', dataExportRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/analytics', cacheMiddleware(300), analyticsRoutes); // Cache analytics for 5 minutes
app.use('/api/admin/settings', adminSettingsRoutes);
app.use('/api/companies', companyRoutes);
app.use('/api/super-admin', superAdminRoutes);
app.use('/api/trial', trialRoutes);
app.use('/api', fcmRoutes);
app.use('/api/events', eventRoutes);

// Enterprise Features Routes
app.use('/api/locations', locationRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/performance', performanceRoutes);
app.use('/api/training', trainingRoutes);

// Performance monitoring routes
app.use('/api/performance-monitoring', performanceMonitoringRoutes);

// Mobile optimization routes
app.use('/api/mobile', mobileOptimizationRoutes);

// Monitoring routes
app.use('/api/monitoring', monitoringRoutes);

// Basic route for testing
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to SNS Rooster API' });
});

// Error tracking middleware (must be before error handling)
app.use(errorTrackingMiddleware);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!' });
});

module.exports = app;