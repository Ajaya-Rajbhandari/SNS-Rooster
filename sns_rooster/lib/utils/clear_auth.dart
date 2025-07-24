import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import 'dart:convert';

class ClearAuth {
  static Future<void> clearAllAuthData() async {
    try {
      await SecureStorageService.clearAllData();
      print('✅ All auth data cleared successfully');
    } catch (e) {
      print('❌ Error clearing auth data: $e');
    }
  }

  static Future<void> clearCompanyContext() async {
    try {
      await SecureStorageService.clearCompanyData();
      print('✅ Company context cleared successfully');
    } catch (e) {
      print('❌ Error clearing company context: $e');
    }
  }

  static Future<void> refreshCompanyContext() async {
    try {
      // Clear and then try to reload from user data
      await SecureStorageService.clearCompanyData();
      final userData = await SecureStorageService.getUserData();
      if (userData != null) {
        final user = Map<String, dynamic>.from(json.decode(userData));
        if (user['companyId'] != null) {
          await SecureStorageService.storeCompanyId(
              user['companyId'].toString());
          print('✅ Company context refreshed: ${user['companyId']}');
        } else {
          print('⚠️  No company ID found in user data');
        }
      } else {
        print('⚠️  No user data found');
      }
    } catch (e) {
      print('❌ Error refreshing company context: $e');
    }
  }

  static Future<void> showClearAuthDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Authentication'),
          content: const Text(
            'This will clear all stored authentication data and log you out. '
            'You will need to log in again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await clearAllAuthData();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  // Navigate to login screen
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
              child: const Text('Clear & Logout'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showRefreshCompanyContextDialog(
      BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Refresh Company Context'),
          content: const Text(
            'This will refresh your company context. '
            'This might fix issues with payroll and other company-specific features.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await refreshCompanyContext();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Company context refreshed. Try accessing payroll again.'),
                    ),
                  );
                }
              },
              child: const Text('Refresh'),
            ),
          ],
        );
      },
    );
  }
}
