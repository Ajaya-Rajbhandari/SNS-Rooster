import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class DebugCompanyContext {
  static Future<void> debugCompanyContext() async {
    print('🔍 DEBUGGING COMPANY CONTEXT');
    print('============================');

    // Check stored company ID
    final companyId = await SecureStorageService.getCompanyId();
    print('📱 Stored Company ID: $companyId');

    // Check stored auth token
    final authToken = await SecureStorageService.getAuthToken();
    print(
        '🔑 Stored Auth Token: ${authToken != null ? 'Present (${authToken.length} chars)' : 'None'}');

    // Check API service headers manually
    final token = await SecureStorageService.getAuthToken();
    final storedCompanyId = await SecureStorageService.getCompanyId();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    // Add company context header if available
    if (storedCompanyId != null && storedCompanyId.isNotEmpty) {
      headers['x-company-id'] = storedCompanyId;
    }

    print('📡 API Headers:');
    headers.forEach((key, value) {
      if (key == 'Authorization') {
        print(
            '   $key: ${value.length > 20 ? '${value.substring(0, 20)}...' : value}');
      } else {
        print('   $key: $value');
      }
    });

    print('============================');
  }

  static Future<void> showDebugDialog(BuildContext context) async {
    await debugCompanyContext();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Debug Info'),
            content:
                const Text('Check console for detailed debug information.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  static Future<void> testPayrollApi() async {
    print('🧪 TESTING PAYROLL API');
    print('======================');

    try {
      final apiService = ApiService(baseUrl: ApiConfig.baseUrl);

      print('📡 Making test request to /payroll/test...');
      final response = await apiService.get('/payroll/test');

      print('✅ Response Status: ${response.success}');
      print('📝 Response Message: ${response.message}');
      print('📊 Response Data: ${response.data}');
    } catch (e) {
      print('❌ Error testing payroll API: $e');
    }

    print('======================');
  }
}
