import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:meta/meta.dart';
import 'package:sns_rooster/utils/logger.dart';
import '../services/secure_storage_service.dart';
import '../../config/api_config.dart';

/// Dynamic API Service that automatically detects and uses the correct IP address
/// for connecting to the backend server without manual configuration.
class DynamicApiService {
  static DynamicApiService? _instance;
  static DynamicApiService get instance => _instance ??= DynamicApiService._();

  DynamicApiService._();

  /// Public constructor for testing (allows subclassing and direct instantiation)
  @visibleForTesting
  DynamicApiService.testable();

  String? _cachedBaseUrl;
  String? _cachedIP;
  http.Client? _client;

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

  /// Check if the stored JWT is expired
  Future<bool> _isTokenExpired() async {
    final token = await SecureStorageService.getAuthToken();
    if (token == null) return true;
    try {
      final decodedToken = JwtDecoder.decode(token);
      final exp = decodedToken['exp'];
      if (exp == null) return true;
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return expirationDate.isBefore(DateTime.now());
    } catch (e) {
      Logger.error('JWT decode error: $e');
      return true;
    }
  }

  /// Attempt to refresh the JWT using the refresh token
  Future<bool> _tryRefreshToken() async {
    final refreshToken = await SecureStorageService.getRefreshToken();
    if (refreshToken == null) {
      Logger.warning('No refresh token available.');
      return false;
    }
    try {
      final url = await _buildUrl('auth/refresh');
      final response = await _effectiveClient.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];
        final newRefreshToken = data['refreshToken'] ?? refreshToken;
        if (newToken != null) {
          await SecureStorageService.storeAuthToken(newToken);
          await SecureStorageService.storeRefreshToken(newRefreshToken);
          Logger.info('Token refreshed successfully.');
          return true;
        }
      } else {
        Logger.warning('Token refresh failed: {response.body}');
      }
    } catch (e) {
      Logger.error('Exception during token refresh: $e');
    }
    return false;
  }

  /// Get the current valid token, try refresh if expired
  Future<String> _getValidToken() async {
    if (await _isTokenExpired()) {
      Logger.warning('Access token expired, attempting refresh...');
      final refreshed = await _tryRefreshToken();
      if (!refreshed) {
        throw Exception('Authentication token expired. Please log in again.');
      }
    }
    final token = await SecureStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found.');
    return token;
  }

  set httpClient(http.Client client) => _client = client;

  http.Client get _effectiveClient => _client ?? http.Client();

  /// Make a GET request with automatic base URL and token expiration check
  Future<http.Response> get(String endpoint,
      {Map<String, String>? headers}) async {
    await _getValidToken();
    final url = await _buildUrl(endpoint);
    return _effectiveClient.get(Uri.parse(url), headers: headers);
  }

  /// Make a POST request with automatic base URL and token expiration check
  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    await _getValidToken();
    final url = await _buildUrl(endpoint);
    return _effectiveClient.post(Uri.parse(url), headers: headers, body: body);
  }

  /// Make a PUT request with automatic base URL and token expiration check
  Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    await _getValidToken();
    final url = await _buildUrl(endpoint);
    return _effectiveClient.put(Uri.parse(url), headers: headers, body: body);
  }

  /// Make a DELETE request with automatic base URL and token expiration check
  Future<http.Response> delete(String endpoint,
      {Map<String, String>? headers}) async {
    await _getValidToken();
    final url = await _buildUrl(endpoint);
    return _effectiveClient.delete(Uri.parse(url), headers: headers);
  }

  /// Build full URL with detected base URL
  Future<String> _buildUrl(String endpoint) async {
    final base = await baseUrl;
    final uri = Uri.parse(base);
    final joined = uri.resolve(endpoint).toString();
    return joined;
  }

  /// Test connectivity to the backend server
  Future<bool> testConnectivity() async {
    try {
      final response = await get('auth/login');
      // Even if we get a 404 (expected for GET on login), it means server is reachable
      return response.statusCode < 500;
    } catch (e) {
      log('Connectivity test failed: $e');
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
