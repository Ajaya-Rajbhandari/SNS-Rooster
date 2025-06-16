import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';
import '../services/mock_service.dart'; // Import the mock service
import '../config/api_config.dart';

class ProfileProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  static const String _profileKey = 'user_profile';
  bool _disposed = false;

  // Instantiate the mock service
  final MockEmployeeService _mockEmployeeService = MockEmployeeService();

  ProfileProvider(this._authProvider) {
    print('ProfileProvider initialized');
    if (_authProvider.isAuthenticated) {
      _initializeProfile();
    }
  }

  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  Future<void> _initializeProfile() async {
    // First, try to load cached data immediately
    await _loadStoredProfile();

    // Then fetch fresh data in the background
    _fetchProfileInBackground();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadStoredProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedProfile = prefs.getString(_profileKey);
      if (storedProfile != null) {
        _profile = json.decode(storedProfile);
        _isInitialized = true;
        if (_disposed) return;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading stored profile: \$e');
    }
  }

  Future<void> _fetchProfileInBackground() async {
    if (!_authProvider.isAuthenticated || _authProvider.token == null) {
      _error = 'User not authenticated';
      return;
    }

    try {
      if (useMock) {
        final response = await _mockEmployeeService.getProfile();
        _updateProfileData(response['user']);
      } else {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/auth/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_authProvider.token}',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _updateProfileData(data['user']);
        } else {
          final data = json.decode(response.body);
          _error = data['message'] ?? 'Failed to fetch profile';
        }
      }
    } catch (e) {
      print('Error fetching profile: $e');
      _error = 'Network error occurred: ${e.toString()}';
    }
  }

  void _updateProfileData(Map<String, dynamic> newProfile) {
    _profile = newProfile;
    _error = null;
    _isInitialized = true;
    _saveProfileToPrefs();
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> _saveProfileToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // print('SharedPreferences instance obtained');
      // print('Profile data to save: \$_profile');
      await prefs.setString(_profileKey, json.encode(_profile));
    } catch (e) {
      // print('Error saving profile to prefs: \$e');
    }
  }

  // Public method to force refresh profile data
  Future<void> refreshProfile() async {
    _isLoading = true;
    if (_disposed) return;
    notifyListeners();

    try {
      await _fetchProfileInBackground();
    } finally {
      _isLoading = false;
      if (_disposed) return;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _error = null;
    if (_disposed) return false;
    notifyListeners();

    if (!_authProvider.isAuthenticated || _authProvider.token == null) {
      _error = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      if (useMock) {
        final response = await _mockEmployeeService.updateProfile(updates);
        _updateProfileData(response['user']);
        if (_disposed) return false;
        // Update AuthProvider's user data for consistency
        await _authProvider.updateUser(_profile!);
        return true;
      } else {
        final response = await http.patch(
          Uri.parse('${ApiConfig.baseUrl}/auth/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_authProvider.token}',
          },
          body: json.encode(updates),
        );

        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);
            _updateProfileData(data['profile']);
            if (_disposed) return false;
            await _authProvider.updateUser(_profile!);
            return true;
          } catch (e) {
            // print('Error decoding JSON response: \$e');
            // print('Raw response body: \${response.body}');
            _error = 'Unexpected response format';
            notifyListeners();
            return false;
          }
        } else {
          try {
            final data = json.decode(response.body);
            _error = data['message'] ?? 'Failed to update profile';
          } catch (e) {
            // print('Error decoding error response: \$e');
            // print('Raw response body: \${response.body}');
            _error = 'Unexpected response format';
          }
          notifyListeners();
          if (_disposed) return false;
          return false;
        }
      }
    } catch (e) {
      _error = 'Network error occurred: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> updateProfilePicture(String imagePath) async {
    _isLoading = true;
    _error = null;
    if (_disposed) return false;
    notifyListeners();

    if (!_authProvider.isAuthenticated || _authProvider.token == null) {
      _error = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      if (useMock) {
        final response = await _mockEmployeeService.updateProfile({
          'avatar': imagePath,
        });
        _updateProfileData(response['user']);
        if (_disposed) return false;
        // Update AuthProvider's user data for consistency
        await _authProvider.updateUser(_profile!);
        return true;
      } else {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}/users/profile/picture'),
        );

        request.headers['Authorization'] = 'Bearer ${_authProvider.token}';
        request.files.add(await http.MultipartFile.fromPath(
          'profilePicture',
          imagePath,
        ));

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _updateProfileData(data['profile']);
          if (_disposed) return false;
          // Update AuthProvider's user data for consistency
          await _authProvider.updateUser(_profile!);
          return true;
        } else {
          final data = json.decode(response.body);
          _error = data['message'] ?? 'Failed to update profile picture';
          notifyListeners();
          if (_disposed) return false;
          return false;
        }
      }
    } catch (e) {
      _error = 'Network error occurred: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  // Clear profile data when logging out
  Future<void> clearProfile() async {
    _profile = null;
    _error = null;
    _isInitialized = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
    } catch (e) {
      // print('Error clearing profile: \$e');
    }
    if (_disposed) return;
    notifyListeners();
  }
}
