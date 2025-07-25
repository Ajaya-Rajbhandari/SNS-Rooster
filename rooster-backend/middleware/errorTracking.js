const fs = require('fs');
const path = require('path');

/**
 * Error Tracking Middleware
 * Provides basic error monitoring and alerting for production use
 * 
 * Features:
 * - Error logging to files
 * - Error categorization
 * - Performance monitoring
 * - Alert thresholds
 * - Error reporting
 */

class ErrorTracker {
  constructor() {
    this.logPath = path.join(__dirname, '../logs/errors');
    this.performancePath = path.join(__dirname, '../logs/performance');
    this.errorCounts = new Map();
    this.performanceMetrics = new Map();
    this.alertThreshold = 10; // Alert after 10 errors in 5 minutes
    this.alertWindow = 5 * 60 * 1000; // 5 minutes
    
    this.initializeLogDirectories();
  }

  /**
   * Initialize log directories
   */
  initializeLogDirectories() {
    [this.logPath, this.performancePath].forEach(dir => {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
    });
  }

  /**
   * Log error with categorization
   */
  logError(error, req = null, additionalInfo = {}) {
    const errorInfo = {
      timestamp: new Date().toISOString(),
      error: {
        message: error.message,
        stack: error.stack,
        name: error.name
      },
      request: req ? {
        method: req.method,
        url: req.url,
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        userId: req.user?.userId,
        companyId: req.user?.companyId
      } : null,
      additionalInfo,
      severity: this.categorizeError(error)
    };

    // Write to daily log file
    const today = new Date().toISOString().split('T')[0];
    const logFile = path.join(this.logPath, `errors-${today}.json`);
    
    let logs = [];
    try {
      if (fs.existsSync(logFile)) {
        logs = JSON.parse(fs.readFileSync(logFile, 'utf8'));
      }
    } catch (e) {
      console.warn('Could not read existing error log file');
    }

    logs.push(errorInfo);
    
    // Keep only last 1000 errors per day
    if (logs.length > 1000) {
      logs = logs.slice(-1000);
    }

    fs.writeFileSync(logFile, JSON.stringify(logs, null, 2));

    // Update error counts for alerting
    this.updateErrorCount(errorInfo.severity);

    // Check for alerts
    this.checkAlerts();

    // Console output for development
    if (process.env.NODE_ENV === 'development') {
      console.error('🚨 Error logged:', errorInfo);
    }
  }

  /**
   * Categorize error by severity
   */
  categorizeError(error) {
    const errorMessage = error.message.toLowerCase();
    const errorName = error.name.toLowerCase();

    // Critical errors
    if (errorName.includes('validation') || errorName.includes('authentication')) {
      return 'critical';
    }

    // High severity errors
    if (errorMessage.includes('database') || errorMessage.includes('connection')) {
      return 'high';
    }

    // Medium severity errors
    if (errorMessage.includes('timeout') || errorMessage.includes('rate limit')) {
      return 'medium';
    }

    // Default to low severity
    return 'low';
  }

  /**
   * Update error count for alerting
   */
  updateErrorCount(severity) {
    const now = Date.now();
    const key = `${severity}-${Math.floor(now / this.alertWindow)}`;
    
    this.errorCounts.set(key, (this.errorCounts.get(key) || 0) + 1);
    
    // Clean up old entries
    const cutoff = now - (this.alertWindow * 2);
    for (const [k] of this.errorCounts) {
      const timestamp = parseInt(k.split('-')[1]) * this.alertWindow;
      if (timestamp < cutoff) {
        this.errorCounts.delete(k);
      }
    }
  }

  /**
   * Check for alerts
   */
  checkAlerts() {
    const now = Date.now();
    const currentWindow = Math.floor(now / this.alertWindow);
    
    for (const [key, count] of this.errorCounts) {
      const [severity, window] = key.split('-');
      
      if (parseInt(window) === currentWindow && count >= this.alertThreshold) {
        this.sendAlert(severity, count);
      }
    }
  }

  /**
   * Send alert (placeholder for production alerting)
   */
  sendAlert(severity, count) {
    const alert = {
      timestamp: new Date().toISOString(),
      severity,
      count,
      message: `High error rate detected: ${count} ${severity} errors in the last 5 minutes`
    };

    // Log alert
    const alertFile = path.join(this.logPath, 'alerts.json');
    let alerts = [];
    
    try {
      if (fs.existsSync(alertFile)) {
        alerts = JSON.parse(fs.readFileSync(alertFile, 'utf8'));
      }
    } catch (e) {
      console.warn('Could not read existing alerts file');
    }

    alerts.push(alert);
    
    // Keep only last 100 alerts
    if (alerts.length > 100) {
      alerts = alerts.slice(-100);
    }

    fs.writeFileSync(alertFile, JSON.stringify(alerts, null, 2));

    // Console output for development
    if (process.env.NODE_ENV === 'development') {
      console.error('🚨 ALERT:', alert.message);
    }

    // TODO: Integrate with external alerting services (Sentry, DataDog, etc.)
    // this.sendExternalAlert(alert);
  }

