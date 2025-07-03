import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../services/tax_settings_service.dart';
import '../utils/logger.dart';

class TaxSettingsProvider with ChangeNotifier {
  final TaxSettingsService _service;

  Map<String, dynamic>? _settings;
  bool isLoading = false;
  String? error;

  TaxSettingsProvider(AuthProvider auth) : _service = TaxSettingsService(auth);

  Map<String, dynamic>? get settings => _settings;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      _settings = await _service.fetchSettings();
    } catch (e) {
      error = e.toString();
      log('TaxSettingsProvider load error: $e');
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
      _settings = data;
      return true;
    } catch (e) {
      error = e.toString();
      log('TaxSettingsProvider save error: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
