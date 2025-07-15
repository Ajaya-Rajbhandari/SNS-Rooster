import 'package:flutter/foundation.dart';

/// Environment Configuration for SNS Rooster
///
/// This class manages environment-specific configurations
/// and provides secure access to sensitive data without
/// hardcoding credentials in the source code.
class EnvironmentConfig {
  // Environment types
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  // Current environment - should be set based on build configuration
  static const String currentEnvironment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: production,
  );

  // Debug mode check
  static bool get isDevelopment => currentEnvironment == development;
  static bool get isStaging => currentEnvironment == staging;
  static bool get isProduction => currentEnvironment == production;

  // API Configuration
  static const String _devApiUrl = String.fromEnvironment(
    'DEV_API_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  static const String _stagingApiUrl = String.fromEnvironment(
    'STAGING_API_URL',
    defaultValue: 'https://sns-rooster-staging.onrender.com/api',
  );

  static const String _prodApiUrl = String.fromEnvironment(
    'PROD_API_URL',
    defaultValue: 'https://sns-rooster.onrender.com/api',
  );

  /// Get API URL based on current environment
  static String get apiUrl {
    switch (currentEnvironment) {
      case staging:
        return _stagingApiUrl;
      case production:
        return _prodApiUrl;
      default:
        return _devApiUrl;
    }
  }

  // Test credentials (only available in development)
  static Map<String, String>? get testCredentials {
    if (!isDevelopment || kReleaseMode) {
      return null; // No test credentials in staging/production
    }

    return {
      'employee_email': const String.fromEnvironment(
        'TEST_EMPLOYEE_EMAIL',
        defaultValue: '',
      ),
      'employee_password': const String.fromEnvironment(
        'TEST_EMPLOYEE_PASSWORD',
        defaultValue: '',
      ),
      'admin_email': const String.fromEnvironment(
        'TEST_ADMIN_EMAIL',
        defaultValue: '',
      ),
      'admin_password': const String.fromEnvironment(
        'TEST_ADMIN_PASSWORD',
        defaultValue: '',
      ),
    };
  }

  // Security settings
  static bool get allowHttpInDevelopment => isDevelopment && kDebugMode;
  static bool get enableDebugLogging => isDevelopment && kDebugMode;
  static bool get enableVerboseLogging => isDevelopment && kDebugMode;

  // App configuration
  static String get appName => 'SNS HR';
  static String get appVersion => const String.fromEnvironment(
        'APP_VERSION',
        defaultValue: '1.0.0',
      );

  /// Validate environment configuration
  static bool validateConfig() {
    if (isProduction) {
      // In production, ensure no test credentials are available
      final testCreds = testCredentials;
      if (testCreds != null && testCreds.values.any((v) => v.isNotEmpty)) {
        if (kDebugMode) {
          print('ERROR: Test credentials found in production build!');
        }
        return false;
      }

      // Ensure HTTPS in production
      if (!apiUrl.startsWith('https://')) {
        if (kDebugMode) {
          print('ERROR: Production must use HTTPS!');
        }
        return false;
      }
    }

    return true;
  }

  /// Get environment info for debugging (development only)
  static Map<String, dynamic> getEnvironmentInfo() {
    if (!isDevelopment) {
      return {'error': 'Environment info only available in development'};
    }

    return {
      'environment': currentEnvironment,
      'api_url': apiUrl,
      'app_name': appName,
      'app_version': appVersion,
      'debug_mode': kDebugMode,
      'release_mode': kReleaseMode,
      'test_credentials_available': testCredentials != null,
    };
  }
}
