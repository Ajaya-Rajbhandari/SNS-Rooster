const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const { body, validationResult } = require('express-validator');

/**
 * Security Middleware Configuration
 * Implements rate limiting, security headers, and input validation
 */

// ===== RATE LIMITING CONFIGURATION =====

// Rate limiter for authentication endpoints (prevent brute force attacks)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // Increased from 5 to 20 requests per window per IP
  message: {
    error: 'Too many login attempts',
    message: 'Please try again after 15 minutes'
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      error: 'Rate limit exceeded',
      message: 'Too many login attempts, please try again after 15 minutes'
    });
  }
});

// Rate limiter for general API endpoints
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 500, // Increased from 200 to 500 requests per window per IP
  message: {
    error: 'Rate limit exceeded',
    message: 'Too many requests, please try again later'
  },
  standardHeaders: true,
  legacyHeaders: false
});

// Rate limiter for auth validation (more lenient to prevent loops)
const authValidationLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 120, // Increased from 60 to 120 requests per minute per IP
  message: {
    error: 'Rate limit exceeded',
    message: 'Too many validation requests, please try again later'
  },
  standardHeaders: true,
  legacyHeaders: false
});

// Rate limiter for file uploads (prevent abuse)
const uploadLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 20, // Increased from 10 to 20 uploads per hour per IP
  message: {
    error: 'Upload limit exceeded',
    message: 'Too many file uploads, please try again later'
  },
  standardHeaders: true,
  legacyHeaders: false
});

// Rate limiter for super admin endpoints (more lenient for dashboard)
const superAdminLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200, // Increased from 50 to 200 requests per window per IP
  message: {
    error: 'Rate limit exceeded',
    message: 'Too many super admin requests, please try again later'
  },
  standardHeaders: true,
  legacyHeaders: false
});

// Rate limiter for dashboard and analytics endpoints (very lenient)
const dashboardLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // 1000 requests per window per IP for dashboard
  message: {
    error: 'Rate limit exceeded',
    message: 'Too many dashboard requests, please try again later'
  },
  standardHeaders: true,
  legacyHeaders: false
});

// ===== SECURITY HEADERS CONFIGURATION =====

// Helmet configuration for security headers
const helmetConfig = helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      imgSrc: ["'self'", "data:", "https:"],
      scriptSrc: ["'self'"],
      connectSrc: ["'self'", "https://sns-rooster.onrender.com", "https://sns-rooster-8cca5.web.app"],
      frameSrc: ["'none'"],
      objectSrc: ["'none'"],
      upgradeInsecureRequests: []
    }
  },
  crossOriginEmbedderPolicy: false, // Disable for file uploads
  crossOriginResourcePolicy: { policy: "cross-origin" }, // Allow cross-origin for uploads
  crossOriginOpenerPolicy: false // Disable for cross-origin requests
});

// ===== INPUT VALIDATION SCHEMAS =====

// User registration validation
const validateUserRegistration = [
  body('firstName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('First name must be between 2 and 50 characters')
    .matches(/^[a-zA-Z\s]+$/)
    .withMessage('First name can only contain letters and spaces'),
  
  body('lastName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Last name must be between 2 and 50 characters')
    .matches(/^[a-zA-Z\s]+$/)
    .withMessage('Last name can only contain letters and spaces'),
  
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email address'),
  
  body('password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'),
  
  body('role')
    .isIn(['employee', 'admin', 'super_admin'])
    .withMessage('Invalid role specified'),
  
  body('department')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Department name must be less than 100 characters'),
  
  body('position')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Position must be less than 100 characters'),
  
  body('phone')
    .optional()
    .matches(/^[\+]?[1-9][\d]{0,15}$/)
    .withMessage('Please provide a valid phone number')
];

// User login validation
const validateUserLogin = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email address'),
  
  body('password')
    .notEmpty()
    .withMessage('Password is required')
];

