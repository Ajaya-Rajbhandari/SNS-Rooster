import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sns_rooster/models/user_model.dart';
import 'package:sns_rooster/config/api_config.dart'; // Import ApiConfig

class UserService {
  // Use ApiConfig.baseUrl
  final String _baseUrl = ApiConfig.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Use 'token' key from SharedPreferences
  }

  // Fetches all users, potentially to be filtered for those not yet employees
  Future<List<UserModel>> getUsers() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/auth/users'), // Endpoint to get all users, aligned with user_management_screen.dart
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // The backend returns a list, not a map
      List<dynamic> usersJson = jsonDecode(response.body);
      List<UserModel> users = usersJson.map((dynamic item) => UserModel.fromJson(item)).toList();
      return users;
    } else {
      // Consider more specific error handling based on status code
      throw Exception('Failed to load users: \\${response.statusCode} \\${response.body}');
    }
  }

  // Add other user-related service methods here if needed, e.g.:
  // Future<UserModel> getUserById(String id) async { ... }
  // Future<void> updateUser(UserModel user) async { ... }
  // Future<void> deleteUser(String id) async { ... }
  // Future<List<UserModel>> getNonEmployeeUsers() async { ... } // More specific fetch
}