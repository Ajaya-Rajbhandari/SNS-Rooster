import 'dart:io';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../services/company_settings_service.dart';
import '../utils/logger.dart';

class CompanySettingsProvider with ChangeNotifier {
  final CompanySettingsService _service;

  Map<String, dynamic>? _settings;
  bool isLoading = false;
  bool isUploading = false;
  String? error;

  CompanySettingsProvider(AuthProvider auth)
      : _service = CompanySettingsService(auth);

  Map<String, dynamic>? get settings => _settings;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      _settings = await _service.fetchSettings();
    } catch (e) {
      error = e.toString();
      log('CompanySettingsProvider load error: $e');
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
      log('CompanySettingsProvider save error: $e');
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
      log('CompanySettingsProvider uploadLogo error: $e');
      return false;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  String get logoUrl {
    final logoPath = _settings?['logoUrl'] as String?;
    return CompanySettingsService.getLogoUrl(logoPath);
  }

  String get companyName => _settings?['name'] ?? 'Your Company Name';
  String get companyEmail => _settings?['email'] ?? '';
  String get companyPhone => _settings?['phone'] ?? '';
  String get companyAddress => _settings?['address'] ?? '';
}
