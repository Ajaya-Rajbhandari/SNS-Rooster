const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { validateCompanyContext, validateUserCompanyAccess } = require('../middleware/companyContext');
const { getCacheStats, clearCache } = require('../middleware/performance');

// Get performance statistics (admin only)
router.get('/stats', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res) => {
  try {
    // Only allow admin and super_admin to access performance stats
    if (req.user.role !== 'admin' && req.user.role !== 'super_admin') {
      return res.status(403).json({
        error: 'Access denied',
        message: 'Only administrators can access performance statistics'
      });
    }

    const cacheStats = getCacheStats();
    
    // Get memory usage
    const memoryUsage = process.memoryUsage();
    const uptime = process.uptime();

    const performanceStats = {
      cache: {
        ...cacheStats,
        hitRate: Math.round(cacheStats.hitRate * 100) / 100
      },
      memory: {
        rss: Math.round(memoryUsage.rss / 1024 / 1024), // MB
        heapUsed: Math.round(memoryUsage.heapUsed / 1024 / 1024), // MB
        heapTotal: Math.round(memoryUsage.heapTotal / 1024 / 1024), // MB
        external: Math.round(memoryUsage.external / 1024 / 1024) // MB
      },
      uptime: {
        seconds: Math.round(uptime),
        minutes: Math.round(uptime / 60),
        hours: Math.round(uptime / 3600)
      },
      timestamp: new Date().toISOString()
    };

    res.json({
      success: true,
      data: performanceStats
    });
  } catch (error) {
    console.error('Error getting performance stats:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to retrieve performance statistics'
    });
  }
});

// Clear cache (admin only)
router.delete('/cache', authenticateToken, validateCompanyContext, validateUserCompanyAccess, (req, res) => {
  try {
    // Only allow admin and super_admin to clear cache
    if (req.user.role !== 'admin' && req.user.role !== 'super_admin') {
      return res.status(403).json({
        error: 'Access denied',
        message: 'Only administrators can clear cache'
      });
    }

    const result = clearCache();
    
    res.json({
      success: true,
      message: 'Cache cleared successfully',
      data: result
    });
  } catch (error) {
    console.error('Error clearing cache:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to clear cache'
    });
  }
});

// Get system health with performance metrics
router.get('/health', (req, res) => {
  try {
    const memoryUsage = process.memoryUsage();
    const uptime = process.uptime();
    const cacheStats = getCacheStats();

    const healthData = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: Math.round(uptime),
      memory: {
        rss: Math.round(memoryUsage.rss / 1024 / 1024), // MB
        heapUsed: Math.round(memoryUsage.heapUsed / 1024 / 1024), // MB
        heapTotal: Math.round(memoryUsage.heapTotal / 1024 / 1024), // MB
        external: Math.round(memoryUsage.external / 1024 / 1024) // MB
      },
      cache: {
        keys: cacheStats.keys,
        hitRate: Math.round(cacheStats.hitRate * 100) / 100
      },
      environment: process.env.NODE_ENV || 'development'
    };

    res.json(healthData);
  } catch (error) {
    console.error('Error getting health data:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to retrieve health data'
    });
  }
});

module.exports = router; 