import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class PayrollService {
  final AuthProvider authProvider;
  PayrollService(this.authProvider);

  Future<List<Map<String, dynamic>>> getPayrollSlips(String userId) async {
    final token = authProvider.token;
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final url = '${ApiConfig.baseUrl}/payroll/user/$userId';
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
          'Failed to fetch payroll slips: ${response.statusCode} ${response.body}');
    }
  }
}
