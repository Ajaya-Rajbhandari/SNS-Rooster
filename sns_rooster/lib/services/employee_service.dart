import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sns_rooster/providers/auth_provider.dart';
import '../config/api_config.dart';

class EmployeeService {
  final AuthProvider authProvider;
  String? _adminToken;

  EmployeeService(this.authProvider);

  // Set admin token for operations
  void setAdminToken(String token) {
    _adminToken = token;
  }

  Map<String, String> getHeaders() {
    final token = _adminToken ?? authProvider.token;
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/employees'),
          headers: getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            'Failed to load employees: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching employees: $e');
    }
  }

  Future<Map<String, dynamic>> addEmployee(
      Map<String, dynamic> employee) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/employees'),
        headers: getHeaders(),
        body: json.encode(employee),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to add employee: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding employee: $e');
    }
  }

  Future<Map<String, dynamic>> updateEmployee(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/employees/$id'),
        headers: getHeaders(),
        body: json.encode(updates),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to update employee: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating employee: $e');
    }
  }

  Future<void> deleteEmployee(String id) async {
    try {
      final response = await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/employees/$id'),
          headers: getHeaders());
      if (response.statusCode != 204 &&
          response.statusCode != 200 &&
          response.statusCode != 404) {
        throw Exception(
            'Failed to delete employee: \\${response.statusCode} \\${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting employee: $e');
    }
  }

  // New method to permanently delete an employee (user) from the database
  Future<void> deleteEmployeeFromDatabase(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '${ApiConfig.baseUrl}/auth/users/$userId'), // Correct endpoint for permanent deletion
        headers: getHeaders(),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        // 200 or 204 for successful deletion
        // Successfully deleted
      } else {
        // Attempt to parse error message from response body
        String errorMessage =
            'Failed to delete employee from database: ${response.statusCode}';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody != null && errorBody['message'] != null) {
            errorMessage += ' - ${errorBody['message']}';
          }
        } catch (_) {
          // If parsing fails, use the raw body
          errorMessage += ' - ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error deleting employee from database: $e');
    }
  }

  Future<Map<String, dynamic>> getEmployeeById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/employees/$id'),
        headers: getHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to fetch employee by ID: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching employee by ID: $e');
    }
  }
}
