const fs = require('fs');
const path = require('path');

// Ensure logs directory exists
const logsDir = path.join(__dirname, '..', 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

// Define log levels
const LOG_LEVELS = {
  ERROR: 0,
  WARN: 1,
  INFO: 2,
  DEBUG: 3
};

// Get current log level based on environment
const getCurrentLogLevel = () => {
  if (process.env.NODE_ENV === 'production') {
    return LOG_LEVELS.ERROR; // Only errors in production
  } else if (process.env.NODE_ENV === 'staging') {
    return LOG_LEVELS.WARN; // Warnings and errors in staging
  } else {
    return LOG_LEVELS.DEBUG; // All logs in development
  }
};

// Format timestamp
const formatTimestamp = () => {
  return new Date().toISOString();
};

// Format log message
const formatMessage = (level, message, data = null) => {
  const timestamp = formatTimestamp();
  const environment = process.env.NODE_ENV || 'development';
  let formatted = `[${timestamp}] [${environment.toUpperCase()}] [${level}] ${message}`;
  
  if (data) {
    formatted += ` ${JSON.stringify(data)}`;
  }
  
  return formatted;
};

// Write to log file
const writeToFile = (filename, message) => {
  try {
    const logPath = path.join(logsDir, filename);
    fs.appendFileSync(logPath, message + '\n');
  } catch (error) {
    // Fallback to console if file writing fails
    console.error('Failed to write to log file:', error.message);
  }
};

// Sanitize sensitive data
const sanitizeData = (data) => {
  if (process.env.NODE_ENV === 'production') {
    const sensitivePatterns = [
      /token["\s]*[:=]["\s]*[a-zA-Z0-9\-_.]+/gi,
      /password["\s]*[:=]["\s]*[^"\s]+/gi,
      /secret["\s]*[:=]["\s]*[^"\s]+/gi,
      /key["\s]*[:=]["\s]*[^"\s]+/gi,
      /Bearer\s+[a-zA-Z0-9\-_.]+/gi,
      /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g, // Email addresses
    ];
    
    let sanitized = JSON.stringify(data);
    sensitivePatterns.forEach(pattern => {
      sanitized = sanitized.replace(pattern, '"***REDACTED***"');
    });
    
    return JSON.parse(sanitized);
  }
  return data;
};

// Logger class
class Logger {
  static error(message, data = null) {
    const currentLevel = getCurrentLogLevel();
    if (currentLevel >= LOG_LEVELS.ERROR) {
      const sanitizedData = sanitizeData(data);
      const formatted = formatMessage('ERROR', message, sanitizedData);
      
      // Always log errors to console and file
      console.error(formatted);
      writeToFile('error.log', formatted);
      writeToFile('combined.log', formatted);
    }
  }

  static warn(message, data = null) {
    const currentLevel = getCurrentLogLevel();
    if (currentLevel >= LOG_LEVELS.WARN) {
      const sanitizedData = sanitizeData(data);
      const formatted = formatMessage('WARN', message, sanitizedData);
      
      console.warn(formatted);
      writeToFile('combined.log', formatted);
    }
  }

  static info(message, data = null) {
    const currentLevel = getCurrentLogLevel();
    if (currentLevel >= LOG_LEVELS.INFO) {
      const sanitizedData = sanitizeData(data);
      const formatted = formatMessage('INFO', message, sanitizedData);
      
      console.log(formatted);
      writeToFile('combined.log', formatted);
    }
  }

  static debug(message, data = null) {
    const currentLevel = getCurrentLogLevel();
    if (currentLevel >= LOG_LEVELS.DEBUG) {
      const sanitizedData = sanitizeData(data);
      const formatted = formatMessage('DEBUG', message, sanitizedData);
      
      console.log(formatted);
      writeToFile('combined.log', formatted);
    }
  }
}

// Console wrapper for backward compatibility
const consoleWrapper = {
  log: (message, ...args) => {
    if (process.env.NODE_ENV !== 'production') {
      Logger.debug(message, args.length > 0 ? args : null);
    }
  },
  debug: (message, ...args) => {
    if (process.env.NODE_ENV !== 'production') {
      Logger.debug(message, args.length > 0 ? args : null);
    }
  },
  info: (message, ...args) => {
    Logger.info(message, args.length > 0 ? args : null);
  },
  warn: (message, ...args) => {
    Logger.warn(message, args.length > 0 ? args : null);
  },
  error: (message, ...args) => {
    Logger.error(message, args.length > 0 ? args : null);
  }
};

module.exports = { Logger, console: consoleWrapper }; 