import '../providers/auth_provider.dart';
import '../config/api_config.dart';
import '../utils/logger.dart';
import 'api_service.dart';

class FeatureService {
  final AuthProvider authProvider;
  late final ApiService _apiService;

  FeatureService(this.authProvider) {
    _apiService = ApiService(baseUrl: ApiConfig.baseUrl);
  }

  /// Get company features and subscription plan
  Future<Map<String, dynamic>> getCompanyFeatures() async {
    try {
      final response = await _apiService.get('/companies/features');

      if (response.success) {
        final data = response.data as Map<String, dynamic>;
        return {
          'features': data['features'] ?? {},
          'subscriptionPlan': data['subscriptionPlan'] ?? {},
          'company': data['company'] ?? {},
          'limits': data['limits'] ?? {},
        };
      } else {
        // If the API call fails, try to get default features based on user's company
        Logger.info(
            'FeatureService: API call failed, trying fallback approach');
        return await _getFallbackFeatures();
      }
    } catch (e) {
      Logger.info('FeatureService: Error fetching features: $e');
      // Return fallback features if there's an error
      return await _getFallbackFeatures();
    }
  }

  /// Get fallback features when API call fails
  Future<Map<String, dynamic>> _getFallbackFeatures() async {
    try {
      final user = authProvider.user;
      final userCompanyId = user?['companyId'];

      if (userCompanyId != null) {
        Logger.info(
            'FeatureService: Using user company ID as fallback: $userCompanyId');
        // Try to get features using user's company ID
        final response = await _apiService.get('/companies/features');

        if (response.success) {
          final data = response.data as Map<String, dynamic>;
          return {
            'features': data['features'] ?? {},
            'subscriptionPlan': data['subscriptionPlan'] ?? {},
            'company': data['company'] ?? {},
            'limits': data['limits'] ?? {},
          };
        }
      }

      // Return default features if everything fails
      Logger.info('FeatureService: Returning default features');
      return {
        'features': {
          'attendance': true,
          'payroll': false, // Basic plan: no payroll
          'leaveManagement': true,
          'analytics': false, // Basic plan: no analytics
          'documentManagement': false, // Basic plan: no document management
          'notifications': true,
          'customBranding': false,
          'apiAccess': false,
          'multiLocation': false,
          'advancedReporting': false,
          'timeTracking': true,
          'expenseManagement': false,
          'performanceReviews': false,
          'trainingManagement': false,
          'locationBasedAttendance': false,
        },
        'subscriptionPlan': {
          'name': 'Basic',
          'price': {'monthly': 29, 'yearly': 290},
        },
        'company': {
          'name': user?['companyName'] ?? 'Default Company',
          'status': 'active',
        },
        'limits': {
          'maxEmployees': 10,
          'maxStorageGB': 5,
          'maxApiCallsPerDay': 1000,
          'maxDepartments': 3,
          'dataRetention': 365,
        },
      };
    } catch (e) {
      Logger.info('FeatureService: Error in fallback: $e');
      // Return basic features as last resort
      return {
        'features': {
          'attendance': true,
          'payroll': false, // Basic plan: no payroll
          'leaveManagement': true,
          'analytics': false, // Basic plan: no analytics
          'documentManagement': false, // Basic plan: no document management
          'notifications': true,
          'customBranding': false,
          'apiAccess': false,
          'multiLocation': false,
          'advancedReporting': false,
          'timeTracking': true,
          'expenseManagement': false,
          'performanceReviews': false,
          'trainingManagement': false,
          'locationBasedAttendance': false,
          'locationManagement': false,
          'locationSettings': false,
          'locationNotifications': false,
          'locationGeofencing': false,
          'locationCapacity': false,
        },
        'subscriptionPlan': {
          'name': 'Basic',
          'price': {'monthly': 0, 'yearly': 0},
        },
        'company': {
          'name': 'Default Company',
          'status': 'active',
        },
        'limits': {
          'maxEmployees': 10,
          'maxStorageGB': 5,
          'maxApiCallsPerDay': 1000,
        },
      };
    }
  }

  /// Check if a specific feature is enabled for the company
  Future<bool> isFeatureEnabled(String featureName) async {
    try {
      final features = await getCompanyFeatures();
      final companyFeatures = features['features'] as Map<String, dynamic>?;

      return companyFeatures?[featureName] == true;
    } catch (e) {
      print('Error checking feature $featureName: $e');
      return false; // Default to false if there's an error
    }
  }

