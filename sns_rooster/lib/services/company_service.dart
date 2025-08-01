import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sns_rooster/config/api_config.dart';
import 'package:sns_rooster/models/company.dart';
import 'package:sns_rooster/services/secure_storage_service.dart';
import 'package:sns_rooster/utils/logger.dart';

class CompanyService {
  static String get _baseUrl => ApiConfig.baseUrl;

  /// Get available companies for login selection
  static Future<List<Company>> getAvailableCompanies() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/companies/available'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final companiesData = data['companies'] as List;

        return companiesData.map((companyData) {
          return Company.fromJson(companyData);
        }).toList();
      } else {
        Logger.error(
            'Failed to get available companies: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      Logger.error('Error getting available companies: $e');
      return [];
    }
  }

  /// Get company information for the current user
  static Future<Company?> getCurrentCompany() async {
    try {
      final token = await SecureStorageService.getAuthToken();
      final companyId = await SecureStorageService.getCompanyId();

      if (token == null || companyId == null) {
        Logger.error('No token or company ID available');
        return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/companies/$companyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-company-id': companyId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final company = Company.fromJson(data['company']);

        // Store company data for offline access
        await SecureStorageService.storeCompanyData(
            json.encode(data['company']));

        return company;
      } else {
        Logger.error(
            'Failed to get company: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      Logger.error('Error getting company: $e');
      return null;
    }
  }

  /// Get company information from local storage
  static Future<Company?> getStoredCompany() async {
    try {
      final companyData = await SecureStorageService.getCompanyData();
      if (companyData != null) {
        final data = json.decode(companyData);
        return Company.fromJson(data);
      }
      return null;
    } catch (e) {
      Logger.error('Error getting stored company: $e');
      return null;
    }
  }

  /// Update company information
  static Future<bool> updateCompany(Map<String, dynamic> updates) async {
    try {
      final token = await SecureStorageService.getAuthToken();
      final companyId = await SecureStorageService.getCompanyId();

      if (token == null || companyId == null) {
        Logger.error('No token or company ID available');
        return false;
      }

      final response = await http.patch(
        Uri.parse('$_baseUrl/companies/$companyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-company-id': companyId,
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Update stored company data
        await SecureStorageService.storeCompanyData(
            json.encode(data['company']));

        return true;
      } else {
        Logger.error(
            'Failed to update company: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      Logger.error('Error updating company: $e');
      return false;
    }
  }

  /// Get company usage statistics
  static Future<Map<String, dynamic>?> getCompanyUsage() async {
    try {
      final token = await SecureStorageService.getAuthToken();
      final companyId = await SecureStorageService.getCompanyId();

      if (token == null || companyId == null) {
        Logger.error('No token or company ID available');
        return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/companies/$companyId/usage'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-company-id': companyId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['usage'];
      } else {
        Logger.error(
            'Failed to get company usage: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      Logger.error('Error getting company usage: $e');
      return null;
    }
  }

  /// Check if a feature is enabled for the current company
  static Future<bool> isFeatureEnabled(String feature) async {
    try {
      final company = await getCurrentCompany() ?? await getStoredCompany();
      return company?.hasFeature(feature) ?? false;
    } catch (e) {
      Logger.error('Error checking feature: $e');
      return false;
    }
  }

  /// Check if usage is within limits for the current company
  static Future<bool> isWithinLimit(String limitKey) async {
    try {
      final company = await getCurrentCompany() ?? await getStoredCompany();
      return company?.isWithinLimit(limitKey) ?? false;
    } catch (e) {
      Logger.error('Error checking limit: $e');
      return false;
    }
  }

  /// Get company subscription plan
  static Future<String?> getSubscriptionPlan() async {
    try {
      final company = await getCurrentCompany() ?? await getStoredCompany();
      return company?.subscriptionPlan;
    } catch (e) {
      Logger.error('Error getting subscription plan: $e');
      return null;
    }
  }

  /// Check if company is on basic plan
  static Future<bool> isBasicPlan() async {
    final plan = await getSubscriptionPlan();
    return plan == 'basic';
  }

  /// Check if company is on pro plan
  static Future<bool> isProPlan() async {
    final plan = await getSubscriptionPlan();
    return plan == 'pro';
  }

  /// Check if company is on enterprise plan
  static Future<bool> isEnterprisePlan() async {
    final plan = await getSubscriptionPlan();
    return plan == 'enterprise';
  }

  /// Get company limits
  static Future<Map<String, dynamic>> getCompanyLimits() async {
    try {
      final company = await getCurrentCompany() ?? await getStoredCompany();
      return company?.limits ?? {};
    } catch (e) {
      Logger.error('Error getting company limits: $e');
      return {};
    }
  }

  /// Get company usage
  static Future<Map<String, dynamic>> getCompanyUsageData() async {
    try {
      final company = await getCurrentCompany() ?? await getStoredCompany();
      return company?.usage ?? {};
    } catch (e) {
      Logger.error('Error getting company usage: $e');
      return {};
    }
  }
}
