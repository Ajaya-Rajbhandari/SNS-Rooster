import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Dynamic API Service that automatically detects and uses the correct IP address
/// for connecting to the backend server without manual configuration.
class DynamicApiService {
  static DynamicApiService? _instance;
  static DynamicApiService get instance => _instance ??= DynamicApiService._();

  DynamicApiService._();

  String? _cachedBaseUrl;
  String? _cachedIP;

  /// Get the base URL with automatic IP detection
  Future<String> get baseUrl async {
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl!;
    }

    _cachedBaseUrl = await ApiConfig.getDynamicBaseUrl();
    return _cachedBaseUrl!;
  }

  /// Get the detected IP address
  Future<String> get detectedIP async {
    if (_cachedIP != null) {
      return _cachedIP!;
    }

    _cachedIP = await ApiConfig.detectLocalIP();
    return _cachedIP ?? ApiConfig.fallbackIP;
  }

  /// Clear cached values (useful when network changes)
  void clearCache() {
    _cachedBaseUrl = null;
    _cachedIP = null;
  }

  /// Make a GET request with automatic base URL
  Future<http.Response> get(String endpoint,
      {Map<String, String>? headers}) async {
    final url = await _buildUrl(endpoint);
    return http.get(Uri.parse(url), headers: headers);
  }

  /// Make a POST request with automatic base URL
  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final url = await _buildUrl(endpoint);
    return http.post(Uri.parse(url), headers: headers, body: body);
  }

  /// Make a PUT request with automatic base URL
  Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final url = await _buildUrl(endpoint);
    return http.put(Uri.parse(url), headers: headers, body: body);
  }

  /// Make a DELETE request with automatic base URL
  Future<http.Response> delete(String endpoint,
      {Map<String, String>? headers}) async {
    final url = await _buildUrl(endpoint);
    return http.delete(Uri.parse(url), headers: headers);
  }

  /// Build full URL with detected base URL
  Future<String> _buildUrl(String endpoint) async {
    final base = await baseUrl;
    return '$base/$endpoint'.replaceAll(RegExp(r'/+'), '/');
  }

  /// Test connectivity to the backend server
  Future<bool> testConnectivity() async {
    try {
      final response = await get('auth/login');
      // Even if we get a 404 (expected for GET on login), it means server is reachable
      return response.statusCode < 500;
    } catch (e) {
      print('Connectivity test failed: $e');
      return false;
    }
  }

  /// Get detailed network information for debugging
  Future<Map<String, dynamic>> getNetworkInfo() async {
    final info = await ApiConfig.getDetailedDebugInfo();
    info['serviceBaseUrl'] = await baseUrl;
    info['detectedIP'] = await detectedIP;
    info['connectivityTest'] = await testConnectivity();
    return info;
  }

  /// Get the base URL for static assets (without /api prefix)
  Future<String> get staticBaseUrl async {
    final base = await baseUrl;
    // Remove /api suffix for static assets
    return base.replaceAll('/api', '');
  }

  /// Build URL for static assets (like images, documents)
  Future<String> buildStaticUrl(String path) async {
    final base = await staticBaseUrl;
    return '$base/$path'.replaceAll(RegExp(r'/+'), '/');
  }
}
