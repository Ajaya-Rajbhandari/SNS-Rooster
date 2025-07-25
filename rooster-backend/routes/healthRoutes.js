const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { errorTracker } = require('../middleware/errorTracking');

/**
 * Health Check Routes
 * Provides system status, performance metrics, and monitoring information
 */

// Basic health check
router.get('/', async (req, res) => {
  try {
    // Check database connection
    const dbStatus = mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';
    
    // Get memory usage
    const memoryUsage = process.memoryUsage();
    
    // Get uptime
    const uptime = process.uptime();
    
    const healthStatus = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: Math.round(uptime),
      database: {
        status: dbStatus,
        readyState: mongoose.connection.readyState
      },
      memory: {
        rss: Math.round(memoryUsage.rss / 1024 / 1024), // MB
        heapUsed: Math.round(memoryUsage.heapUsed / 1024 / 1024), // MB
        heapTotal: Math.round(memoryUsage.heapTotal / 1024 / 1024), // MB
        external: Math.round(memoryUsage.external / 1024 / 1024) // MB
      },
      environment: process.env.NODE_ENV || 'development',
      version: process.env.npm_package_version || '1.0.0'
    };

    res.json(healthStatus);
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Detailed health check with error tracking
router.get('/detailed', async (req, res) => {
  try {
    // Get basic health status
    const basicHealth = await new Promise((resolve) => {
      const req = { method: 'GET', url: '/health' };
      const res = {
        json: (data) => resolve(data),
        status: () => ({ json: (data) => resolve(data) })
      };
      
      // Simulate health check
      const dbStatus = mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';
      resolve({
        status: dbStatus === 'connected' ? 'healthy' : 'unhealthy',
        database: { status: dbStatus }
      });
    });

    // Get error tracking status
    const errorStatus = errorTracker.getHealthStatus();
    
    // Get performance metrics
    const performanceMetrics = errorTracker.getPerformanceSummary();
    
    // Get error summary
    const errorSummary = errorTracker.getErrorSummary();

    const detailedHealth = {
      ...basicHealth,
      errorTracking: errorStatus,
      performance: {
        summary: performanceMetrics,
        topSlowEndpoints: Object.entries(performanceMetrics)
          .sort(([,a], [,b]) => b.avgDuration - a.avgDuration)
          .slice(0, 5)
          .map(([endpoint, metrics]) => ({
            endpoint,
            avgDuration: metrics.avgDuration,
            count: metrics.count
          }))
      },
      errors: {
        summary: errorSummary,
        recentErrors: errorSummary.recentErrors.slice(0, 5)
      },
      timestamp: new Date().toISOString()
    };

    res.json(detailedHealth);
  } catch (error) {
    res.status(500).json({
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Performance metrics endpoint
router.get('/performance', (req, res) => {
  try {
    const performanceMetrics = errorTracker.getPerformanceSummary();
    
    res.json({
      performance: performanceMetrics,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Error summary endpoint
router.get('/errors', (req, res) => {
  try {
    const errorSummary = errorTracker.getErrorSummary();
    
    res.json({
      errors: errorSummary,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Database status endpoint
router.get('/database', async (req, res) => {
  try {
    const dbStatus = {
      status: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
      readyState: mongoose.connection.readyState,
      host: mongoose.connection.host,
      port: mongoose.connection.port,
      name: mongoose.connection.name,
      timestamp: new Date().toISOString()
    };

    // Test database connection
    if (mongoose.connection.readyState === 1) {
      try {
        await mongoose.connection.db.admin().ping();
        dbStatus.ping = 'success';
      } catch (pingError) {
        dbStatus.ping = 'failed';
        dbStatus.pingError = pingError.message;
      }
    }

    res.json(dbStatus);
  } catch (error) {
    res.status(500).json({
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Memory usage endpoint
router.get('/memory', (req, res) => {
  try {
    const memoryUsage = process.memoryUsage();
    
    res.json({
      memory: {
        rss: Math.round(memoryUsage.rss / 1024 / 1024), // MB
        heapUsed: Math.round(memoryUsage.heapUsed / 1024 / 1024), // MB
        heapTotal: Math.round(memoryUsage.heapTotal / 1024 / 1024), // MB
        external: Math.round(memoryUsage.external / 1024 / 1024), // MB
        arrayBuffers: Math.round(memoryUsage.arrayBuffers / 1024 / 1024) // MB
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router; 