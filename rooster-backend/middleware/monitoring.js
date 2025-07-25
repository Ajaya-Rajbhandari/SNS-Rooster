const { Logger } = require('../config/logger');

// Performance monitoring
const performanceMonitor = (req, res, next) => {
  const start = Date.now();
  
  // Add performance headers
  res.set('X-Response-Time', '0ms');
  res.set('X-Content-Length', '0');
  
  // Monitor response
  res.on('finish', () => {
    const duration = Date.now() - start;
    const contentLength = res.get('Content-Length') || 0;
    
    // Log performance metrics
    Logger.info('PERFORMANCE', {
      method: req.method,
      url: req.originalUrl,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      contentLength: `${contentLength} bytes`,
      userAgent: req.get('User-Agent'),
      ip: req.ip
    });
    
    // Alert for slow responses
    if (duration > 5000) {
      Logger.warn('SLOW_RESPONSE', {
        method: req.method,
        url: req.originalUrl,
        duration: `${duration}ms`
      });
    }
  });
  
  next();
};

// Error tracking
const errorTracker = (err, req, res, next) => {
  // Log error details
  Logger.error('API_ERROR', {
    method: req.method,
    url: req.originalUrl,
    error: err.message,
    stack: err.stack,
    userAgent: req.get('User-Agent'),
    ip: req.ip,
    userId: req.user?.id,
    companyId: req.companyId
  });
  
  // Send error response
  res.status(err.status || 500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'production' ? 'Something went wrong' : err.message
  });
};

// Database monitoring
const databaseMonitor = (req, res, next) => {
  const mongoose = require('mongoose');
  
  // Monitor database connection
  const dbState = mongoose.connection.readyState;
  const dbStates = ['disconnected', 'connected', 'connecting', 'disconnecting'];
  
  if (dbState !== 1) { // 1 = connected
    Logger.warn('DATABASE_CONNECTION', {
      state: dbStates[dbState],
      method: req.method,
      url: req.originalUrl
    });
  }
  
  next();
};

// Uptime monitoring
const uptimeMonitor = (req, res, next) => {
  // Add uptime header
  const uptime = process.uptime();
  res.set('X-Uptime', `${Math.floor(uptime)}s`);
  
  // Log uptime periodically
  if (Math.floor(uptime) % 300 === 0) { // Every 5 minutes
    Logger.info('UPTIME', {
      uptime: `${Math.floor(uptime)}s`,
      memory: process.memoryUsage(),
      cpu: process.cpuUsage()
    });
  }
  
  next();
};

// Security monitoring
const securityMonitor = (req, res, next) => {
  // Monitor suspicious activities
  const suspiciousPatterns = [
    /\.\.\//, // Directory traversal
    /<script/i, // XSS attempts
    /union.*select/i, // SQL injection attempts
    /eval\(/i, // Code injection
  ];
  
  const url = req.originalUrl;
  const body = JSON.stringify(req.body);
  
  for (const pattern of suspiciousPatterns) {
    if (pattern.test(url) || pattern.test(body)) {
      Logger.warn('SECURITY_THREAT', {
        pattern: pattern.toString(),
        url: req.originalUrl,
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        body: req.body
      });
    }
  }
  
  next();
};

// Rate limiting monitoring
const rateLimitMonitor = (req, res, next) => {
  // Monitor rate limit headers
  res.on('finish', () => {
    const remaining = res.get('X-RateLimit-Remaining');
    const reset = res.get('X-RateLimit-Reset');
    
    if (remaining && parseInt(remaining) < 10) {
      Logger.warn('RATE_LIMIT_WARNING', {
        remaining,
        reset,
        ip: req.ip,
        url: req.originalUrl
      });
    }
  });
  
  next();
};

// Health check monitoring
const healthCheckMonitor = (req, res, next) => {
  if (req.path === '/health') {
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      database: require('mongoose').connection.readyState === 1 ? 'connected' : 'disconnected'
    };
    
    Logger.info('HEALTH_CHECK', health);
    
    res.json(health);
  } else {
    next();
  }
};

module.exports = {
  performanceMonitor,
  errorTracker,
  databaseMonitor,
  uptimeMonitor,
  securityMonitor,
  rateLimitMonitor,
  healthCheckMonitor
}; 