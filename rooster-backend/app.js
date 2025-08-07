// app.js: Defines and exports the Express app, routes, and middleware.
// Do NOT run this file directly. Use server.js as the entry point for the backend.

const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const path = require('path');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const compression = require('compression');

// Import routes
const authRoutes = require('./routes/authRoutes');
const attendanceRoutes = require('./routes/attendanceRoutes');
const adminAttendanceRoutes = require('./routes/adminAttendanceRoutes');
const employeeRoutes = require('./routes/employeeRoutes');
const payrollRoutes = require('./routes/payrollRoutes');
const leaveRoutes = require('./routes/leaveRoutes');
const leavePolicyRoutes = require('./routes/leavePolicyRoutes');
const dataExportRoutes = require('./routes/dataExportRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');
const adminSettingsRoutes = require('./routes/adminSettingsRoutes');
const companyRoutes = require('./routes/companyRoutes');
const superAdminRoutes = require('./routes/superAdminRoutes');
const billingRoutes = require('./routes/billingRoutes');
const trialRoutes = require('./routes/trialRoutes');
const fcmRoutes = require('./routes/fcmRoutes');
const eventRoutes = require('./routes/eventRoutes');
const performanceReviewRoutes = require('./routes/performanceReviewRoutes');
const performanceReviewTemplateRoutes = require('./routes/performanceReviewTemplateRoutes');
const locationRoutes = require('./routes/locationRoutes');
const expenseRoutes = require('./routes/expenseRoutes');
const performanceRoutes = require('./routes/performanceRoutes');
const trainingRoutes = require('./routes/trainingRoutes');
const performanceMonitoringRoutes = require('./routes/performanceRoutes');
const mobileOptimizationRoutes = require('./routes/mobileOptimizationRoutes');
const monitoringRoutes = require('./routes/monitoringRoutes');
const appVersionRoutes = require('./routes/appVersionRoutes');
const appDownloadRoutes = require('./routes/appDownloadRoutes');
const googleMapsRoutes = require('./routes/googleMapsRoutes');
const healthRoutes = require('./routes/healthRoutes');

// Import middleware
const { authenticateToken } = require('./middleware/auth');
const { requireSuperAdmin } = require('./middleware/superAdmin');
const { performanceMonitor, memoryMonitor, responseSizeLimiter, performanceTrackingMiddleware } = require('./middleware/monitoring');
const { errorTrackingMiddleware } = require('./middleware/errorTracking');
const { cacheMiddleware } = require('./middleware/cache');

const app = express();

// Simple, fast health check for Render deployment (no middleware, no dependencies)
app.get('/api/monitoring/health', (req, res) => {
  // Return immediately without any database checks or complex logic
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: process.env.npm_package_version || '1.0.0',
    message: 'Server is running and ready',
    deployment: 'successful'
  });
});

// Additional simple health check at root level for maximum compatibility
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    message: 'Server is running'
  });
});

// Security headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      imgSrc: ["'self'", "data:", "https:"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      connectSrc: ["'self'", "https://sns-rooster.onrender.com", "https://sns-rooster-8ccz5.web.app"]
    }
  }
}));

// CORS configuration
app.use(cors({
  origin: [
    'https://sns-rooster-8ccz5.web.app',
    'https://sns-rooster-admin.web.app',
    'https://sns-rooster.com',
    'http://localhost:3000',
    'http://localhost:3001',
    'http://localhost:8080',
    'http://localhost:8081'
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Rate limiting configuration
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests from this IP, please try again later.',
    retryAfter: Math.ceil(15 * 60 / 60) // minutes
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const dashboardLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200, // more lenient for dashboard
  message: {
    error: 'Too many dashboard requests, please try again later.',
    retryAfter: Math.ceil(15 * 60 / 60)
  }
});

// Compression middleware
const compressionMiddleware = compression({
  level: 6,
  threshold: 1024,
  filter: (req, res) => {
    if (req.headers['x-no-compression']) {
      return false;
    }
    return compression.filter(req, res);
  }
});

// Environment validation middleware
app.use((req, res, next) => {
  const requiredEnvVars = ['MONGODB_URI', 'JWT_SECRET'];
  const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
  
  if (missingVars.length > 0) {
    console.error('Missing required environment variables:', missingVars);
    return res.status(500).json({
      error: 'Server configuration error',
      message: 'Missing required environment variables'
    });
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

// Rate limiting for dashboard and analytics endpoints (more lenient)
app.use('/api/super-admin/dashboard', dashboardLimiter);
app.use('/api/super-admin/analytics', dashboardLimiter);
app.use('/api/analytics', dashboardLimiter);

// Performance optimization middleware
app.use(compressionMiddleware);
app.use(performanceMonitor);
app.use(memoryMonitor);
app.use(responseSizeLimiter(50)); // Limit responses to 50MB
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
app.use('/api/leave-policies', leavePolicyRoutes);
app.use('/api/export', dataExportRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/analytics', cacheMiddleware(300), analyticsRoutes); // Cache analytics for 5 minutes
app.use('/api/admin/settings', adminSettingsRoutes);
app.use('/api/companies', companyRoutes);
app.use('/api/super-admin', superAdminRoutes);
app.use('/api/super-admin/billing', billingRoutes);
app.use('/api/trial', trialRoutes);
app.use('/api', fcmRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/performance-reviews', performanceReviewRoutes);
app.use('/api/performance-review-templates', performanceReviewTemplateRoutes);

// Enterprise Features Routes
app.use('/api/locations', locationRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/performance', performanceRoutes);
app.use('/api/training', trainingRoutes);

// Performance monitoring routes
app.use('/api/performance-monitoring', performanceMonitoringRoutes);

// Mobile optimization routes
app.use('/api/mobile', mobileOptimizationRoutes);

// Monitoring routes (this will override the simple health check above with the full version)
app.use('/api/monitoring', monitoringRoutes);

// App version routes
app.use('/api/app/version', appVersionRoutes);

// App download routes
app.use('/api/app/download', appDownloadRoutes);

// Google Maps API routes (server-side proxy)
app.use('/api', googleMapsRoutes);

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