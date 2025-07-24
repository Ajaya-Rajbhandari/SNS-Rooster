import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sns_rooster/services/secure_storage_service.dart';
import 'package:sns_rooster/utils/logger.dart';
import 'certificate_pinning_service.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? CertificatePinningService.createSecureClient();

  Future<ApiResponse> get(String endpoint) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e, stack) {
      Logger.error('GET $endpoint failed: $e', stack);
      return ApiResponse(
        success: false,
        message: 'Unable to connect. Please check your network and try again.',
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
    } catch (e, stack) {
      Logger.error('POST $endpoint failed: $e', stack);
      return ApiResponse(
        success: false,
        message: 'Unable to connect. Please try again later.',
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
    } catch (e, stack) {
      Logger.error('PUT $endpoint failed: $e', stack);
      return ApiResponse(
        success: false,
        message: 'Unable to update data. Please try again.',
        data: null,
      );
    }
  }

  Future<ApiResponse> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: json.encode(data),
      );
      return _handleResponse(response);
    } catch (e, stack) {
      Logger.error('PATCH $endpoint failed: $e', stack);
      return ApiResponse(
        success: false,
        message: 'Unable to update data. Please try again.',
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
    } catch (e, stack) {
      Logger.error('DELETE $endpoint failed: $e', stack);
      return ApiResponse(
        success: false,
        message: 'Unable to delete data. Please try again.',
        data: null,
      );
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorageService.getAuthToken();
    final companyId = await SecureStorageService.getCompanyId();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    // Add company context header if available
    if (companyId != null && companyId.isNotEmpty) {
      headers['x-company-id'] = companyId;
      print('🔍 API_DEBUG: Adding company ID header: $companyId');
    } else {
      print('⚠️  API_DEBUG: No company ID found in secure storage');
    }

    print('🔍 API_DEBUG: Headers being sent: ${headers.keys.toList()}');
    return headers;
  }

  Future<String> getAuthorizationHeader() async {
    final token = await SecureStorageService.getAuthToken();
    return token != null ? 'Bearer $token' : 'No Authorization header';
  }

  ApiResponse _handleResponse(http.Response response) {
    try {
      // Check if response is HTML (server error page)
      if (response.headers['content-type']?.contains('text/html') == true ||
          response.body.trim().startsWith('<!DOCTYPE html>') ||
          response.body.trim().startsWith('<html>')) {
        Logger.error(
            'Server returned HTML instead of JSON: ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}');
        return ApiResponse(
          success: false,
          message: 'Server error. Please check if the backend is running.',
          data: null,
        );
      }

      // Check if response body is empty
      if (response.body.trim().isEmpty) {
        return ApiResponse(
          success: response.statusCode >= 200 && response.statusCode < 300,
          message: 'Empty response from server',
          data: null,
        );
      }

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
    } catch (e, stack) {
      Logger.error('Response parsing failed: $e', stack);
      Logger.error(
          'Response body: ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}');
      return ApiResponse(
        success: false,
        message: 'Unexpected server response. Please try again later.',
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
