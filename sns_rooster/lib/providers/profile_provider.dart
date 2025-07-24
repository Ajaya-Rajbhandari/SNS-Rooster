import 'dart:convert';
import 'dart:typed_data';
import 'package:sns_rooster/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';
import '../config/api_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  static const String _profileKey = 'user_profile';
  bool _disposed = false;
  DateTime? _lastUpdated;
  String? _avatarSignedUrl;
  String? get avatarSignedUrl => _avatarSignedUrl;

  ProfileProvider(this._authProvider) {
    log('ProfileProvider initialized');
    if (_authProvider.isAuthenticated) {
      _initializeProfile();
    }
  }

  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  DateTime? get lastUpdated => _lastUpdated;
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
      log('Error loading stored profile: \$e');
    }
  }

  Future<void> _fetchProfileInBackground() async {
    if (!_authProvider.isAuthenticated || _authProvider.token == null) {
      _error = 'User not authenticated';
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _updateProfileData(data['profile']); // Use 'profile' instead of 'user'

        // Fetch assigned location information
        await _fetchAssignedLocation();
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Failed to fetch profile';
      }
    } catch (e) {
      log('Error fetching profile: $e');
      _error = 'Network error occurred: ${e.toString()}';
    }
  }

  Future<void> _fetchAssignedLocation() async {
    if (!_authProvider.isAuthenticated || _authProvider.token == null) {
      return;
    }

    try {
      final userId = _authProvider.user?['_id'];
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/employees/me/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['assignedLocation'] != null) {
          _profile?['assignedLocation'] = data['assignedLocation'];
          _saveProfileToPrefs();
          if (_disposed) return;
          notifyListeners();
        }
      }
    } catch (e) {
      log('Error fetching assigned location: $e');
      // Don't set error for location fetch failure as it's not critical
    }
  }

  void _updateProfileData(Map<String, dynamic> newProfile) {
    _profile = newProfile;
    _error = null;
    _isInitialized = true;
    _lastUpdated = DateTime.now();

    _saveProfileToPrefs();
    fetchAvatarSignedUrl();
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> _saveProfileToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // log('SharedPreferences instance obtained');
      // log('Profile data to save: \$_profile');
      await prefs.setString(_profileKey, json.encode(_profile));
    } catch (e) {
      // log('Error saving profile to prefs: \$e');
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

  /// Public method to fetch and refresh the profile.
  /// This is an alias for refreshProfile for clarity in UI code.
  Future<void> fetchProfile() async {
    log('fetchProfile called');
    await refreshProfile();
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
          // log('Error decoding JSON response: \$e');
          // log('Raw response body: \${response.body}');
          _error = 'Unexpected response format';
          notifyListeners();
          return false;
        }
      } else {
        try {
          final data = json.decode(response.body);
          _error = data['message'] ?? 'Failed to update profile';
        } catch (e) {
          // log('Error decoding error response: \$e');
          // log('Raw response body: \${response.body}');
          _error = 'Unexpected response format';
        }
        notifyListeners();
        if (_disposed) return false;
        return false;
      }
    } catch (e) {
      _error = 'Network error occurred: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> updateProfilePicture(
      {String? imagePath, Uint8List? imageBytes, String? fileName}) async {
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
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('${ApiConfig.baseUrl}/auth/me'),
      );
      request.headers['Authorization'] = 'Bearer ${_authProvider.token}';
      if (kIsWeb) {
        if (imageBytes == null || fileName == null) {
          _error = 'No image selected';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        request.files.add(http.MultipartFile.fromBytes(
            'profilePicture', imageBytes,
            filename: fileName));
      } else {
        if (imagePath == null) {
          _error = 'No image selected';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        if (kIsWeb) throw UnsupportedError('fromPath is not supported on web');
        request.files.add(
            await http.MultipartFile.fromPath('profilePicture', imagePath));
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['profile'] != null &&
            data['profile'] is Map<String, dynamic>) {
          _updateProfileData(data['profile']);
          if (_disposed) return false;
          await _authProvider.updateUser(_profile!);
          return true;
        } else {
          _error = 'Unexpected response format: missing profile data';
          notifyListeners();
          return false;
        }
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Failed to update profile picture';
        notifyListeners();
        if (_disposed) return false;
        return false;
      }
    } catch (e) {
      _error = 'Network error occurred: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadDocument(
      {String? filePath,
      Uint8List? fileBytes,
      String? fileName,
      required String documentType}) async {
    _error = null;
    if (!_authProvider.isAuthenticated || _authProvider.token == null) {
      _error = 'User not authenticated';
      return false;
    }
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/auth/upload-document'),
      );
      request.headers['Authorization'] = 'Bearer ${_authProvider.token}';
      request.fields['documentType'] = documentType;
      if (kIsWeb) {
        if (fileBytes == null || fileName == null) {
          _error = 'No file selected';
          return false;
        }
        request.files.add(http.MultipartFile.fromBytes('file', fileBytes,
            filename: fileName));
      } else {
        if (filePath == null) {
          _error = 'No file selected';
          return false;
        }
        if (kIsWeb) throw UnsupportedError('fromPath is not supported on web');
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      }
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        await _fetchProfileInBackground();
        return true;
      } else {
        _error = 'Failed to upload document';
        return false;
      }
    } catch (e) {
      _error = 'An error occurred during upload';
      return false;
    }
  }

  Future<void> fetchAvatarSignedUrl() async {
    if (_profile == null || _authProvider.token == null) {
      _avatarSignedUrl = null;
      return;
    }
    try {
      final userId = _profile!["_id"];
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/avatar/$userId/signed-url'),
        headers: {
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _avatarSignedUrl = data['url'] as String?;
      } else {
        _avatarSignedUrl = null;
      }
    } catch (e) {
      _avatarSignedUrl = null;
    }
    if (_disposed) return;
    notifyListeners();
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
      // log('Error clearing profile: \$e');
    }
    if (_disposed) return;
    notifyListeners();
  }
}
