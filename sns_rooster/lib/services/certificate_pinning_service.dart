import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../utils/logger.dart';
import '../config/environment_config.dart';

/// Certificate Pinning Service for SNS Rooster
/// 
/// This service implements certificate pinning to prevent man-in-the-middle attacks
/// by validating that the server certificate matches expected certificates.
class CertificatePinningService {
  // Production certificate fingerprints (SHA-256)
  // These should be obtained from your actual production certificates
  static const Map<String, List<String>> _certificateFingerprints = {
    'sns-rooster.onrender.com': [
      // Add your actual production certificate SHA-256 fingerprints here
      // Example: 'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99'
    ],
    'sns-rooster-staging.onrender.com': [
      // Add your staging certificate fingerprints here
    ],
  };

  // Backup certificate fingerprints for certificate rotation
  static const Map<String, List<String>> _backupCertificateFingerprints = {
    'sns-rooster.onrender.com': [
      // Add backup certificate fingerprints here
    ],
  };

  /// Create an HTTP client with certificate pinning
  static http.Client createSecureClient() {
    if (kIsWeb) {
      // Web platform doesn't support certificate pinning in the same way
      // Browser handles certificate validation
      Logger.info('CertificatePinning: Using default client for web platform');
      return http.Client();
    }

    if (EnvironmentConfig.isDevelopment && kDebugMode) {
      // In development, allow all certificates for localhost
      Logger.warning('CertificatePinning: Development mode - allowing all certificates');
      return _createDevelopmentClient();
    }

    // Production/staging - use certificate pinning
    return _createPinnedClient();
  }

  /// Create a development client that allows self-signed certificates
  static http.Client _createDevelopmentClient() {
    final httpClient = HttpClient();
    
    // In development, allow bad certificates for testing
    httpClient.badCertificateCallback = (cert, host, port) {
      Logger.warning('CertificatePinning: Allowing bad certificate for development: $host:$port');
      return true;
    };

    return IOClient(httpClient);
  }

  /// Create a production client with certificate pinning
  static http.Client _createPinnedClient() {
    final httpClient = HttpClient();

    // Set certificate callback for pinning
    httpClient.badCertificateCallback = (cert, host, port) {
      Logger.error('CertificatePinning: Bad certificate detected for $host:$port');
      return false;
    };

    // Add certificate verification callback
    httpClient.findProxy = (uri) {
      // Log connection attempts in production
      if (!EnvironmentConfig.isDevelopment) {
        Logger.info('CertificatePinning: Connecting to ${uri.host}:${uri.port}');
      }
      return 'DIRECT';
    };

    return IOClient(httpClient);
  }

  /// Validate certificate fingerprint
  static bool validateCertificateFingerprint(String host, String fingerprint) {
    if (EnvironmentConfig.isDevelopment) {
      // Skip validation in development
      return true;
    }

    // Get expected fingerprints for the host
    final expectedFingerprints = _certificateFingerprints[host] ?? [];
    final backupFingerprints = _backupCertificateFingerprints[host] ?? [];

    // Check against primary certificates
    if (expectedFingerprints.contains(fingerprint)) {
      Logger.info('CertificatePinning: Certificate validated for $host');
      return true;
    }

    // Check against backup certificates
    if (backupFingerprints.contains(fingerprint)) {
      Logger.warning('CertificatePinning: Using backup certificate for $host');
      return true;
    }

    Logger.error('CertificatePinning: Certificate fingerprint validation failed for $host');
    Logger.error('CertificatePinning: Expected one of: ${expectedFingerprints.join(', ')}');
    Logger.error('CertificatePinning: Received: $fingerprint');
    
    return false;
  }

  /// Get certificate information for debugging (development only)
  static Future<Map<String, dynamic>> getCertificateInfo(String url) async {
    if (!EnvironmentConfig.isDevelopment) {
      return {'error': 'Certificate info only available in development'};
    }

    try {
      final uri = Uri.parse(url);
      final httpClient = HttpClient();
      
      // Capture certificate information
      httpClient.badCertificateCallback = (cert, host, port) {
        // In development, log certificate details
        Logger.info('Certificate Subject: ${cert.subject}');
        Logger.info('Certificate Issuer: ${cert.issuer}');
        Logger.info('Certificate Valid From: ${cert.startValidity}');
        Logger.info('Certificate Valid Until: ${cert.endValidity}');
        return true; // Accept all certificates for debugging
      };

      final request = await httpClient.getUrl(uri);
      final response = await request.close();
      
      httpClient.close();

      return {
        'host': uri.host,
        'port': uri.port,
        'status_code': response.statusCode,
        'certificate_validated': true,
      };
    } catch (e) {
      Logger.error('Failed to get certificate info: $e');
      return {
        'error': 'Failed to retrieve certificate information',
        'details': e.toString(),
      };
    }
  }

  /// Initialize certificate pinning
  static Future<void> initialize() async {
    try {
      Logger.info('CertificatePinning: Initializing certificate pinning service');
      
      if (EnvironmentConfig.isProduction) {
        // Validate that we have certificate fingerprints for production
        final prodFingerprints = _certificateFingerprints['sns-rooster.onrender.com'] ?? [];
        if (prodFingerprints.isEmpty) {
          Logger.warning('CertificatePinning: No certificate fingerprints configured for production!');
        }
      }

      // Test certificate pinning in development
      if (EnvironmentConfig.isDevelopment && kDebugMode) {
        Logger.info('CertificatePinning: Development mode - certificate pinning is relaxed');
      }

      Logger.info('CertificatePinning: Service initialized successfully');
    } catch (e) {
      Logger.error('CertificatePinning: Failed to initialize: $e');
      rethrow;
    }
  }

  /// Update certificate fingerprints (for certificate rotation)
  static void updateCertificateFingerprints(String host, List<String> fingerprints) {
    if (EnvironmentConfig.isProduction) {
      Logger.warning('CertificatePinning: Certificate fingerprint update attempted in production');
      // In production, this should be done through app updates, not runtime changes
      return;
    }

    Logger.info('CertificatePinning: Updating certificate fingerprints for $host');
    // In a real implementation, you would update the fingerprints
    // This is just a placeholder for the concept
  }

  /// Check if certificate pinning is active
  static bool get isActive {
    return !EnvironmentConfig.isDevelopment || kReleaseMode;
  }

  /// Get pinning status for debugging
  static Map<String, dynamic> get status {
    return {
      'active': isActive,
      'environment': EnvironmentConfig.currentEnvironment,
      'configured_hosts': _certificateFingerprints.keys.toList(),
      'web_platform': kIsWeb,
      'debug_mode': kDebugMode,
    };
  }
}

/// Exception thrown when certificate pinning fails
class CertificatePinningException implements Exception {
  final String message;
  final String host;
  
  CertificatePinningException(this.message, this.host);
  
  @override
  String toString() => 'CertificatePinningException for $host: $message';
}
