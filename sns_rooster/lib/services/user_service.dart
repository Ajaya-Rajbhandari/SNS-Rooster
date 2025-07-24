import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sns_rooster/models/user_model.dart';
import '../../config/api_config.dart'; // Import ApiConfig
import 'secure_storage_service.dart';

class UserService {
  // Use ApiConfig.baseUrl
  final String _baseUrl = ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    return await SecureStorageService.getAuthToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    final companyId = await SecureStorageService.getCompanyId();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    // Add company context header if available
    if (companyId != null && companyId.isNotEmpty) {
      headers['x-company-id'] = companyId;
    }

    return headers;
  }

  // Fetches all users, potentially to be filtered for those not yet employees
  Future<List<UserModel>> getUsers() async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$_baseUrl/auth/users'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      // The backend returns a list, not a map
      List<dynamic> usersJson = jsonDecode(response.body);
      List<UserModel> users =
          usersJson.map((dynamic item) => UserModel.fromJson(item)).toList();
      return users;
    } else {
      // Consider more specific error handling based on status code
      throw Exception(
          'Failed to load users: ${response.statusCode} ${response.body}');
    }
  }

  // Fetch users not already assigned as employees
  Future<List<UserModel>> getUnassignedUsers() async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$_baseUrl/employees/unassigned-users'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> usersJson = jsonDecode(response.body);
      List<UserModel> users =
          usersJson.map((dynamic item) => UserModel.fromJson(item)).toList();
      return users;
    } else {
      throw Exception(
          'Failed to load unassigned users: ${response.statusCode} ${response.body}');
    }
  }

  // Add other user-related service methods here if needed, e.g.:
  // Future<UserModel> getUserById(String id) async { ... }
  // Future<void> updateUser(UserModel user) async { ... }
  // Future<void> deleteUser(String id) async { ... }
  // Future<List<UserModel>> getNonEmployeeUsers() async { ... } // More specific fetch
}
