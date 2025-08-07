import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../config/api_config.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../utils/logger.dart';

class CompanySettingsService {
  final AuthProvider _authProvider;

  CompanySettingsService(this._authProvider);

  Future<Map<String, dynamic>?> fetchSettings() async {
    if (!_authProvider.isAuthenticated) return null;
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/settings/company');
    Logger.debug(
        'CompanySettingsService.fetchSettings() - Calling API: ${uri.path}');

    final res = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_authProvider.token}',
    });

    Logger.debug(
        'CompanySettingsService.fetchSettings() - Response status: ${res.statusCode}');

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      Logger.debug(
          'CompanySettingsService.fetchSettings() - Parsed data: success');
      return data;
    }
    throw Exception('Failed to load company settings');
  }

  Future<void> saveSettings(Map<String, dynamic> data) async {
    if (!_authProvider.isAuthenticated) return;
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/settings/company');
    final res = await http.put(uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode(data));
    if (res.statusCode != 200) {
      final error = json.decode(res.body);
      throw Exception(error['message'] ?? 'Failed to save company settings');
    }
  }

  Future<Map<String, dynamic>> uploadLogo(File logoFile) async {
    if (!_authProvider.isAuthenticated) {
      throw Exception('Not authenticated');
    }
    if (kIsWeb) {
      throw UnsupportedError('Use uploadLogoWeb for web uploads');
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/settings/company/logo');
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${_authProvider.token}';
    // Add the file to the request
    var multipartFile = await http.MultipartFile.fromPath(
      'logo',
      logoFile.path,
      contentType:
          MediaType('image', 'jpeg'), // Default to jpeg, backend will validate
    );
    request.files.add(multipartFile);
    // Send the request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to upload logo');
    }
  }

  Future<Map<String, dynamic>> uploadLogoWeb(
      Uint8List fileBytes, String fileName) async {
    if (!_authProvider.isAuthenticated) {
      throw Exception('Not authenticated');
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/settings/company/logo');
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${_authProvider.token}';
    request.files.add(
        http.MultipartFile.fromBytes('logo', fileBytes, filename: fileName));
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to upload logo');
    }
  }

  /// Get the full URL for a company logo
  static String getLogoUrl(String? logoPath) {
    if (logoPath == null || logoPath.isEmpty) {
      return '';
    }

    // If it's already a full URL (GCS or other remote storage), return as is
    if (logoPath.startsWith('http://') ||
        logoPath.startsWith('https://') ||
        logoPath.contains('://')) {
      return logoPath;
    }

    // For local files (uploads), construct the full URL
    // If it starts with /uploads, it's a local file
    if (logoPath.startsWith('/uploads/')) {
      // ApiConfig.baseUrl is like 'http://192.168.1.68:5000/api'
      // We need 'http://192.168.1.68:5000/uploads/filename.ext'
      final baseWithoutApi = ApiConfig.baseUrl.replaceAll('/api', '');
      return '$baseWithoutApi$logoPath';
    }

    // For other local files, construct the full URL
    // ApiConfig.baseUrl is like 'http://192.168.1.68:5000/api'
    // We need 'http://192.168.1.68:5000/uploads/company/filename.ext'
    final baseWithoutApi = ApiConfig.baseUrl.replaceAll('/api', '');
    return '$baseWithoutApi/uploads/company/$logoPath';
  }
}
