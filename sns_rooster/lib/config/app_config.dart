import 'package:flutter/foundation.dart';

/// Consolidated App Configuration for SNS Rooster
///
/// This single file manages all application configuration including:
/// - Environment settings
/// - API endpoints
/// - Firebase configuration
/// - Google Maps configuration
/// - Security settings
/// - Debug utilities
class AppConfig {
  // =============================================================================
  // ENVIRONMENT CONFIGURATION
  // =============================================================================

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  // =============================================================================
  // API CONFIGURATION
  // =============================================================================

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  // Network Configuration
  static const String devPort = '5000';
  static const String httpsPort = '443';

  // Production URLs (HTTPS only)
  static const String productionApiUrl = 'https://sns-rooster.onrender.com/api';
  static const String stagingApiUrl =
      'https://sns-rooster-staging.onrender.com/api';

  /// Get the appropriate base URL based on environment
  static String get baseUrl {
    if (isProduction) {
      return productionApiUrl;
    } else if (isStaging) {
      return stagingApiUrl;
    } else {
      return apiUrl; // Use environment variable for development
    }
  }

  // =============================================================================
  // FIREBASE CONFIGURATION
  // =============================================================================

  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );

  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );

  // =============================================================================
  // GOOGLE MAPS CONFIGURATION
  // =============================================================================

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  // =============================================================================
  // APP CONFIGURATION
  // =============================================================================

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'SNS HR',
  );

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  // =============================================================================
  // SECURITY CONFIGURATION
  // =============================================================================

  /// Validate if URL is secure (HTTPS) for production
  static bool isSecureUrl(String url) {
    return url.startsWith('https://');
  }

  /// Check if current environment allows HTTP
  static bool get allowsHttp {
    return isDevelopment && kDebugMode && !kReleaseMode;
  }

  /// Force HTTPS for production environments
  static String enforceHttps(String url) {
    if (isProduction || isStaging) {
      if (!isSecureUrl(url)) {
        throw SecurityException('HTTPS is required in production environments');
      }
    }
    return url;
  }

  // =============================================================================
  // VALIDATION METHODS
  // =============================================================================

  /// Validate that all required configuration is present
  static bool validateConfiguration() {
    final errors = <String>[];

    // Check required API configuration
    if (apiUrl.isEmpty) {
      errors.add('API_URL is required');
    }

    // Check Firebase configuration
    if (firebaseApiKey.isEmpty) {
      errors.add('FIREBASE_API_KEY is required');
    }

    if (firebaseProjectId.isEmpty) {
      errors.add('FIREBASE_PROJECT_ID is required');
    }

    // Check Google Maps configuration
    if (googleMapsApiKey.isEmpty) {
      errors.add('GOOGLE_MAPS_API_KEY is required');
    }

    // Production-specific validations
    if (isProduction) {
      if (!apiUrl.startsWith('https://')) {
        errors.add('Production API_URL must use HTTPS');
      }
    }

    if (errors.isNotEmpty) {
      if (kDebugMode) {
        print('Configuration validation errors:');
        for (final error in errors) {
          print('  - $error');
        }
      }
      return false;
    }

    return true;
  }

  // =============================================================================
  // DEBUG UTILITIES
  // =============================================================================

  /// Print current environment configuration
  static void printEnvironmentInfo() {
    if (kDebugMode) {
      print('=== APP CONFIG DEBUG ===');
      print('Environment: $environment');
      print('Is Development: $isDevelopment');
      print('Is Production: $isProduction');
      print('API URL: $apiUrl');
      print('Base URL: $baseUrl');
      print('Firebase Project ID: $firebaseProjectId');
      print('Firebase API Key Set: ${firebaseApiKey.isNotEmpty}');
      print('Google Maps API Key Set: ${googleMapsApiKey.isNotEmpty}');
      print('Debug Mode: $kDebugMode');
      print('Release Mode: $kReleaseMode');
      print('========================');
    }
  }

  /// Get configuration info for debugging (development only)
  static Map<String, dynamic> getConfigurationInfo() {
    if (!isDevelopment) {
      return {'error': 'Configuration info only available in development'};
    }

    return {
      'environment': environment,
      'api_url': apiUrl,
      'base_url': baseUrl,
      'firebase_project_id': firebaseProjectId,
      'firebase_api_key_set': firebaseApiKey.isNotEmpty,
      'google_maps_api_key_set': googleMapsApiKey.isNotEmpty,
      'app_name': appName,
      'app_version': appVersion,
      'is_production': isProduction,
      'is_staging': isStaging,
      'is_development': isDevelopment,
    };
  }

  /// Get Firebase configuration for web
  static Map<String, dynamic> getFirebaseConfig() {
    return {
      'apiKey': firebaseApiKey,
      'authDomain': '$firebaseProjectId.firebaseapp.com',
      'projectId': firebaseProjectId,
      'messagingSenderId': firebaseMessagingSenderId,
      'appId': firebaseAppId,
    };
  }

  // =============================================================================
  // LEAVE CONFIGURATION (Keeping this for now)
  // =============================================================================

  static Map<String, int> totalLeaveDays = {
    'Annual': 30,
    'Sick': 10,
    'Casual': 5,
  };

  static Map<String, int> usedLeaveDays = {'Annual': 6, 'Sick': 5, 'Casual': 1};

  static List<String> get leaveTypes => [
        'Annual Leave',
        'Sick Leave',
        'Casual Leave',
        'Maternity Leave',
        'Paternity Leave'
      ];
}

/// Custom exception for security violations
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
