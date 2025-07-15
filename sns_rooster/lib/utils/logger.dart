import 'package:flutter/foundation.dart';
import '../config/environment_config.dart';

/// Enhanced Logger for SNS Rooster
/// 
/// This logger provides secure logging with different levels and
/// prevents sensitive information from being logged in production.
class Logger {
  // Log levels
  static const int _levelDebug = 0;
  static const int _levelInfo = 1;
  static const int _levelWarning = 2;
  static const int _levelError = 3;

  // Current log level based on environment
  static int get _currentLogLevel {
    if (EnvironmentConfig.isProduction) {
      return _levelError; // Only errors in production
    } else if (EnvironmentConfig.isStaging) {
      return _levelWarning; // Warnings and errors in staging
    } else {
      return _levelDebug; // All logs in development
    }
  }

  // Sensitive data patterns to filter out
  static final List<RegExp> _sensitivePatterns = [
    RegExp(r'token["\s]*[:=]["\s]*[a-zA-Z0-9\-_.]+', caseSensitive: false),
    RegExp(r'password["\s]*[:=]["\s]*[^"\s]+', caseSensitive: false),
    RegExp(r'secret["\s]*[:=]["\s]*[^"\s]+', caseSensitive: false),
    RegExp(r'key["\s]*[:=]["\s]*[^"\s]+', caseSensitive: false),
    RegExp(r'Bearer\s+[a-zA-Z0-9\-_.]+', caseSensitive: false),
    RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'), // Email addresses
    RegExp(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'), // Credit card numbers
  ];

  /// Sanitize message by removing sensitive information
  static String _sanitizeMessage(String message) {
    if (EnvironmentConfig.isProduction) {
      String sanitized = message;
      for (final pattern in _sensitivePatterns) {
        sanitized = sanitized.replaceAll(pattern, '[REDACTED]');
      }
      return sanitized;
    }
    return message;
  }

  /// Format log message with timestamp and level
  static String _formatMessage(String level, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final environment = EnvironmentConfig.currentEnvironment.toUpperCase();
    return '[$timestamp] [$environment] [$level] $message';
  }

  /// Log debug messages (development only)
  static void debug(Object? message) {
    if (_currentLogLevel <= _levelDebug && kDebugMode) {
      final sanitized = _sanitizeMessage(message.toString());
      final formatted = _formatMessage('DEBUG', sanitized);
      debugPrint(formatted);
    }
  }

  /// Log info messages
  static void info(Object? message) {
    if (_currentLogLevel <= _levelInfo) {
      final sanitized = _sanitizeMessage(message.toString());
      final formatted = _formatMessage('INFO', sanitized);
      if (kDebugMode) {
        debugPrint(formatted);
      }
    }
  }

  /// Log warning messages
  static void warning(Object? message) {
    if (_currentLogLevel <= _levelWarning) {
      final sanitized = _sanitizeMessage(message.toString());
      final formatted = _formatMessage('WARNING', sanitized);
      if (kDebugMode) {
        debugPrint(formatted);
      }
    }
  }

  /// Log error messages
  static void error(Object? message, [StackTrace? stackTrace]) {
    if (_currentLogLevel <= _levelError) {
      final sanitized = _sanitizeMessage(message.toString());
      final formatted = _formatMessage('ERROR', sanitized);
      if (kDebugMode) {
        debugPrint(formatted);
        if (stackTrace != null) {
          debugPrint('Stack trace: $stackTrace');
        }
      }
    }
  }

  /// Log authentication events (special handling for security)
  static void auth(String event, {String? userId, bool success = true}) {
    final level = success ? 'AUTH_SUCCESS' : 'AUTH_FAILURE';
    final userInfo = userId != null ? ' (User: ${_sanitizeUserId(userId)})' : '';
    final message = '$event$userInfo';
    
    final formatted = _formatMessage(level, message);
    if (kDebugMode || !success) { // Always log auth failures
      debugPrint(formatted);
    }
  }

  /// Sanitize user ID for logging
  static String _sanitizeUserId(String userId) {
    if (EnvironmentConfig.isProduction) {
      // In production, only show first and last 3 characters
      if (userId.length > 6) {
        return '${userId.substring(0, 3)}***${userId.substring(userId.length - 3)}';
      }
      return '***';
    }
    return userId;
  }

  /// Log network requests (with URL sanitization)
  static void network(String method, String url, int? statusCode, {String? error}) {
    if (!EnvironmentConfig.enableDebugLogging) return;

    final sanitizedUrl = _sanitizeUrl(url);
    final status = statusCode != null ? ' ($statusCode)' : '';
    final errorMsg = error != null ? ' - Error: $error' : '';
    
    final message = '$method $sanitizedUrl$status$errorMsg';
    debug(message);
  }

  /// Sanitize URLs for logging
  static String _sanitizeUrl(String url) {
    // Remove query parameters that might contain sensitive data
    final uri = Uri.tryParse(url);
    if (uri != null) {
      return '${uri.scheme}://${uri.host}${uri.path}';
    }
    return url;
  }

  /// Log performance metrics
  static void performance(String operation, Duration duration) {
    if (!EnvironmentConfig.enableDebugLogging) return;
    debug('PERFORMANCE: $operation took ${duration.inMilliseconds}ms');
  }

  /// Get current log level as string
  static String get currentLogLevelString {
    switch (_currentLogLevel) {
      case _levelDebug:
        return 'DEBUG';
      case _levelInfo:
        return 'INFO';
      case _levelWarning:
        return 'WARNING';
      case _levelError:
        return 'ERROR';
      default:
        return 'UNKNOWN';
    }
  }

  /// Check if logging is enabled for a specific level
  static bool isLevelEnabled(String level) {
    switch (level.toLowerCase()) {
      case 'debug':
        return _currentLogLevel <= _levelDebug;
      case 'info':
        return _currentLogLevel <= _levelInfo;
      case 'warning':
        return _currentLogLevel <= _levelWarning;
      case 'error':
        return _currentLogLevel <= _levelError;
      default:
        return false;
    }
  }

  /// Get logger configuration info
  static Map<String, dynamic> get config {
    return {
      'current_level': currentLogLevelString,
      'environment': EnvironmentConfig.currentEnvironment,
      'debug_logging_enabled': EnvironmentConfig.enableDebugLogging,
      'production_mode': EnvironmentConfig.isProduction,
      'sensitive_data_filtering': EnvironmentConfig.isProduction,
    };
  }
}

/// Legacy function for backward compatibility
/// Use Logger.debug() instead for new code
void log(Object? message) {
  Logger.debug(message);
}
