import '../../config/api_config.dart';
import '../providers/auth_provider.dart';
import 'api_service.dart';

class PayrollService {
  final AuthProvider authProvider;
  late final ApiService _apiService;

  PayrollService(this.authProvider) {
    _apiService = ApiService(baseUrl: ApiConfig.baseUrl);
  }

  Future<List<Map<String, dynamic>>> getPayrollSlips(String userId) async {
    try {
      final response = await _apiService.get('/payroll/user/$userId');

      if (response.success) {
        if (response.data is List) {
          return (response.data as List).cast<Map<String, dynamic>>();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to fetch payroll slips: ${response.message}');
      }
    } catch (e) {
      throw Exception('Failed to fetch payroll slips: $e');
    }
  }

  Future<void> updatePayslipStatus(String payslipId, String status,
      {String? comment}) async {
    try {
      final body = {
        'status': status,
        if (comment != null) 'employeeComment': comment,
      };

      final response =
          await _apiService.patch('/payroll/$payslipId/status', body);

      if (!response.success) {
        throw Exception('Failed to update payslip status: ${response.message}');
      }
    } catch (e) {
      throw Exception('Failed to update payslip status: $e');
    }
  }
}
