import 'package:flutter/material.dart';
import '../services/super_admin_service.dart';
import '../providers/auth_provider.dart';

class SuperAdminProvider with ChangeNotifier {
  final SuperAdminService _service;

  // System Overview
  Map<String, dynamic>? _systemOverview;
  bool _isLoadingOverview = false;
  String? _overviewError;

  // Companies
  List<Map<String, dynamic>> _companies = [];
  bool _isLoadingCompanies = false;
  String? _companiesError;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCompanies = 0;

  // Subscription Plans
  List<Map<String, dynamic>> _subscriptionPlans = [];
  bool _isLoadingPlans = false;
  String? _plansError;

  // Users
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = false;
  String? _usersError;
  int _currentUsersPage = 1;
  int _totalUsersPages = 1;
  int _totalUsers = 0;

  // System Settings
  Map<String, dynamic>? _systemSettings;
  bool _isLoadingSettings = false;
  String? _settingsError;

  // System Logs
  List<Map<String, dynamic>> _systemLogs = [];
  bool _isLoadingLogs = false;
  String? _logsError;

  SuperAdminProvider(AuthProvider auth) : _service = SuperAdminService(auth);

  // ===== Getters =====

  Map<String, dynamic>? get systemOverview => _systemOverview;
  bool get isLoadingOverview => _isLoadingOverview;
  String? get overviewError => _overviewError;

  List<Map<String, dynamic>> get companies => _companies;
  bool get isLoadingCompanies => _isLoadingCompanies;
  String? get companiesError => _companiesError;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCompanies => _totalCompanies;

  List<Map<String, dynamic>> get subscriptionPlans => _subscriptionPlans;
  bool get isLoadingPlans => _isLoadingPlans;
  String? get plansError => _plansError;

  List<Map<String, dynamic>> get users => _users;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get usersError => _usersError;
  int get currentUsersPage => _currentUsersPage;
  int get totalUsersPages => _totalUsersPages;
  int get totalUsers => _totalUsers;

  Map<String, dynamic>? get systemSettings => _systemSettings;
  bool get isLoadingSettings => _isLoadingSettings;
  String? get settingsError => _settingsError;

  List<Map<String, dynamic>> get systemLogs => _systemLogs;
  bool get isLoadingLogs => _isLoadingLogs;
  String? get logsError => _logsError;

  // ===== System Overview =====

  Future<void> loadSystemOverview() async {
    _isLoadingOverview = true;
    _overviewError = null;
    notifyListeners();

    try {
      _systemOverview = await _service.getSystemOverview();
    } catch (e) {
      _overviewError = e.toString();
    } finally {
      _isLoadingOverview = false;
      notifyListeners();
    }
  }

  // ===== Company Management =====

  Future<void> loadCompanies({
    int page = 1,
    int limit = 10,
    String? status,
    String? search,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    _isLoadingCompanies = true;
    _companiesError = null;
    notifyListeners();

    try {
      final result = await _service.getAllCompanies(
        page: page,
        limit: limit,
        status: status,
        search: search,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      _companies = List<Map<String, dynamic>>.from(result['companies']);
      _currentPage = result['currentPage'];
      _totalPages = result['totalPages'];
      _totalCompanies = result['total'];
    } catch (e) {
      _companiesError = e.toString();
    } finally {
      _isLoadingCompanies = false;
      notifyListeners();
    }
  }

  Future<bool> createCompany({
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
    try {
      await _service.createCompany(
        name: name,
        domain: domain,
        subdomain: subdomain,
        adminEmail: adminEmail,
        adminPassword: adminPassword,
        adminFirstName: adminFirstName,
        adminLastName: adminLastName,
        subscriptionPlanId: subscriptionPlanId,
        contactPhone: contactPhone,
        address: address,
        notes: notes,
      );

      // Reload companies list
      await loadCompanies(page: 1);
      return true;
    } catch (e) {
      _companiesError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCompany({
    required String companyId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      await _service.updateCompany(
        companyId: companyId,
        updateData: updateData,
      );

      // Reload companies list
      await loadCompanies(page: _currentPage);
      return true;
    } catch (e) {
      _companiesError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCompany(String companyId) async {
    try {
      await _service.deleteCompany(companyId);

      // Reload companies list
      await loadCompanies(page: _currentPage);
      return true;
    } catch (e) {
      _companiesError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ===== Subscription Management =====

  Future<void> loadSubscriptionPlans() async {
    _isLoadingPlans = true;
    _plansError = null;
    notifyListeners();

    try {
      _subscriptionPlans = await _service.getSubscriptionPlans();
    } catch (e) {
      _plansError = e.toString();
    } finally {
      _isLoadingPlans = false;
      notifyListeners();
    }
  }

  Future<bool> createSubscriptionPlan(Map<String, dynamic> planData) async {
    try {
      await _service.createSubscriptionPlan(planData);
      await loadSubscriptionPlans();
      return true;
    } catch (e) {
      _plansError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSubscriptionPlan({
    required String planId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      await _service.updateSubscriptionPlan(
        planId: planId,
        updateData: updateData,
      );
      await loadSubscriptionPlans();
      return true;
    } catch (e) {
      _plansError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ===== User Management =====

  Future<void> loadUsers({
    int page = 1,
    int limit = 10,
    String? role,
    String? companyId,
    String? search,
  }) async {
    _isLoadingUsers = true;
    _usersError = null;
    notifyListeners();

    try {
      final result = await _service.getAllUsers(
        page: page,
        limit: limit,
        role: role,
        companyId: companyId,
        search: search,
      );

      _users = List<Map<String, dynamic>>.from(result['users']);
      _currentUsersPage = result['currentPage'];
      _totalUsersPages = result['totalPages'];
      _totalUsers = result['total'];
    } catch (e) {
      _usersError = e.toString();
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser({
    required String userId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      await _service.updateUser(
        userId: userId,
        updateData: updateData,
      );
      await loadUsers(page: _currentUsersPage);
      return true;
    } catch (e) {
      _usersError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _service.deleteUser(userId);
      await loadUsers(page: _currentUsersPage);
      return true;
    } catch (e) {
      _usersError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ===== System Administration =====

  Future<void> loadSystemSettings() async {
    _isLoadingSettings = true;
    _settingsError = null;
    notifyListeners();

    try {
      _systemSettings = await _service.getSystemSettings();
    } catch (e) {
      _settingsError = e.toString();
    } finally {
      _isLoadingSettings = false;
      notifyListeners();
    }
  }

  Future<bool> updateSystemSettings(Map<String, dynamic> settings) async {
    try {
      await _service.updateSystemSettings(settings);
      await loadSystemSettings();
      return true;
    } catch (e) {
      _settingsError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadSystemLogs({
    int page = 1,
    int limit = 50,
    String? level,
    String? startDate,
    String? endDate,
  }) async {
    _isLoadingLogs = true;
    _logsError = null;
    notifyListeners();

    try {
      _systemLogs = await _service.getSystemLogs(
        page: page,
        limit: limit,
        level: level,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _logsError = e.toString();
    } finally {
      _isLoadingLogs = false;
      notifyListeners();
    }
  }

  // ===== Utility Methods =====

  void clearErrors() {
    _overviewError = null;
    _companiesError = null;
    _plansError = null;
    _usersError = null;
    _settingsError = null;
    _logsError = null;
    notifyListeners();
  }

  void clearData() {
    _systemOverview = null;
    _companies = [];
    _subscriptionPlans = [];
    _users = [];
    _systemSettings = null;
    _systemLogs = [];
    clearErrors();
  }
}
