import 'dart:io';
import 'package:flutter/foundation.dart';

/// API Configuration for SNS Rooster App
///
/// This class manages API endpoints for different environments and platforms.
/// It automatically detects the platform and provides the appropriate base URL.
class ApiConfig {
  // Network Configuration - Update these IPs based on your setup
  static const String homeIP =
      '10.0.2.2'; // Android emulator maps to host localhost
  static const String fallbackIP =
      '192.168.1.72'; // Actual machine IP as fallback
  static const String officeIP =
      '10.0.0.45'; // Your office network IP (update this!)
  static const String port = '5000';

  /// Get the appropriate base URL based on platform and environment
  static String get baseUrl {
    if (kIsWeb) {
      // Web platform always uses localhost
      return 'http://localhost:$port/api';
    } else if (Platform.isAndroid || Platform.isIOS) {
      // For emulator, try fallback IP if 10.0.2.2 doesn't work
      // For physical devices, use the host machine's IP address
      String ip = const String.fromEnvironment('API_HOST',
          defaultValue: fallbackIP); // Use fallbackIP for better connectivity
      return 'http://$ip:$port/api'; // Added /api here
    } else {
      // Default for other platforms (desktop, etc.)
      return 'http://localhost:$port/api';
    }
  }

  /// Get base URL for specific environment
  static String getBaseUrlForEnvironment(Environment env) {
    String ip;
    switch (env) {
      case Environment.home:
        ip = homeIP;
        break;
      case Environment.office:
        ip = officeIP;
        break;
      case Environment.localhost:
        return 'http://localhost:$port/api';
    }
    return 'http://$ip:$port/api';
  }

  /// Get the current environment based on IP detection
  static Environment getCurrentEnvironment() {
    final currentUrl = baseUrl;
    if (currentUrl.contains(homeIP)) {
      return Environment.home;
    } else if (currentUrl.contains(officeIP)) {
      return Environment.office;
    } else {
      return Environment.localhost;
    }
  }

  /// Check if the current configuration is for localhost
  static bool get isLocalhost {
    return baseUrl.contains('localhost');
  }

  /// Check if the current configuration is for home network
  static bool get isHomeNetwork {
    return baseUrl.contains(homeIP);
  }

  /// Check if the current configuration is for office network
  static bool get isOfficeNetwork {
    return baseUrl.contains(officeIP);
  }

  /// Get platform-specific information for debugging
  static Map<String, dynamic> get debugInfo {
    return {
      'platform': kIsWeb ? 'Web' : Platform.operatingSystem,
      'isDebugMode': kDebugMode,
      'baseUrl': baseUrl,
      'environment': getCurrentEnvironment().toString(),
      'homeIP': homeIP,
      'officeIP': officeIP,
      'port': port,
    };
  }
}

/// Environment enumeration
enum Environment {
  home,
  office,
  localhost,
}

/// Extension to get string representation of Environment
extension EnvironmentExtension on Environment {
  String get displayName {
    switch (this) {
      case Environment.home:
        return 'Home Network';
      case Environment.office:
        return 'Office Network';
      case Environment.localhost:
        return 'Localhost';
    }
  }

  String get emoji {
    switch (this) {
      case Environment.home:
        return '🏠';
      case Environment.office:
        return '🏢';
      case Environment.localhost:
        return '💻';
    }
  }
}
