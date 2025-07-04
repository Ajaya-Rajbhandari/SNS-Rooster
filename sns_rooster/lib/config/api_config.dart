import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sns_rooster/utils/logger.dart';

/// API Configuration for SNS Rooster App
///
/// This class manages API endpoints for different environments and platforms.
/// It automatically detects the platform and provides the appropriate base URL.
class ApiConfig {
  // Network Configuration - Update these IPs based on your setup
  static const String homeIP =
      '10.0.2.2'; // Android emulator maps to host localhost
  static const String fallbackIP = '192.168.1.80';
  // '192.168.1.68'; // Actual machine IP as fallback (updated to current IP)
  static const String officeIP =
      '10.0.0.45'; // Your office network IP (update this!)
  static const String port = '5000';

  /// Get the appropriate base URL based on platform and environment
  static String get baseUrl {
    if (kIsWeb) {
      // For web, use relative path (assumes backend is served from same domain)
      return '';
    } else if (Platform.isAndroid) {
      // Android emulator
      return 'http://10.0.2.2:5000';
    } else {
      // iOS simulator, desktop, etc.
      return 'http://localhost:5000';
    }
  }

  /// Get base URL with automatic IP detection
  static Future<String> getDynamicBaseUrl() async {
    if (kIsWeb) {
      return 'http://localhost:$port/api';
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

      return 'http://$ip:$port/api';
    } else {
      return 'http://localhost:$port/api';
    }
  }

  /// Detect local IP address automatically
  static Future<String> detectLocalIP() async {
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

  /// Get detailed network information for debugging
  static Future<Map<String, dynamic>> getDetailedDebugInfo() async {
    final info = Map<String, dynamic>.from(debugInfo);

    try {
      final detectedIP = await detectLocalIP();
      info['detectedLocalIP'] = detectedIP;
      info['dynamicBaseUrl'] = await getDynamicBaseUrl();

      // Get all network interfaces
      final interfaces = await NetworkInterface.list();
      info['networkInterfaces'] = interfaces
          .map((interface) => {
                'name': interface.name,
                'addresses':
                    interface.addresses.map((addr) => addr.address).toList(),
              })
          .toList();
    } catch (e) {
      info['detectionError'] = e.toString();
    }

    return info;
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