  /// Get available features for the current user role
  Future<Map<String, bool>> getAvailableFeatures() async {
    try {
      final features = await getCompanyFeatures();
      final companyFeatures =
          features['features'] as Map<String, dynamic>? ?? {};
      final user = authProvider.user;
      final userRole = user?['role'] ?? 'employee';

      // Define feature availability based on role and subscription
      final availableFeatures = <String, bool>{};

      // Core features available to all roles if enabled
      availableFeatures['attendance'] = companyFeatures['attendance'] == true;
      availableFeatures['profile'] = true; // Always available
      availableFeatures['notifications'] =
          companyFeatures['notifications'] == true;

      // Role-specific features
      if (userRole == 'admin' || userRole == 'super_admin') {
        // Admin features
        availableFeatures['payroll'] = companyFeatures['payroll'] == true;
        availableFeatures['leaveManagement'] =
            companyFeatures['leaveManagement'] == true;
        availableFeatures['analytics'] = companyFeatures['analytics'] == true;
        availableFeatures['documentManagement'] =
            companyFeatures['documentManagement'] == true;
        availableFeatures['employeeManagement'] = true;
        availableFeatures['settings'] = true;
        availableFeatures['reports'] =
            companyFeatures['advancedReporting'] == true;
        availableFeatures['locationManagement'] =
            companyFeatures['locationManagement'] == true;
        availableFeatures['locationSettings'] =
            companyFeatures['locationSettings'] == true;
        availableFeatures['locationNotifications'] =
            companyFeatures['locationNotifications'] == true;
        availableFeatures['locationGeofencing'] =
            companyFeatures['locationGeofencing'] == true;
        availableFeatures['locationCapacity'] =
            companyFeatures['locationCapacity'] == true;
        availableFeatures['expenseManagement'] =
            companyFeatures['expenseManagement'] == true;
        availableFeatures['performanceReviews'] =
            companyFeatures['performanceReviews'] == true;
        availableFeatures['trainingManagement'] =
            companyFeatures['trainingManagement'] == true;
      } else {
        // Employee features (only if enabled in subscription)
        availableFeatures['payroll'] = companyFeatures['payroll'] == true;
        availableFeatures['leaveManagement'] =
            companyFeatures['leaveManagement'] == true;
        availableFeatures['analytics'] = companyFeatures['analytics'] == true;
        availableFeatures['documentManagement'] =
            companyFeatures['documentManagement'] == true;
        availableFeatures['timeTracking'] =
            companyFeatures['timeTracking'] == true;
        availableFeatures['expenseManagement'] =
            companyFeatures['expenseManagement'] == true;
        availableFeatures['performanceReviews'] =
            companyFeatures['performanceReviews'] == true;
        availableFeatures['trainingManagement'] =
            companyFeatures['trainingManagement'] == true;

        // Employee-specific features
        availableFeatures['timesheet'] = true; // Always available for employees
        availableFeatures['events'] = true; // Always available for employees
        availableFeatures['companyInfo'] =
            true; // Always available for employees
      }

      return availableFeatures;
    } catch (e) {
      print('Error getting available features: $e');
      // Return basic features if there's an error
      return {
        'attendance': true,
        'profile': true,
        'notifications': true,
        'timesheet': true,
        'events': true,
        'companyInfo': true,
      };
    }
  }

  /// Get subscription plan information
  Future<Map<String, dynamic>> getSubscriptionInfo() async {
    try {
      final features = await getCompanyFeatures();
      final subscriptionPlan =
          features['subscriptionPlan'] as Map<String, dynamic>? ?? {};
      final company = features['company'] as Map<String, dynamic>? ?? {};

      return {
        'planName': subscriptionPlan['name'] ?? 'Basic',
        'planType': subscriptionPlan['type'] ?? 'basic',
        'status': company['status'] ?? 'active',
        'features': features['features'] ?? {},
        'limits': features['limits'] ?? {},
        'trialSubscriptionPlan': company['trialSubscriptionPlan'],
        'trialPlanName': company['trialPlanName'],
        'trialStartDate': company['trialStartDate'],
        'trialEndDate': company['trialEndDate'],
        'trialDurationDays': company['trialDurationDays'],
        'trialExpired': company['trialExpired'],
      };
    } catch (e) {
      return {
        'planName': 'Basic',
        'planType': 'basic',
        'status': 'active',
        'features': {},
        'limits': {},
        'trialSubscriptionPlan': 'basic',
        'trialPlanName': 'Basic Trial',
        'trialExpired': false,
      };
    }
  }

  /// Check if the company is in trial period
  Future<bool> isInTrial() async {
    try {
      final features = await getCompanyFeatures();
      final company = features['company'] as Map<String, dynamic>? ?? {};
      return company['status'] == 'trial';
    } catch (e) {
      return false;
    }
  }

  /// Get trial status information
  Future<Map<String, dynamic>?> getTrialStatus() async {
    try {
      final response = await _apiService.get('/trial/status');

      if (response.success) {
        return response.data as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
