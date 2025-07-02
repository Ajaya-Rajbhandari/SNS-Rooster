import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import 'package:sns_rooster/utils/logger.dart';

class AdminSettingsProvider with ChangeNotifier {
  final AuthProvider _authProvider;

  // Profile feature settings
  bool _educationSectionEnabled = true;
  bool _certificatesSectionEnabled = true;

  // Other admin settings
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  bool _isLoading = false;
  String? _error;

  AdminSettingsProvider(this._authProvider) {
    _loadSettingsFromPrefs();
    // Load from backend if admin is authenticated
    if (_authProvider.isAuthenticated &&
        _authProvider.user?['role'] == 'admin') {
      loadSettingsFromBackend();
    }
  }

  // Getters
  bool get educationSectionEnabled => _educationSectionEnabled;
  bool get certificatesSectionEnabled => _certificatesSectionEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load settings from SharedPreferences
  Future<void> _loadSettingsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _educationSectionEnabled =
          prefs.getBool('education_section_enabled') ?? true;
      _certificatesSectionEnabled =
          prefs.getBool('certificates_section_enabled') ?? true;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
      notifyListeners();
    } catch (e) {
      log('Error loading admin settings: $e');
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettingsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
          'education_section_enabled', _educationSectionEnabled);
      await prefs.setBool(
          'certificates_section_enabled', _certificatesSectionEnabled);
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('dark_mode_enabled', _darkModeEnabled);
    } catch (e) {
      log('Error saving admin settings: $e');
    }
  }

  // Update education section setting
  Future<void> setEducationSectionEnabled(bool enabled) async {
    _educationSectionEnabled = enabled;
    await _saveSettingsToPrefs();
    await syncSettingsToBackend();
    notifyListeners();
  }

  // Update certificates section setting
  Future<void> setCertificatesSectionEnabled(bool enabled) async {
    _certificatesSectionEnabled = enabled;
    await _saveSettingsToPrefs();
    await syncSettingsToBackend();
    notifyListeners();
  }

  // Update notifications setting
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveSettingsToPrefs();
    await syncSettingsToBackend();
    notifyListeners();
  }

  // Update dark mode setting
  Future<void> setDarkModeEnabled(bool enabled) async {
    _darkModeEnabled = enabled;
    await _saveSettingsToPrefs();
    await syncSettingsToBackend();
    notifyListeners();
  }

  // Sync settings to backend
  Future<void> syncSettingsToBackend() async {
    if (!_authProvider.isAuthenticated ||
        _authProvider.user?['role'] != 'admin') {
      return;
    }

    try {
      final settings = {
        'educationSectionEnabled': _educationSectionEnabled,
        'certificatesSectionEnabled': _certificatesSectionEnabled,
        'notificationsEnabled': _notificationsEnabled,
        'darkModeEnabled': _darkModeEnabled,
      };

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/admin/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode(settings),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        log('Failed to sync settings: ${data['message']}');
      }
    } catch (e) {
      log('Error syncing settings to backend: $e');
    }
  }

  // Load settings from backend
  Future<void> loadSettingsFromBackend() async {
    if (!_authProvider.isAuthenticated ||
        _authProvider.user?['role'] != 'admin') {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _updateSettingsFromMap(data['settings']);
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Failed to load settings';
      }
    } catch (e) {
      _error = 'Failed to load settings: $e';
      log('Error loading settings from backend: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateSettingsFromMap(Map<String, dynamic> settings) {
    _educationSectionEnabled = settings['educationSectionEnabled'] ?? true;
    _certificatesSectionEnabled =
        settings['certificatesSectionEnabled'] ?? true;
    _notificationsEnabled = settings['notificationsEnabled'] ?? true;
    _darkModeEnabled = settings['darkModeEnabled'] ?? false;
    _saveSettingsToPrefs();
    notifyListeners();
  }
}
