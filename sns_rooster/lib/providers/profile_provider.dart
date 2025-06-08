import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import '../services/mock_service.dart'; // Import the mock service

class ProfileProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _error;

  // Instantiate the mock service
  final MockEmployeeService _mockEmployeeService = MockEmployeeService();

  // API base URL
  final String _baseUrl = 'http://10.0.2.2:5000/api'; // For Android emulator
  // Use 'http://localhost:5000/api' for iOS simulator

  ProfileProvider(this._authProvider);

  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProfile() async {
    print("fetchProfile called");
    _isLoading = true;
    _error = null;
    notifyListeners();
    if (!_authProvider.isAuthenticated || _authProvider.token == null) {
      _error = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      print("Not authenticated");
      return;
    }
    try {
      // Use mock service if useMock is true
      if (useMock) {
        final response = await _mockEmployeeService.getProfile();
        _profile = response['user'];
      } else {
        final response = await http.get(
          Uri.parse('$_baseUrl/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_authProvider.token}',
          },
        );
        print("Profile response: ${response.statusCode} ${response.body}");
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _profile = data['user'];
          _error = null;
        } else {
          final data = json.decode(response.body);
          _error = data['message'] ?? 'Failed to fetch profile';
        }
      }
    } catch (e) {
      _error = 'Network error occurred: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
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
        _profile = response['user'];
        _error = null;
        print(
            'Debug: ProfileProvider _profile after update (from updateProfile): $_profile');
        notifyListeners();
        return true;
      } else {
        final response = await http.patch(
          Uri.parse('$_baseUrl/users/profile'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_authProvider.token}',
          },
          body: json.encode(updates),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _profile = data['profile'];
          _error = null;
          notifyListeners();
          return true;
        } else {
          final data = json.decode(response.body);
          _error = data['message'] ?? 'Failed to update profile';
          notifyListeners();
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
    notifyListeners();

    if (!_authProvider.isAuthenticated || _authProvider.token == null) {
      _error = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      if (useMock) {
        // For mock, we directly update the avatar field in the mock user profile.
        final response = await _mockEmployeeService.updateProfile({
          'avatar': imagePath,
        });
        _profile = response['user'];
        _error = null;
        print('Debug: ProfileProvider _profile after update: $_profile');
        notifyListeners();
        return true;
      } else {
        // Real API call for updating profile picture
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/users/profile/picture'),
        );

        // Add authorization header
        request.headers['Authorization'] = 'Bearer ${_authProvider.token}';

        // Add file to request
        request.files.add(await http.MultipartFile.fromPath(
          'profilePicture',
          imagePath,
        ));

        // Send request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _profile = data['profile'];
          _error = null;
          notifyListeners();
          return true;
        } else {
          final data = json.decode(response.body);
          _error = data['message'] ?? 'Failed to update profile picture';
          notifyListeners();
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
}
