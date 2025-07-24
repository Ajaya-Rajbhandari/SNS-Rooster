import 'package:flutter/foundation.dart';
import 'environment_config.dart';
import 'api_config.dart';

/// Debug Configuration Helper
///
/// This class helps debug environment and API configuration issues
class DebugConfig {
  /// Print current environment configuration
  static void printEnvironmentInfo() {
    if (kDebugMode) {
      print('=== ENVIRONMENT CONFIG DEBUG ===');
      print('Current Environment: ${EnvironmentConfig.currentEnvironment}');
      print('Is Development: ${EnvironmentConfig.isDevelopment}');
      print('Is Production: ${EnvironmentConfig.isProduction}');
      print('Environment API URL: ${EnvironmentConfig.apiUrl}');
      print('ApiConfig Base URL: ${ApiConfig.baseUrl}');
      print('Debug Mode: $kDebugMode');
      print('Release Mode: $kReleaseMode');
      print('================================');
    }
  }

  /// Get detailed environment info as a map
  static Map<String, dynamic> getEnvironmentDebugInfo() {
    return {
      'environment': EnvironmentConfig.currentEnvironment,
      'isDevelopment': EnvironmentConfig.isDevelopment,
      'isProduction': EnvironmentConfig.isProduction,
      'environmentApiUrl': EnvironmentConfig.apiUrl,
      'apiConfigBaseUrl': ApiConfig.baseUrl,
      'debugMode': kDebugMode,
      'releaseMode': kReleaseMode,
    };
  }

  /// Test if the current configuration is correct
  static bool isConfigurationCorrect() {
    final envUrl = EnvironmentConfig.apiUrl;
    final apiUrl = ApiConfig.baseUrl;

    if (kDebugMode) {
      print('Environment URL: $envUrl');
      print('API Config URL: $apiUrl');
      print('URLs match: ${envUrl == apiUrl}');
    }

    return envUrl == apiUrl;
  }
}