// Password change validation
const validatePasswordChange = [
  body('currentPassword')
    .notEmpty()
    .withMessage('Current password is required'),
  
  body('newPassword')
    .isLength({ min: 8 })
    .withMessage('New password must be at least 8 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('New password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'),
  
  body('confirmPassword')
    .custom((value, { req }) => {
      if (value !== req.body.newPassword) {
        throw new Error('Password confirmation does not match password');
      }
      return true;
    })
];

// Company creation validation
const validateCompanyCreation = [
  body('name')
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Company name must be between 2 and 100 characters'),

  body('domain')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Domain must be between 2 and 50 characters')
    .matches(/^[a-zA-Z0-9-]+$/)
    .withMessage('Domain can only contain letters, numbers, and hyphens'),

  body('adminEmail')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid admin email address'),

  body('adminPassword')
    .isLength({ min: 8 })
    .withMessage('Admin password must be at least 8 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Admin password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'),

  body('contactPhone')
    .optional()
    .matches(/^[\+]?[1-9][\d]{0,15}$/)
    .withMessage('Please provide a valid phone number')
];

// Leave request validation
const validateLeaveRequest = [
  body('leaveType')
    .trim()
    .isIn(['Annual Leave', 'Sick Leave', 'Casual Leave', 'Maternity Leave', 'Paternity Leave', 'Unpaid Leave'])
    .withMessage('Invalid leave type specified'),

  body('startDate')
    .isISO8601()
    .withMessage('Start date must be a valid ISO 8601 date')
    .custom((value) => {
      const startDate = new Date(value);
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      
      if (startDate < today) {
        throw new Error('Start date cannot be in the past');
      }
      return true;
    }),

  body('endDate')
    .isISO8601()
    .withMessage('End date must be a valid ISO 8601 date')
    .custom((value, { req }) => {
      const endDate = new Date(value);
      const startDate = new Date(req.body.startDate);
      
      if (endDate < startDate) {
        throw new Error('End date cannot be before start date');
      }
      
      // Check if leave duration is reasonable (max 90 days)
      const daysDiff = Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24));
      if (daysDiff > 90) {
        throw new Error('Leave duration cannot exceed 90 days');
      }
      
      return true;
    }),

  body('reason')
    .optional()
    .trim()
    .isLength({ min: 10, max: 500 })
    .withMessage('Reason must be between 10 and 500 characters')
];

// Attendance validation
const validateAttendance = [
  body('date')
    .optional()
    .isISO8601()
    .withMessage('Date must be a valid ISO 8601 date'),
  
  body('checkInTime')
    .optional()
    .isISO8601()
    .withMessage('Check-in time must be a valid ISO 8601 datetime'),
  
  body('checkOutTime')
    .optional()
    .isISO8601()
    .withMessage('Check-out time must be a valid ISO 8601 datetime')
];

// ===== VALIDATION RESULT HANDLER =====

const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'Validation failed',
      message: 'Please check your input data',
      details: errors.array().map(err => ({
        field: err.path,
        message: err.msg,
        value: err.value
      }))
    });
  }
  next();
};

// ===== FILE UPLOAD VALIDATION =====

const validateFileUpload = (req, res, next) => {
  if (!req.file) {
    return res.status(400).json({
      error: 'No file uploaded',
      message: 'Please select a file to upload'
    });
  }

  // Check file size (5MB limit)
  const maxSize = 5 * 1024 * 1024; // 5MB
  if (req.file.size > maxSize) {
    return res.status(400).json({
      error: 'File too large',
      message: 'File size must be less than 5MB'
    });
  }

  // Check file type
  const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'application/pdf', 'text/plain'];
  if (!allowedTypes.includes(req.file.mimetype)) {
    return res.status(400).json({
      error: 'Invalid file type',
      message: 'Only JPEG, PNG, GIF, PDF, and text files are allowed'
    });
  }

  next();
};

// ===== ENVIRONMENT VARIABLE VALIDATION =====

const validateEnvironmentVariables = () => {
  const requiredVars = [
    'JWT_SECRET',
    'MONGODB_URI',
    'NODE_ENV'
  ];

  const missingVars = requiredVars.filter(varName => !process.env[varName]);
  
  if (missingVars.length > 0) {
    console.error('Missing required environment variables:', missingVars);
    process.exit(1);
  }

  // Validate JWT_SECRET strength
  if (process.env.JWT_SECRET && process.env.JWT_SECRET.length < 32) {
    console.error('JWT_SECRET must be at least 32 characters long');
    process.exit(1);
  }

  console.log('✅ Environment variables validated successfully');
};

// ===== EXPORT ALL SECURITY MIDDLEWARE =====

module.exports = {
  // Rate limiters
  authLimiter,
  apiLimiter,
  authValidationLimiter,
  uploadLimiter,
  superAdminLimiter,
  dashboardLimiter,
  
  // Security headers
  helmetConfig,
  
  // Validation schemas
validateUserRegistration,
validateUserLogin,
validatePasswordChange,
validateCompanyCreation,
validateLeaveRequest,
validateAttendance,
  
  // Validation handlers
  handleValidationErrors,
  validateFileUpload,
  
  // Environment validation
  validateEnvironmentVariables
}; 