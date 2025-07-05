import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../providers/auth_provider.dart';

class TaxSettingsService {
  final AuthProvider _authProvider;

  TaxSettingsService(this._authProvider);

  Future<Map<String, dynamic>?> fetchSettings() async {
    if (!_authProvider.isAuthenticated) return null;
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/settings/tax');
    final res = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_authProvider.token}',
    });
    if (res.statusCode == 200) {
      return json.decode(res.body);
    }
    throw Exception('Failed to load tax settings');
  }

  Future<void> saveSettings(Map<String, dynamic> data) async {
    if (!_authProvider.isAuthenticated) return;
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/settings/tax');
    final res = await http.put(uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode(data));
    if (res.statusCode != 200) {
      final error = json.decode(res.body);
      throw Exception(error['message'] ?? 'Failed to save tax settings');
    }
  }
}
