const { Logger } = require('../config/logger');
const fs = require('fs');
const path = require('path');

class ErrorTrackingService {
  constructor() {
    this.errorLogPath = path.join(__dirname, '../logs/errors.json');
    this.performanceLogPath = path.join(__dirname, '../logs/performance.json');
    this.securityLogPath = path.join(__dirname, '../logs/security.json');
    this.ensureLogDirectories();
  }

  ensureLogDirectories() {
    const logDir = path.dirname(this.errorLogPath);
    if (!fs.existsSync(logDir)) {
      fs.mkdirSync(logDir, { recursive: true });
    }
  }

  // Track errors with context
  trackError(error, context = {}) {
    const errorData = {
      timestamp: new Date().toISOString(),
      error: {
        message: error.message,
        stack: error.stack,
        name: error.name
      },
      context: {
        ...context,
        environment: process.env.NODE_ENV,
        version: process.env.npm_package_version || '1.0.0'
      },
      severity: this.calculateSeverity(error),
      fingerprint: this.generateFingerprint(error, context)
    };

    // Log to file
    this.appendToLog(this.errorLogPath, errorData);
    
    // Log to console
    Logger.error('ERROR_TRACKED', errorData);
    
    // Alert for critical errors
    if (errorData.severity === 'critical') {
      this.sendAlert(errorData);
    }

    return errorData;
  }

  // Track performance metrics
  trackPerformance(metrics) {
    const performanceData = {
      timestamp: new Date().toISOString(),
      metrics: {
        ...metrics,
        memory: process.memoryUsage(),
        cpu: process.cpuUsage()
      }
    };

    this.appendToLog(this.performanceLogPath, performanceData);
    Logger.info('PERFORMANCE_TRACKED', performanceData);
  }

  // Track security events
  trackSecurityEvent(event) {
    const securityData = {
      timestamp: new Date().toISOString(),
      event: {
        ...event,
        environment: process.env.NODE_ENV
      },
      severity: event.severity || 'medium'
    };

    this.appendToLog(this.securityLogPath, securityData);
    Logger.warn('SECURITY_EVENT', securityData);
    
    // Alert for high severity security events
    if (securityData.severity === 'high' || securityData.severity === 'critical') {
      this.sendSecurityAlert(securityData);
    }
  }

  // Calculate error severity
  calculateSeverity(error) {
    const criticalPatterns = [
      /database.*connection/i,
      /authentication.*failed/i,
      /unauthorized.*access/i,
      /payment.*failed/i
    ];

    const highPatterns = [
      /validation.*failed/i,
      /rate.*limit/i,
      /timeout/i,
      /memory.*leak/i
    ];

    const message = error.message.toLowerCase();
    
    if (criticalPatterns.some(pattern => pattern.test(message))) {
      return 'critical';
    } else if (highPatterns.some(pattern => pattern.test(message))) {
      return 'high';
    } else if (error.status >= 500) {
      return 'high';
    } else if (error.status >= 400) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  // Generate error fingerprint for grouping
  generateFingerprint(error, context) {
    const key = `${error.name}:${error.message}:${context.url || ''}:${context.method || ''}`;
    return require('crypto').createHash('md5').update(key).digest('hex');
  }

  // Append data to log file
  appendToLog(logPath, data) {
    try {
      let logs = [];
      if (fs.existsSync(logPath)) {
        const content = fs.readFileSync(logPath, 'utf8');
        logs = content ? JSON.parse(content) : [];
      }
      
      logs.push(data);
      
      // Keep only last 1000 entries
      if (logs.length > 1000) {
        logs = logs.slice(-1000);
      }
      
      fs.writeFileSync(logPath, JSON.stringify(logs, null, 2));
    } catch (err) {
      Logger.error('ERROR_WRITING_LOG', { logPath, error: err.message });
    }
  }

  // Send alert for critical errors
  sendAlert(errorData) {
    // In production, this would send to email, Slack, etc.
    Logger.error('CRITICAL_ERROR_ALERT', {
      message: 'Critical error detected',
      error: errorData.error.message,
      context: errorData.context
    });
    
    // TODO: Implement actual alert sending
    // - Email notification
    // - Slack webhook
    // - SMS alert
  }

  // Send security alert
  sendSecurityAlert(securityData) {
    Logger.error('SECURITY_ALERT', {
      message: 'Security threat detected',
      event: securityData.event,
      severity: securityData.severity
    });
    
    // TODO: Implement actual security alert sending
  }

  // Get error statistics
  getErrorStats() {
    try {
      if (!fs.existsSync(this.errorLogPath)) {
        return { total: 0, bySeverity: {}, recent: [] };
      }

      const content = fs.readFileSync(this.errorLogPath, 'utf8');
      const logs = content ? JSON.parse(content) : [];
      
      const stats = {
        total: logs.length,
        bySeverity: {},
        recent: logs.slice(-10) // Last 10 errors
      };

      logs.forEach(log => {
        const severity = log.severity || 'unknown';
        stats.bySeverity[severity] = (stats.bySeverity[severity] || 0) + 1;
      });

      return stats;
    } catch (err) {
      Logger.error('ERROR_GETTING_STATS', { error: err.message });
      return { total: 0, bySeverity: {}, recent: [] };
    }
  }

  // Get performance statistics
  getPerformanceStats() {
    try {
      if (!fs.existsSync(this.performanceLogPath)) {
        return { total: 0, averageResponseTime: 0, recent: [] };
      }

      const content = fs.readFileSync(this.performanceLogPath, 'utf8');
      const logs = content ? JSON.parse(content) : [];
      
      const recentLogs = logs.slice(-100); // Last 100 performance logs
      const responseTimes = recentLogs
        .filter(log => log.metrics.duration)
        .map(log => parseInt(log.metrics.duration.replace('ms', '')));

      return {
        total: logs.length,
        averageResponseTime: responseTimes.length > 0 
          ? Math.round(responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length)
          : 0,
        recent: recentLogs.slice(-10)
      };
    } catch (err) {
      Logger.error('ERROR_GETTING_PERFORMANCE_STATS', { error: err.message });
      return { total: 0, averageResponseTime: 0, recent: [] };
    }
  }

  // Clean old logs
  cleanOldLogs(daysToKeep = 30) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);

    [this.errorLogPath, this.performanceLogPath, this.securityLogPath].forEach(logPath => {
      try {
        if (fs.existsSync(logPath)) {
          const content = fs.readFileSync(logPath, 'utf8');
          const logs = content ? JSON.parse(content) : [];
          
          const filteredLogs = logs.filter(log => {
            const logDate = new Date(log.timestamp);
            return logDate > cutoffDate;
          });
          
          fs.writeFileSync(logPath, JSON.stringify(filteredLogs, null, 2));
          Logger.info('CLEANED_OLD_LOGS', { logPath, removed: logs.length - filteredLogs.length });
        }
      } catch (err) {
        Logger.error('ERROR_CLEANING_LOGS', { logPath, error: err.message });
      }
    });
  }
}

module.exports = new ErrorTrackingService(); 