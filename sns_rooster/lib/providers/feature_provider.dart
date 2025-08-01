import 'package:flutter/foundation.dart';
import '../services/feature_service.dart';
import '../providers/auth_provider.dart';
import '../utils/logger.dart';

class FeatureProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  late final FeatureService _featureService;

  FeatureProvider(this.authProvider) {
    _featureService = FeatureService(authProvider);
    // Initialize features when provider is created
    _initializeFeatures();
  }

  /// Initialize features when provider is created
  Future<void> _initializeFeatures() async {
    await loadFeatures();
  }

  // State variables
  bool _isLoading = false;
  String? _error;
  Map<String, bool> _features = {};
  Map<String, int> _limits = {};
  Map<String, int> _usage = {};
  Map<String, dynamic> _subscriptionPlan = {};
  Map<String, dynamic> _companyInfo = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, bool> get features => _features;
  Map<String, int> get limits => _limits;
  Map<String, int> get usage => _usage;
  Map<String, dynamic> get subscriptionPlan => _subscriptionPlan;
  Map<String, dynamic> get companyInfo => _companyInfo;

  // Convenience getters
  bool get isBasicPlan =>
      _subscriptionPlan['name']?.toString().toLowerCase() == 'basic';
  bool get isProfessionalPlan =>
      _subscriptionPlan['name']?.toString().toLowerCase() == 'professional';
  bool get isEnterprisePlan =>
      _subscriptionPlan['name']?.toString().toLowerCase() == 'enterprise';
  bool get isCompanyActive => _companyInfo['status'] == 'active';
  bool get isCompanyInTrial => _companyInfo['status'] == 'trial';
  String get companyName => _companyInfo['name'] ?? '';
  String get companyDomain => _companyInfo['domain'] ?? '';
  String get companySubdomain => _companyInfo['subdomain'] ?? '';

  // Feature checks
  bool get hasAttendance => _features['attendance'] ?? false;
  bool get hasPayroll => _features['payroll'] ?? false;
  bool get hasLeaveManagement => _features['leaveManagement'] ?? false;
  bool get hasAnalytics => _features['analytics'] ?? false;
  bool get hasDocumentManagement => _features['documentManagement'] ?? false;
  bool get hasNotifications => _features['notifications'] ?? false;
  bool get hasCustomBranding => _features['customBranding'] ?? false;
  bool get hasApiAccess => _features['apiAccess'] ?? false;
  bool get hasMultiLocation =>
      _features['multiLocationSupport'] ??
      _features['locationManagement'] ??
      false;
  bool get hasAdvancedReporting => _features['advancedReporting'] ?? false;
  bool get hasDataExport => _features['dataExport'] ?? false;
  bool get hasTimeTracking => _features['timeTracking'] ?? false;
  bool get hasExpenseManagement => _features['expenseManagement'] ?? false;
  bool get hasPerformanceReviews => _features['performanceReviews'] ?? false;
  bool get hasTrainingManagement => _features['trainingManagement'] ?? false;
  bool get hasLocationBasedAttendance =>
      _features['locationBasedAttendance'] ?? false;
  bool get hasLocationManagement => _features['locationManagement'] ?? false;
  bool get hasLocationSettings => _features['locationSettings'] ?? false;
  bool get hasLocationNotifications =>
      _features['locationNotifications'] ?? false;
  bool get hasLocationGeofencing => _features['locationGeofencing'] ?? false;
  bool get hasLocationCapacity => _features['locationCapacity'] ?? false;

  // Employee Features
  bool get hasEvents => _features['events'] ?? false;
  bool get hasProfile => _features['profile'] ?? true;
  bool get hasCompanyInfo => _features['companyInfo'] ?? true;

  // Admin Features
  bool get hasEmployeeManagement => _features['employeeManagement'] ?? false;
  bool get hasTimesheetApprovals => _features['timesheetApprovals'] ?? false;
  bool get hasAttendanceManagement =>
      _features['attendanceManagement'] ?? false;
  bool get hasBreakManagement => _features['breakManagement'] ?? false;
  bool get hasBreakTypes => _features['breakTypes'] ?? false;
  bool get hasUserManagement => _features['userManagement'] ?? false;
  bool get hasSettings => _features['settings'] ?? false;
  bool get hasCompanySettings => _features['companySettings'] ?? false;
  bool get hasFeatureManagement => _features['featureManagement'] ?? false;
  bool get hasHelpSupport => _features['helpSupport'] ?? false;

  // Usage checks
  int get employeeCount => _usage['currentEmployeeCount'] ?? 0;
  int get maxEmployees => _limits['maxEmployees'] ?? 0;
  int get employeeUsagePercentage => getUsagePercentage('maxEmployees');
  bool get isWithinEmployeeLimit =>
      maxEmployees == 0 || employeeCount < maxEmployees;

  int get storageUsage => _usage['currentStorageGB'] ?? 0;
  int get maxStorage => _limits['maxStorageGB'] ?? 0;
  int get storageUsagePercentage => getUsagePercentage('maxStorageGB');
  bool get isWithinStorageLimit => maxStorage == 0 || storageUsage < maxStorage;

  int get apiCallCount => _usage['currentApiCallsToday'] ?? 0;
  int get maxApiCalls => _limits['maxApiCallsPerDay'] ?? 0;
  int get apiCallUsagePercentage => getUsagePercentage('maxApiCallsPerDay');
  bool get isWithinApiCallLimit =>
      maxApiCalls == 0 || apiCallCount < maxApiCalls;

  /// Load company features and limits
  Future<void> loadFeatures() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final data = await _featureService.getCompanyFeatures();

      // Convert features data properly, handling both boolean and integer values
      final rawFeatures = data['features'] ?? {};
      _features = <String, bool>{};
      rawFeatures.forEach((key, value) {
        if (value is bool) {
          _features[key] = value;
        } else if (value is int) {
          // Convert integer values to boolean (non-zero = true, zero = false)
          _features[key] = value != 0;
        } else if (value is String) {
          // Convert string values to boolean
          _features[key] = value.toLowerCase() == 'true' || value == '1';
        } else {
          // Default to false for unknown types
          _features[key] = false;
        }
      });

      _limits = Map<String, int>.from(data['limits'] ?? {});
      _usage = Map<String, int>.from(data['usage'] ?? {});
      _subscriptionPlan =
          Map<String, dynamic>.from(data['subscriptionPlan'] ?? {});
      _companyInfo = Map<String, dynamic>.from(data['company'] ?? {});

      Logger.info('Features loaded successfully');
    } catch (e) {
      Logger.error('Error loading features: $e');
      _error = 'Error loading features: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if a specific feature is enabled
  bool isFeatureEnabled(String featureName) {
    return _features[featureName] ?? false;
  }

  /// Check if usage is within a specific limit
  bool isWithinLimit(String limitKey) {
    // Map limit keys to usage keys
    final usageKeyMap = {
      'maxEmployees': 'currentEmployeeCount',
      'maxStorageGB': 'currentStorageGB',
      'maxApiCallsPerDay': 'currentApiCallsToday',
    };

    final usageKey = usageKeyMap[limitKey] ?? limitKey;
    final usage = _usage[usageKey] ?? 0;
    final limit = _limits[limitKey] ?? 0;
    return limit == 0 || usage < limit; // 0 means unlimited
  }

  /// Get usage percentage for a limit
  int getUsagePercentage(String limitKey) {
    // Map limit keys to usage keys
    final usageKeyMap = {
      'maxEmployees': 'currentEmployeeCount',
      'maxStorageGB': 'currentStorageGB',
      'maxApiCallsPerDay': 'currentApiCallsToday',
    };

    final usageKey = usageKeyMap[limitKey] ?? limitKey;
    final usage = _usage[usageKey] ?? 0;
    final limit = _limits[limitKey] ?? 0;
    if (limit == 0) return 0;
    final percentage = ((usage / limit) * 100).round();
    return percentage > 100 ? 100 : percentage;
  }

  /// Get current usage for a limit
  int getCurrentUsage(String limitKey) {
    // Map limit keys to usage keys
    final usageKeyMap = {
      'maxEmployees': 'currentEmployeeCount',
      'maxStorageGB': 'currentStorageGB',
      'maxApiCallsPerDay': 'currentApiCallsToday',
    };

    final usageKey = usageKeyMap[limitKey] ?? limitKey;
    return _usage[usageKey] ?? 0;
  }

  /// Get limit value
  int getLimit(String limitKey) {
    return _limits[limitKey] ?? 0;
  }

  /// Get all available features
  List<String> getAvailableFeatures() {
    return _features.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  /// Refresh features (reload from server)
  Future<void> refreshFeatures() async {
    await loadFeatures();
  }

  /// Force refresh features (clear cache and reload)
  Future<void> forceRefreshFeatures() async {
    _features.clear();
    _limits.clear();
    _usage.clear();
    _subscriptionPlan.clear();
    _companyInfo.clear();
    _error = null;
    _isLoading = true;
    notifyListeners();

    await loadFeatures();
  }

  /// Clear all feature data (on logout)
  void clearFeatures() {
    _features.clear();
    _limits.clear();
    _usage.clear();
    _subscriptionPlan.clear();
    _companyInfo.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Get subscription plan name
  String get subscriptionPlanName {
    // If still loading, return a loading indicator
    if (_isLoading) {
      return 'Loading...';
    }

    return _subscriptionPlan['name'] ?? 'No Plan';
  }

  /// Get subscription plan price
  Map<String, dynamic>? get subscriptionPlanPrice => _subscriptionPlan['price'];

  /// Check if subscription plan is properly loaded
  bool get isSubscriptionPlanLoaded {
    final hasName = _subscriptionPlan['name'] != null &&
        _subscriptionPlan['name'].toString().isNotEmpty;
    final hasPrice = _subscriptionPlan['price'] != null;
    final isNotLoading = !_isLoading;
    return hasName && hasPrice && isNotLoading;
  }

  /// Check if any limit is exceeded
  bool get hasExceededLimits {
    return !isWithinEmployeeLimit ||
        !isWithinStorageLimit ||
        !isWithinApiCallLimit;
  }

  /// Get exceeded limits
  List<String> get exceededLimits {
    final exceeded = <String>[];
    if (!isWithinEmployeeLimit) exceeded.add('maxEmployees');
    if (!isWithinStorageLimit) exceeded.add('maxStorageGB');
    if (!isWithinApiCallLimit) exceeded.add('maxApiCallsPerDay');
    return exceeded;
  }

  /// Get usage warnings (above 80%)
  List<String> get usageWarnings {
    final warnings = <String>[];
    if (employeeUsagePercentage > 80) warnings.add('maxEmployees');
    if (storageUsagePercentage > 80) warnings.add('maxStorageGB');
    if (apiCallUsagePercentage > 80) warnings.add('maxApiCallsPerDay');
    return warnings;
  }
}
