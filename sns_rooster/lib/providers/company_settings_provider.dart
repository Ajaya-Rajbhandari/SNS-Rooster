import 'dart:io';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../services/company_settings_service.dart';
import '../utils/logger.dart';

class CompanySettingsProvider with ChangeNotifier {
  final CompanySettingsService _service;
  final AuthProvider _authProvider;

  Map<String, dynamic>? _settings;
  bool isLoading = false;
  bool isUploading = false;
  String? error;

  CompanySettingsProvider(AuthProvider auth)
      : _service = CompanySettingsService(auth),
        _authProvider = auth;

  Map<String, dynamic>? get settings => _settings;

  /// Auto-load company settings when user logs in
  Future<void> autoLoad() async {
    Logger.debug('CompanySettingsProvider.autoLoad() called');
    Logger.debug('isAuthenticated: ${_authProvider.isAuthenticated}');
    Logger.debug('_settings is null: ${_settings == null}');

    if (_authProvider.isAuthenticated && _settings == null) {
      Logger.debug('Calling load() from autoLoad()');
      await load();
    } else {
      Logger.debug('Skipping load() - conditions not met');
    }
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    Logger.debug('CompanySettingsProvider.load() called');

    try {
      final settings = await _service.fetchSettings();
      Logger.debug(
          'fetchSettings() returned: ${settings != null ? 'success' : 'null'}');

      if (settings != null) {
        _settings = settings;
        Logger.debug('Settings loaded successfully');
      } else {
        Logger.debug('Settings is null');
        error = 'Failed to load company settings';
      }
    } catch (e) {
      Logger.debug('Error loading settings: $e');
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Force refresh - clear cache and reload from server
  Future<void> forceRefresh() async {
    Logger.debug('CompanySettingsProvider.forceRefresh() called');

    // Clear current settings to force reload
    _settings = null;
    error = null;
    isLoading = true;
    notifyListeners();

    try {
      // Wait a bit to ensure any cached data is cleared
      await Future.delayed(const Duration(milliseconds: 100));

      final settings = await _service.fetchSettings();
      Logger.debug(
          'forceRefresh() fetchSettings() returned: ${settings != null ? 'success' : 'null'}');

      if (settings != null) {
        _settings = settings;
        Logger.debug('Settings force refreshed successfully');
      } else {
        Logger.debug('Settings is null after force refresh');
        error = 'Failed to load company settings';
      }
    } catch (e) {
      Logger.debug('Error force refreshing settings: $e');
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _service.saveSettings(data);
      // Only update local settings if API call succeeds
      await load(); // Reload from server to get the actual saved data
      return true;
    } catch (e) {
      error = e.toString();
      Logger.debug('CompanySettingsProvider save error: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadLogo(File logoFile) async {
    isUploading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _service.uploadLogo(logoFile);

      // Update the local settings with the new logo URL
      if (_settings != null) {
        _settings!['logoUrl'] = result['logoUrl'];
      } else {
        // If settings weren't loaded yet, load them now
        await load();
      }

      return true;
    } catch (e) {
      error = e.toString();
      Logger.debug('CompanySettingsProvider uploadLogo error: $e');
      return false;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  String get logoUrl {
    final companyInfo = _settings?['companyInfo'] ?? _settings;
    final logoPath = companyInfo?['logoUrl'] as String?;
    return CompanySettingsService.getLogoUrl(logoPath);
  }

  String get companyName =>
      (_settings?['companyInfo'] ?? _settings)?['name'] ?? 'Your Company Name';
  String get companyEmail =>
      (_settings?['companyInfo'] ?? _settings)?['email'] ?? '';
  String get companyPhone =>
      (_settings?['companyInfo'] ?? _settings)?['phone'] ?? '';
  String get companyAddress =>
      (_settings?['companyInfo'] ?? _settings)?['address'] ?? '';

  /// Clear settings data (on logout)
  void clearSettings() {
    _settings = null;
    error = null;
    isLoading = false;
    isUploading = false;
    notifyListeners();
  }
}
