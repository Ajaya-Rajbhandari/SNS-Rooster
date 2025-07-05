import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../providers/auth_provider.dart';

class PayrollCycleService {
  final AuthProvider _authProvider;

  PayrollCycleService(this._authProvider);

  Future<Map<String, dynamic>?> fetchSettings() async {
    if (!_authProvider.isAuthenticated) return null;
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/settings/payroll-cycle');
    final res = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_authProvider.token}',
    });
    if (res.statusCode == 200) {
      return json.decode(res.body);
    }
    throw Exception('Failed to load payroll cycle settings');
  }

  Future<void> saveSettings(Map<String, dynamic> data) async {
    if (!_authProvider.isAuthenticated) return;
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/settings/payroll-cycle');
    final res = await http.put(uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode(data));
    if (res.statusCode != 200) {
      throw Exception('Failed to save settings');
    }
  }
}
