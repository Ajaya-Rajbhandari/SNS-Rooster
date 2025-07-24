import 'package:flutter/foundation.dart';

/// Secure Configuration for SNS Rooster
///
/// This class manages all sensitive configuration data using environment variables.
/// Never hardcode sensitive data in this file.
class SecureConfig {
  // API Configuration
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  // Firebase Configuration
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

  // Google Maps Configuration
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  // Environment Configuration
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // App Configuration
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'SNS HR',
  );

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  // Security Configuration
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
  static bool get isDevelopment => environment == 'development';

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

  /// Get configuration info for debugging (development only)
  static Map<String, dynamic> getConfigurationInfo() {
    if (!isDevelopment) {
      return {'error': 'Configuration info only available in development'};
    }

    return {
      'environment': environment,
      'api_url': apiUrl,
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
}
