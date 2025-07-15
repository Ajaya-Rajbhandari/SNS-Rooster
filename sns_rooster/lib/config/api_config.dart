import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, kReleaseMode;
import 'package:sns_rooster/utils/logger.dart';
import 'environment_config.dart';

/// API Configuration for SNS Rooster App
///
/// This class manages API endpoints for different environments and platforms.
/// It enforces HTTPS in production and provides secure communication.
/// // Ensure this is the correct location for the ApiConfig class

class ApiConfig {
  // Network Configuration
  static const String localhostIP = '127.0.0.1';
  static const String androidEmulatorIP = '10.0.2.2';
  static const String fallbackIP = '192.168.1.68';
  static const String officeIP = '10.0.0.45';
  static const String devPort = '5000';
  static const String httpsPort = '443';

  // Production URLs (HTTPS only)
  static const String productionApiUrl = 'https://sns-rooster.onrender.com/api';
  static const String stagingApiUrl = 'https://sns-rooster-staging.onrender.com/api';

  static Future<Map<String, dynamic>> getDetailedDebugInfo() async {
    return {
      'ip': '127.0.0.1',
      'port': '8080',
      'status': 'active',
    };
  }

  /// Get the appropriate base URL based on environment and security requirements
  static String get baseUrl {
    // Force HTTPS in production/staging
    if (EnvironmentConfig.isProduction) {
      return productionApiUrl;
    } else if (EnvironmentConfig.isStaging) {
      return stagingApiUrl;
    }

    // Development mode - allow HTTP only in debug mode
    if (EnvironmentConfig.isDevelopment && kDebugMode) {
      return _getDevBaseUrl();
    }

    // If somehow in release mode but not production, force HTTPS
    Logger.warning('Release mode detected but not in production - forcing HTTPS');
    return productionApiUrl;
  }

  /// Get development base URL with HTTP (debug mode only)
  static String _getDevBaseUrl() {
    if (kIsWeb) {
      const url = 'http://localhost:$devPort/api';
      log('DEV_API: Web app using: $url');
      return url;
    } else if (Platform.isAndroid) {
      const url = 'http://$androidEmulatorIP:$devPort/api';
      log('DEV_API: Android using: $url');
      return url;
    } else if (Platform.isIOS) {
      const url = 'http://localhost:$devPort/api';
      log('DEV_API: iOS using: $url');
      return url;
    } else {
      const url = 'http://localhost:$devPort/api';
      log('DEV_API: Desktop using: $url');
      return url;
    }
  }

  /// Get base URL with automatic IP detection (development only)
  static Future<String> getDynamicBaseUrl() async {
    // Only allow dynamic detection in development
    if (!EnvironmentConfig.isDevelopment || kReleaseMode) {
      Logger.warning('Dynamic URL detection only allowed in development');
      return baseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:$devPort/api';
    } else if (Platform.isAndroid || Platform.isIOS) {
      // Check environment variable first
      String ip = const String.fromEnvironment('API_HOST', defaultValue: '');

      if (ip.isEmpty) {
        // Try to detect local IP automatically
        ip = await detectLocalIP();

        // Fallback to hardcoded IP if detection fails
        if (ip.isEmpty) {
          ip = fallbackIP;
        }
      }

      return 'http://$ip:$devPort/api';
    } else {
      return 'http://localhost:$devPort/api';
    }
  }

  /// Detect local IP address automatically (development only)
  static Future<String> detectLocalIP() async {
    if (!EnvironmentConfig.isDevelopment || kReleaseMode) {
      return '';
    }

    try {
      // Get all network interfaces
      final interfaces = await NetworkInterface.list();

      for (final interface in interfaces) {
        // Skip loopback and non-active interfaces
        if (interface.name.toLowerCase().contains('loopback') ||
            interface.name.toLowerCase().contains('virtual') ||
            interface.name.toLowerCase().contains('vpn')) {
          continue;
        }

        for (final addr in interface.addresses) {
          // Look for IPv4 addresses in common local ranges
          if (addr.type == InternetAddressType.IPv4) {
            final ip = addr.address;

            // Common local network ranges
            if (ip.startsWith('192.168.') ||
                ip.startsWith('10.') ||
                ip.startsWith('172.')) {
              return ip;
            }
          }
        }
      }
    } catch (e) {
      log('Error detecting local IP: $e');
    }

    return '';
  }

  /// Validate if URL is secure (HTTPS) for production
  static bool isSecureUrl(String url) {
    return url.startsWith('https://');
  }

  /// Force HTTPS for production environments
  static String enforceHttps(String url) {
    if (EnvironmentConfig.isProduction || EnvironmentConfig.isStaging) {
      if (!isSecureUrl(url)) {
        Logger.error('HTTP URL detected in production: $url');
        throw SecurityException('HTTPS is required in production environments');
      }
    }
    return url;
  }

  /// Get the production-safe base URL
  static String get secureBaseUrl {
    final url = baseUrl;
    return enforceHttps(url);
  }

  /// Check if current environment allows HTTP
  static bool get allowsHttp {
    return EnvironmentConfig.isDevelopment && 
           kDebugMode && 
           !kReleaseMode;
  }

  /// Get environment info for debugging (development only)
  static Map<String, dynamic> getEnvironmentInfo() {
    if (!EnvironmentConfig.isDevelopment) {
      return {'error': 'Environment info only available in development'};
    }

    return {
      'environment': EnvironmentConfig.currentEnvironment,
      'base_url': baseUrl,
      'is_secure': isSecureUrl(baseUrl),
      'allows_http': allowsHttp,
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      'debug_mode': kDebugMode,
      'release_mode': kReleaseMode,
    };
  }

  /// Validate API configuration
  static bool validateConfiguration() {
    try {
      final url = baseUrl;
      
      // Check URL format
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        Logger.error('Invalid URL format: $url');
        return false;
      }

      // Ensure HTTPS in production
      if (EnvironmentConfig.isProduction && !isSecureUrl(url)) {
        Logger.error('HTTPS required in production but HTTP URL found: $url');
        return false;
      }

      // Check environment consistency
      if (!EnvironmentConfig.validateConfig()) {
        Logger.error('Environment configuration validation failed');
        return false;
      }

      return true;
    } catch (e) {
      Logger.error('API configuration validation error: $e');
      return false;
    }
  }

  /// Test connection to the API
  static Future<bool> testConnection() async {
    try {
      final uri = Uri.parse(baseUrl);
      final client = HttpClient();

      // Set a timeout for the connection test
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(uri);
      final response = await request.close();

      client.close();

      // Consider 200-299 and 404 as successful connection
      // (404 is expected if the endpoint doesn't exist but server is reachable)
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (e) {
      log('Connection test failed: $e');
      return false;
    }
  }
}

/// Custom exception for security violations
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}
