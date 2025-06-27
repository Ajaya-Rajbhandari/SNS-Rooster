import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl;
  final SharedPreferences prefs;
  final http.Client _client;

  ApiService({
    required this.baseUrl,
    required this.prefs,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<ApiResponse> get(String endpoint) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
      );
    }
  }

  Future<ApiResponse> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: json.encode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
      );
    }
  }

  Future<ApiResponse> put(String endpoint, [Map<String, dynamic>? data]) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: data != null ? json.encode(data) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
      );
    }
  }

  Future<ApiResponse> delete(String endpoint) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
      );
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token =
        prefs.getString('token'); // Changed from 'auth_token' to 'token'
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<String> getAuthorizationHeader() async {
    final token = prefs.getString('token');
    return token != null ? 'Bearer $token' : 'No Authorization header';
  }

  ApiResponse _handleResponse(http.Response response) {
    try {
      final data = json.decode(response.body);
      if (data is List) {
        // Raw array response
        return ApiResponse(
          success: response.statusCode >= 200 && response.statusCode < 300,
          message: 'Request completed',
          data: data,
        );
      } else if (data is Map && data.containsKey('data')) {
        // Object with 'data' field
        return ApiResponse(
          success: response.statusCode >= 200 && response.statusCode < 300,
          message: data['message'] ?? 'Request completed',
          data: data['data'],
        );
      } else {
        // Fallback for other object responses
        return ApiResponse(
          success: response.statusCode >= 200 && response.statusCode < 300,
          message: data['message'] ?? 'Request completed',
          data: data,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error parsing response: $e',
        data: null,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });
}
