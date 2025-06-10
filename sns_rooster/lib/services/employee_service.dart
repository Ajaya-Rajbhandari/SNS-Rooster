import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sns_rooster/providers/auth_provider.dart';

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
          Uri.parse('${authProvider.baseUrl}/employees'),
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
        Uri.parse('${authProvider.baseUrl}/employees'),
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
        Uri.parse('${authProvider.baseUrl}/employees/$id'),
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
          Uri.parse('${authProvider.baseUrl}/employees/$id'),
          headers: getHeaders());
      if (response.statusCode != 204) {
        throw Exception(
            'Failed to delete employee: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting employee: $e');
    }
  }
}
