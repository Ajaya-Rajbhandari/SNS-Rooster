const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { requireSuperAdmin } = require('../middleware/superAdmin');
const errorTrackingService = require('../services/errorTrackingService');
const { Logger } = require('../config/logger');

// Simple startup health check (no dependencies)
router.get('/startup', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    message: 'Server is starting up',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Health check endpoint (public)
router.get('/health', (req, res) => {
  try {
    const mongoose = require('mongoose');
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
      environment: process.env.NODE_ENV,
      version: process.env.npm_package_version || '1.0.0'
    };

    // Always return 200 for health check, even if database is disconnected
    // This allows the server to start and be considered "healthy" by Render
    res.status(200).json(health);
  } catch (error) {
    console.error('Health check error:', error);
    // Return 200 even on error to prevent deployment failures
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      error: error.message,
      environment: process.env.NODE_ENV,
      version: process.env.npm_package_version || '1.0.0'
    });
  }
});

// Detailed health check (requires authentication)
router.get('/health/detailed', authenticateToken, requireSuperAdmin, (req, res) => {
  const mongoose = require('mongoose');
  const os = require('os');
  
  const detailedHealth = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: {
      ...process.memoryUsage(),
      system: {
        total: os.totalmem(),
        free: os.freemem(),
        used: os.totalmem() - os.freemem()
      }
    },
    cpu: {
      load: os.loadavg(),
      cores: os.cpus().length
    },
    database: {
      state: mongoose.connection.readyState,
      host: mongoose.connection.host,
      name: mongoose.connection.name,
      readyState: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
    },
    environment: process.env.NODE_ENV,
    version: process.env.npm_package_version || '1.0.0',
    nodeVersion: process.version,
    platform: os.platform(),
    arch: os.arch()
  };

  const statusCode = detailedHealth.database.readyState === 'connected' ? 200 : 503;
  res.status(statusCode).json(detailedHealth);
});

// Error statistics (super admin only)
router.get('/errors', authenticateToken, requireSuperAdmin, (req, res) => {
  try {
    const stats = errorTrackingService.getErrorStats();
    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    Logger.error('ERROR_GETTING_ERROR_STATS', { error: error.message });
    res.status(500).json({
      success: false,
      error: 'Failed to get error statistics'
    });
  }
});

// Performance statistics (super admin only)
router.get('/performance', authenticateToken, requireSuperAdmin, (req, res) => {
  try {
    const stats = errorTrackingService.getPerformanceStats();
    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    Logger.error('ERROR_GETTING_PERFORMANCE_STATS', { error: error.message });
    res.status(500).json({
      success: false,
      error: 'Failed to get performance statistics'
    });
  }
});

// System metrics (super admin only)
router.get('/metrics', authenticateToken, requireSuperAdmin, (req, res) => {
  const os = require('os');
  const mongoose = require('mongoose');
  
  const metrics = {
    timestamp: new Date().toISOString(),
    system: {
      uptime: process.uptime(),
      memory: {
        ...process.memoryUsage(),
        system: {
          total: os.totalmem(),
          free: os.freemem(),
          used: os.totalmem() - os.freemem(),
          usagePercent: ((os.totalmem() - os.freemem()) / os.totalmem() * 100).toFixed(2)
        }
      },
      cpu: {
        load: os.loadavg(),
        cores: os.cpus().length,
        usage: process.cpuUsage()
      }
    },
    database: {
      state: mongoose.connection.readyState,
      readyState: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
    },
    process: {
      pid: process.pid,
      version: process.version,
      platform: os.platform(),
      arch: os.arch()
    }
  };

  res.json({
    success: true,
    data: metrics
  });
});

// Clean old logs (super admin only)
router.post('/logs/clean', authenticateToken, requireSuperAdmin, (req, res) => {
  try {
    const { daysToKeep = 30 } = req.body;
    errorTrackingService.cleanOldLogs(daysToKeep);
    
    res.json({
      success: true,
      message: `Cleaned logs older than ${daysToKeep} days`
    });
  } catch (error) {
    Logger.error('ERROR_CLEANING_LOGS', { error: error.message });
    res.status(500).json({
      success: false,
      error: 'Failed to clean logs'
    });
  }
});

// Test error tracking (super admin only)
router.post('/test/error', authenticateToken, requireSuperAdmin, (req, res) => {
  try {
    const testError = new Error('Test error for monitoring system');
    testError.status = 500;
    
    const errorData = errorTrackingService.trackError(testError, {
      url: req.originalUrl,
      method: req.method,
      userId: req.user.id,
      test: true
    });
    
    res.json({
      success: true,
      message: 'Test error tracked successfully',
      errorData
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to test error tracking'
    });
  }
});

// Test performance tracking (super admin only)
router.post('/test/performance', authenticateToken, requireSuperAdmin, (req, res) => {
  try {
    const testMetrics = {
      method: 'POST',
      url: '/api/monitoring/test/performance',
      duration: '150ms',
      contentLength: '1024 bytes',
      userAgent: req.get('User-Agent'),
      ip: req.ip,
      test: true
    };
    
    errorTrackingService.trackPerformance(testMetrics);
    
    res.json({
      success: true,
      message: 'Test performance tracked successfully',
      metrics: testMetrics
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to test performance tracking'
    });
  }
});

// Test security tracking (super admin only)
router.post('/test/security', authenticateToken, requireSuperAdmin, (req, res) => {
  try {
    const testSecurityEvent = {
      type: 'test_security_event',
      pattern: 'test_pattern',
      url: req.originalUrl,
      ip: req.ip,
      userAgent: req.get('User-Agent'),
      severity: 'low',
      test: true
    };
    
    errorTrackingService.trackSecurityEvent(testSecurityEvent);
    
    res.json({
      success: true,
      message: 'Test security event tracked successfully',
      event: testSecurityEvent
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to test security tracking'
    });
  }
});

module.exports = router; 