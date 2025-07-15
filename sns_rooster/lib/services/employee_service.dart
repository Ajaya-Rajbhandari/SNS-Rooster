import 'package:sns_rooster/services/api_service.dart';

class EmployeeService {
  final ApiService apiService;

  EmployeeService(this.apiService);

  Future<List<Map<String, dynamic>>> getEmployees({bool showInactive = false}) async {
    final endpoint = showInactive ? '/employees?showInactive=true' : '/employees';
    final response = await apiService.get(endpoint);
    if (response.success && response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    } else {
      throw Exception('Failed to load employees: \\${response.message}');
    }
  }

  Future<Map<String, dynamic>> addEmployee(Map<String, dynamic> employee) async {
    final response = await apiService.post('/employees', employee);
    if (response.success && response.data is Map<String, dynamic>) {
      return response.data;
    } else {
      throw Exception('Failed to add employee: \\${response.message}');
    }
  }

  Future<Map<String, dynamic>> updateEmployee(String id, Map<String, dynamic> updates) async {
    final response = await apiService.put('/employees/$id', updates);
    if (response.success && response.data is Map<String, dynamic>) {
      return response.data;
    } else {
      throw Exception('Failed to update employee: \\${response.message}');
    }
  }

  Future<void> deleteEmployee(String id) async {
    final response = await apiService.delete('/employees/$id');
    if (!response.success && response.message != 'Request completed') {
      throw Exception('Failed to delete employee: \\${response.message}');
    }
  }

  Future<void> deleteEmployeeFromDatabase(String userId) async {
    final response = await apiService.delete('/auth/users/$userId');
    if (!response.success && response.message != 'Request completed') {
      throw Exception('Failed to delete employee from database: \\${response.message}');
    }
  }

  Future<Map<String, dynamic>> getEmployeeById(String id) async {
    final response = await apiService.get('/employees/$id');
    if (response.success && response.data is Map<String, dynamic>) {
      return response.data;
    } else {
      throw Exception('Failed to fetch employee by ID: \\${response.message}');
    }
  }
}
