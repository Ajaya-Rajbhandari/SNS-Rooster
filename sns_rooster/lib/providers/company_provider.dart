import 'package:flutter/material.dart';
import 'package:sns_rooster/models/company.dart';
import 'package:sns_rooster/services/company_service.dart';
import 'package:sns_rooster/services/secure_storage_service.dart';
import 'package:sns_rooster/utils/logger.dart';

class CompanyProvider with ChangeNotifier {
  Company? _currentCompany;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _usage = {};
  Map<String, dynamic> _limits = {};

  // Getters
  Company? get currentCompany => _currentCompany;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get usage => _usage;
  Map<String, dynamic> get limits => _limits;

  // Company status
  bool get isCompanyLoaded => _currentCompany != null;
  bool get isCompanyActive => _currentCompany?.isActive ?? false;

  // Subscription plan checks
  bool get isBasicPlan => _currentCompany?.isBasicPlan() ?? false;
  bool get isProPlan => _currentCompany?.isProPlan() ?? false;
  bool get isEnterprisePlan => _currentCompany?.isEnterprisePlan() ?? false;

  CompanyProvider() {
    // Disable automatic initialization to prevent errors with non-existent endpoints
    // _initializeCompany();
  }

  /// Initialize company data
  Future<void> _initializeCompany() async {
    try {
      // Try to load from storage first
      await loadStoredCompany();

      // Then try to fetch fresh data from server
      await fetchCurrentCompany();
    } catch (e) {
      Logger.error('Error initializing company: $e');
    }
  }

  /// Load company data from local storage
  Future<void> loadStoredCompany() async {
    try {
      final company = await CompanyService.getStoredCompany();
      if (company != null) {
        _currentCompany = company;
        _loadCompanyData();
        notifyListeners();
      }
    } catch (e) {
      Logger.error('Error loading stored company: $e');
    }
  }

  /// Fetch current company data from server
  Future<void> fetchCurrentCompany() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final company = await CompanyService.getCurrentCompany();
      if (company != null) {
        _currentCompany = company;
        _loadCompanyData();
        _error = null;
      } else {
        _error = 'Failed to load company data';
      }
    } catch (e) {
      Logger.error('Error fetching company: $e');
      _error = 'Error loading company data';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load company usage and limits data
  void _loadCompanyData() {
    if (_currentCompany != null) {
      _usage = _currentCompany!.usage;
      _limits = _currentCompany!.limits;
    }
  }

  /// Check if a feature is enabled
  bool isFeatureEnabled(String feature) {
    return _currentCompany?.hasFeature(feature) ?? false;
  }

  /// Check if usage is within limits
  bool isWithinLimit(String limitKey) {
    return _currentCompany?.isWithinLimit(limitKey) ?? false;
  }

  /// Get current usage for a specific metric
  int getCurrentUsage(String usageKey) {
    return _currentCompany?.getUsage(usageKey) ?? 0;
  }

  /// Get limit for a specific metric
  int getLimit(String limitKey) {
    return _currentCompany?.getLimit(limitKey) ?? 0;
  }

  /// Get usage percentage for a specific metric
  double getUsagePercentage(String limitKey) {
    final limit = getLimit(limitKey);
    final usage = getCurrentUsage(limitKey);

    if (limit == 0) return 0.0; // Unlimited
    if (usage == 0) return 0.0;

    return (usage / limit) * 100;
  }

  /// Update company information
  Future<bool> updateCompany(Map<String, dynamic> updates) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await CompanyService.updateCompany(updates);
      if (success) {
        // Refresh company data
        await fetchCurrentCompany();
        return true;
      } else {
        _error = 'Failed to update company';
        return false;
      }
    } catch (e) {
      Logger.error('Error updating company: $e');
      _error = 'Error updating company';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh company data
  Future<void> refreshCompany() async {
    await fetchCurrentCompany();
  }

  /// Clear company data (on logout)
  Future<void> clearCompany() async {
    _currentCompany = null;
    _usage = {};
    _limits = {};
    _error = null;
    _isLoading = false;
    await SecureStorageService.clearCompanyData();
    notifyListeners();
  }

  /// Get company name
  String get companyName => _currentCompany?.name ?? 'Unknown Company';

  /// Get company domain
  String get companyDomain => _currentCompany?.domain ?? '';

  /// Get company subdomain
  String get companySubdomain => _currentCompany?.subdomain ?? '';

  /// Get subscription plan name
  String get subscriptionPlanName {
    final plan = _currentCompany?.subscriptionPlan ?? 'basic';
    switch (plan) {
      case 'basic':
        return 'Basic';
      case 'pro':
        return 'Pro';
      case 'enterprise':
        return 'Enterprise';
      default:
        return 'Basic';
    }
  }

  /// Check if company has analytics feature
  bool get hasAnalytics => isFeatureEnabled('analytics');

  /// Check if company has advanced reporting
  bool get hasAdvancedReporting => isFeatureEnabled('advancedReporting');

  /// Check if company has custom branding
  bool get hasCustomBranding => isFeatureEnabled('customBranding');

  /// Check if company has API access
  bool get hasApiAccess => isFeatureEnabled('apiAccess');

  /// Check if company has priority support
  bool get hasPrioritySupport => isFeatureEnabled('prioritySupport');

  /// Get employee limit
  int get employeeLimit => getLimit('employees');

  /// Get current employee count
  int get currentEmployeeCount => getCurrentUsage('employees');

  /// Get storage limit (in MB)
  int get storageLimit => getLimit('storage');

  /// Get current storage usage (in MB)
  int get currentStorageUsage => getCurrentUsage('storage');

  /// Get API request limit
  int get apiRequestLimit => getLimit('apiRequests');

  /// Get current API request count
  int get currentApiRequestCount => getCurrentUsage('apiRequests');

  /// Check if employee limit is reached
  bool get isEmployeeLimitReached {
    final limit = employeeLimit;
    return limit > 0 && currentEmployeeCount >= limit;
  }

  /// Check if storage limit is reached
  bool get isStorageLimitReached {
    final limit = storageLimit;
    return limit > 0 && currentStorageUsage >= limit;
  }

  /// Check if API request limit is reached
  bool get isApiRequestLimitReached {
    final limit = apiRequestLimit;
    return limit > 0 && currentApiRequestCount >= limit;
  }

  /// Get employee usage percentage
  double get employeeUsagePercentage => getUsagePercentage('employees');

  /// Get storage usage percentage
  double get storageUsagePercentage => getUsagePercentage('storage');

  /// Get API request usage percentage
  double get apiRequestUsagePercentage => getUsagePercentage('apiRequests');
}