  /**
   * Track performance metrics
   */
  trackPerformance(operation, duration, req = null) {
    const metric = {
      timestamp: new Date().toISOString(),
      operation,
      duration,
      request: req ? {
        method: req.method,
        url: req.url,
        userId: req.user?.userId
      } : null
    };

    // Write to daily performance log
    const today = new Date().toISOString().split('T')[0];
    const perfFile = path.join(this.performancePath, `performance-${today}.json`);
    
    let metrics = [];
    try {
      if (fs.existsSync(perfFile)) {
        metrics = JSON.parse(fs.readFileSync(perfFile, 'utf8'));
      }
    } catch (e) {
      console.warn('Could not read existing performance log file');
    }

    metrics.push(metric);
    
    // Keep only last 1000 metrics per day
    if (metrics.length > 1000) {
      metrics = metrics.slice(-1000);
    }

    fs.writeFileSync(perfFile, JSON.stringify(metrics, null, 2));

    // Update performance tracking
    this.updatePerformanceMetrics(operation, duration);
  }

  /**
   * Update performance metrics
   */
  updatePerformanceMetrics(operation, duration) {
    if (!this.performanceMetrics.has(operation)) {
      this.performanceMetrics.set(operation, {
        count: 0,
        totalDuration: 0,
        minDuration: Infinity,
        maxDuration: 0,
        avgDuration: 0
      });
    }

    const metrics = this.performanceMetrics.get(operation);
    metrics.count++;
    metrics.totalDuration += duration;
    metrics.minDuration = Math.min(metrics.minDuration, duration);
    metrics.maxDuration = Math.max(metrics.maxDuration, duration);
    metrics.avgDuration = metrics.totalDuration / metrics.count;
  }

  /**
   * Get performance summary
   */
  getPerformanceSummary() {
    const summary = {};
    
    for (const [operation, metrics] of this.performanceMetrics) {
      summary[operation] = {
        count: metrics.count,
        avgDuration: Math.round(metrics.avgDuration),
        minDuration: metrics.minDuration === Infinity ? 0 : metrics.minDuration,
        maxDuration: metrics.maxDuration
      };
    }

    return summary;
  }

  /**
   * Get error summary
   */
  getErrorSummary() {
    const summary = {
      total: 0,
      bySeverity: { critical: 0, high: 0, medium: 0, low: 0 },
      recentErrors: []
    };

    // Count errors by severity
    for (const [key, count] of this.errorCounts) {
      const severity = key.split('-')[0];
      summary.bySeverity[severity] += count;
      summary.total += count;
    }

    // Get recent errors
    const today = new Date().toISOString().split('T')[0];
    const logFile = path.join(this.logPath, `errors-${today}.json`);
    
    try {
      if (fs.existsSync(logFile)) {
        const logs = JSON.parse(fs.readFileSync(logFile, 'utf8'));
        summary.recentErrors = logs.slice(-10); // Last 10 errors
      }
    } catch (e) {
      console.warn('Could not read error log file');
    }

    return summary;
  }

  /**
   * Health check
   */
  getHealthStatus() {
    const errorSummary = this.getErrorSummary();
    const performanceSummary = this.getPerformanceSummary();
    
    const criticalErrorRate = errorSummary.bySeverity.critical;
    const avgResponseTime = Object.values(performanceSummary).reduce((sum, op) => sum + op.avgDuration, 0) / Object.keys(performanceSummary).length || 0;

    return {
      status: criticalErrorRate > 5 ? 'unhealthy' : avgResponseTime > 1000 ? 'degraded' : 'healthy',
      errorRate: errorSummary.total,
      criticalErrors: criticalErrorRate,
      avgResponseTime: Math.round(avgResponseTime),
      timestamp: new Date().toISOString()
    };
  }
}

// Create singleton instance
const errorTracker = new ErrorTracker();

// Express middleware for error tracking
const errorTrackingMiddleware = (err, req, res, next) => {
  // Track the error
  errorTracker.logError(err, req, {
    responseStatus: res.statusCode,
    responseTime: Date.now() - req.startTime
  });

  // Pass to next error handler
  next(err);
};

// Performance tracking middleware
const performanceTrackingMiddleware = (req, res, next) => {
  req.startTime = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - req.startTime;
    errorTracker.trackPerformance(`${req.method} ${req.url}`, duration, req);
  });

  next();
};

module.exports = {
  errorTracker,
  errorTrackingMiddleware,
  performanceTrackingMiddleware
}; 