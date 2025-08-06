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
      // Use streaming approach for large log files
      const logEntry = JSON.stringify(data) + '\n';
      
      // Append to file without loading entire content
      fs.appendFileSync(logPath, logEntry);
      
      // Check file size and rotate if too large (10MB limit)
      const stats = fs.statSync(logPath);
      if (stats.size > 10 * 1024 * 1024) { // 10MB
        this.rotateLogFile(logPath);
      }
    } catch (err) {
      Logger.error('ERROR_WRITING_LOG', { logPath, error: err.message });
    }
  }

  // Rotate log file when it gets too large
  rotateLogFile(logPath) {
    try {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const backupPath = `${logPath}.${timestamp}`;
      
      // Rename current file to backup
      fs.renameSync(logPath, backupPath);
      
      // Create new empty log file
      fs.writeFileSync(logPath, '');
      
      // Keep only last 5 backup files
      this.cleanupOldLogFiles(logPath);
      
      Logger.info('LOG_ROTATED', { originalPath: logPath, backupPath });
    } catch (err) {
      Logger.error('ERROR_ROTATING_LOG', { logPath, error: err.message });
    }
  }

  // Cleanup old log files
  cleanupOldLogFiles(logPath) {
    try {
      const logDir = path.dirname(logPath);
      const baseName = path.basename(logPath);
      const files = fs.readdirSync(logDir)
        .filter(file => file.startsWith(baseName + '.'))
        .sort()
        .reverse();
      
      // Keep only last 5 backup files
      if (files.length > 5) {
        files.slice(5).forEach(file => {
          try {
            fs.unlinkSync(path.join(logDir, file));
          } catch (err) {
            Logger.error('ERROR_DELETING_OLD_LOG', { file, error: err.message });
          }
        });
      }
    } catch (err) {
      Logger.error('ERROR_CLEANUP_LOGS', { error: err.message });
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

      // Use streaming to read log file efficiently
      const stats = {
        total: 0,
        responseTimes: [],
        recent: []
      };

      const fileContent = fs.readFileSync(this.performanceLogPath, 'utf8');
      const lines = fileContent.split('\n').filter(line => line.trim());
      
      // Process only last 1000 lines to prevent memory issues
      const recentLines = lines.slice(-1000);
      
      for (const line of recentLines) {
        try {
          const logEntry = JSON.parse(line);
          stats.total++;
          
          if (logEntry.metrics && logEntry.metrics.duration) {
            const duration = parseInt(logEntry.metrics.duration.replace('ms', ''));
            if (!isNaN(duration)) {
              stats.responseTimes.push(duration);
            }
          }
          
          // Keep only last 10 entries for recent array
          if (stats.recent.length < 10) {
            stats.recent.push(logEntry);
          }
        } catch (parseError) {
          // Skip invalid JSON lines
          continue;
        }
      }

      return {
        total: stats.total,
        averageResponseTime: stats.responseTimes.length > 0 
          ? Math.round(stats.responseTimes.reduce((a, b) => a + b, 0) / stats.responseTimes.length)
          : 0,
        recent: stats.recent
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