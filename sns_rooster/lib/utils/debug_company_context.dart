import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'package:sns_rooster/services/secure_storage_service.dart';
import 'package:sns_rooster/utils/logger.dart';

/// Debug utility to manually set company ID for testing
class DebugCompanyContext {
  /// Set company ID manually for testing
  static Future<void> setCompanyIdForTesting() async {
    try {
      // Use the company ID from the logs - this should be the company that owns the employees
      const companyId = '6879eab877a3baf82927dabd'; // From the logs

      await SecureStorageService.storeCompanyId(companyId);
      Logger.info('Debug: Company ID set manually for testing: $companyId');

      // Verify it was stored
      final storedCompanyId = await SecureStorageService.getCompanyId();
      Logger.info('Debug: Verified stored company ID: $storedCompanyId');
    } catch (e) {
      Logger.error('Debug: Failed to set company ID: $e');
    }
  }

  /// Check current company ID status
  static Future<void> checkCompanyIdStatus() async {
    try {
      final companyId = await SecureStorageService.getCompanyId();
      Logger.info('Debug: Current company ID: $companyId');

      if (companyId == null) {
        Logger.warning(
            'Debug: No company ID found - this will cause API failures');
      } else {
        Logger.info('Debug: Company ID is set - API calls should work');
      }
    } catch (e) {
      Logger.error('Debug: Error checking company ID: $e');
    }
  }

  /// Clear company ID for testing
  static Future<void> clearCompanyId() async {
    try {
      await SecureStorageService.clearCompanyId();
      Logger.info('Debug: Company ID cleared');
    } catch (e) {
      Logger.error('Debug: Failed to clear company ID: $e');
    }
  }

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
