import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class SuperAdminService {
  final AuthProvider _authProvider;

  SuperAdminService(this._authProvider);

  // ===== SYSTEM OVERVIEW =====

  Future<Map<String, dynamic>> getSystemOverview() async {
    if (!_authProvider.isAuthenticated) throw Exception('Not authenticated');

    final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/system/overview');
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_authProvider.token}',
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to get system overview');
  }

  // ===== COMPANY MANAGEMENT =====

  Future<Map<String, dynamic>> getAllCompanies({
    int page = 1,
    int limit = 10,
    String? status,
    String? search,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    if (!_authProvider.isAuthenticated) throw Exception('Not authenticated');

    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    if (status != null) queryParams['status'] = status;
    if (search != null) queryParams['search'] = search;

    final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/companies')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_authProvider.token}',
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to get companies');
  }

  Future<Map<String, dynamic>> createCompany({
    required String name,
    required String domain,
    required String subdomain,
    required String adminEmail,
    required String adminPassword,
    String? adminFirstName,
    String? adminLastName,
    required String subscriptionPlanId,
    String? contactPhone,
    Map<String, dynamic>? address,
    String? notes,
  }) async {
    if (!_authProvider.isAuthenticated) throw Exception('Not authenticated');

    final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/companies');
    final body = <String, dynamic>{
      'name': name,
      'domain': domain,
      'subdomain': subdomain,
      'adminEmail': adminEmail,
      'adminPassword': adminPassword,
      'subscriptionPlanId': subscriptionPlanId,
    };

    if (adminFirstName != null) body['adminFirstName'] = adminFirstName;
    if (adminLastName != null) body['adminLastName'] = adminLastName;
    if (contactPhone != null) body['contactPhone'] = contactPhone;
    if (address != null) body['address'] = address;
    if (notes != null) body['notes'] = notes;

    final response = await http.post(uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode(body));

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create company');
  }

  Future<Map<String, dynamic>> updateCompany({
    required String companyId,
    required Map<String, dynamic> updateData,
  }) async {
    if (!_authProvider.isAuthenticated) throw Exception('Not authenticated');

    final uri =
        Uri.parse('${ApiConfig.baseUrl}/super-admin/companies/$companyId');
    final response = await http.put(uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode(updateData));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to update company');
  }

  Future<void> deleteCompany(String companyId) async {
    if (!_authProvider.isAuthenticated) throw Exception('Not authenticated');

    final uri =
        Uri.parse('${ApiConfig.baseUrl}/super-admin/companies/$companyId');
    final response = await http.delete(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_authProvider.token}',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to delete company');
    }
  }

  // ===== SUBSCRIPTION MANAGEMENT =====

  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    if (!_authProvider.isAuthenticated) throw Exception('Not authenticated');

    final uri =
        Uri.parse('${ApiConfig.baseUrl}/super-admin/subscription-plans');
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_authProvider.token}',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to get subscription plans');
  }

  Future<Map<String, dynamic>> createSubscriptionPlan(
      Map<String, dynamic> planData) async {
    if (!_authProvider.isAuthenticated) throw Exception('Not authenticated');

    final uri =
        Uri.parse('${ApiConfig.baseUrl}/super-admin/subscription-plans');
    final response = await http.post(uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode(planData));

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create subscription plan');
  }

  Future<Map<String, dynamic>> updateSubscriptionPlan({
    required String planId,
    required Map<String, dynamic> updateData,
  }) async {
    if (!_authProvider.isAuthenticated) throw Exception('Not authenticated');

    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/super-admin/subscription-plans/$planId');
    final response = await http.put(uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode(updateData));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to update subscription plan');
  }

  // ===== USER MANAGEMENT =====

  Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int limit = 10,
    String? role,
    String? companyId,
    String? search,
  }) async {
    if (!_authProvider.isAuthenticated) throw Exception('Not authenticated');

    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (role != null) queryParams['role'] = role;
    if (companyId != null) queryParams['companyId'] = companyId;
    if (search != null) queryParams['search'] = search;

    final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/users')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_authProvider.token}',
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to get users');
  }

  Future<Map<String, dynamic>> updateUser({
    required String userId,
    required Map<String, dynamic> updateData,
  }) async {
    if (!_authProvider.isAuthenticated) throw Exception('Not authenticated');

    final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/users/$userId');
    final response = await http.put(uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode(updateData));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to update user');
  }

  Future<void> deleteUser(String userId) async {
    if (!_authProvider.isAuthenticated) throw Exception('Not authenticated');

    final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/users/$userId');
    final response = await http.delete(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_authProvider.token}',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  // ===== SYSTEM ADMINISTRATION =====

  Future<Map<String, dynamic>> getSystemSettings() async {
    if (!_authProvider.isAuthenticated) throw Exception('Not authenticated');

    final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/system/settings');
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_authProvider.token}',
    });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to get system settings');
  }

  Future<Map<String, dynamic>> updateSystemSettings(
      Map<String, dynamic> settings) async {
    if (!_authProvider.isAuthenticated) throw Exception('Not authenticated');

    final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/system/settings');
    final response = await http.put(uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode(settings));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to update system settings');
  }

  Future<List<Map<String, dynamic>>> getSystemLogs({
    int page = 1,
    int limit = 50,
    String? level,
    String? startDate,
    String? endDate,
  }) async {
    if (!_authProvider.isAuthenticated) throw Exception('Not authenticated');

    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (level != null) queryParams['level'] = level;
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/system/logs')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_authProvider.token}',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to get system logs');
  }
}
