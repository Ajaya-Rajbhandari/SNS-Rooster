import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class AdminPayrollService {
  final AuthProvider authProvider;
  AdminPayrollService(this.authProvider);

  Future<List<Map<String, dynamic>>> fetchEmployees() async {
    final token = authProvider.token;
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final url = '${ApiConfig.baseUrl}/employees';
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
          'Failed to fetch employees: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPayslips(String employeeId) async {
    final token = authProvider.token;
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final url = '${ApiConfig.baseUrl}/payroll/employee/$employeeId';
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
          'Failed to fetch payslips: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map<String, dynamic>> addPayslip(Map<String, dynamic> payslip) async {
    final token = authProvider.token;
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final url = '${ApiConfig.baseUrl}/payroll';
    final response = await http.post(Uri.parse(url),
        headers: headers, body: json.encode(payslip));
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to add payslip: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map<String, dynamic>> editPayslip(
      String payslipId, Map<String, dynamic> payslip) async {
    print('DEBUG: AdminPayrollService.editPayslip called');
    print('DEBUG: payslipId: $payslipId');
    print('DEBUG: payslip data: $payslip');

    final token = authProvider.token;
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final url = '${ApiConfig.baseUrl}/payroll/$payslipId';
    print('DEBUG: Making PUT request to: $url');
    print('DEBUG: Request headers: $headers');
    print('DEBUG: Request body: ${json.encode(payslip)}');

    final response = await http.put(Uri.parse(url),
        headers: headers, body: json.encode(payslip));

    print('DEBUG: Response status code: ${response.statusCode}');
    print('DEBUG: Response body: ${response.body}');

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      print('DEBUG: Successfully parsed response: $result');
      return result;
    } else {
      print('DEBUG: Request failed with status: ${response.statusCode}');
      throw Exception(
          'Failed to edit payslip: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> deletePayslip(String payslipId) async {
    final token = authProvider.token;
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final url = '${ApiConfig.baseUrl}/payroll/$payslipId';
    final response = await http.delete(Uri.parse(url), headers: headers);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Failed to delete payslip: ${response.statusCode} ${response.body}');
    }
  }
}
