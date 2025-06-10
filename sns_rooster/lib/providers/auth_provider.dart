import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/mock_service.dart'; // Import the mock service
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;
  Timer? _logoutDebounce;
  bool _isLoggingOut = false;
  final _navigatorKey = GlobalKey<NavigatorState>();

  // Instantiate the mock service (with useMock = true) so that we can simulate API responses.
  final MockAuthService _mockAuthService = MockAuthService();

  bool get isAuthenticated => _token != null && !isTokenExpired();
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isLoggingOut => _isLoggingOut;
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  // API base URL
  final String _baseUrl =
      'http://192.168.1.72:5000/api'; // For Android emulator
  // Use 'http://localhost:5000/api' for iOS simulator

  AuthProvider() {
    print('AuthProvider initialized');
    _loadStoredAuth(); // Add this back to load stored auth on initialization
  }

  Future<void> initAuth() async {
    print('AuthProvider initAuth called.');
    // Force clear any existing auth state first
    await forceClearAuth();
    // Then try to load stored auth
    await _loadStoredAuth();
    await checkAuthStatus();
  }

  Future<void> _loadStoredAuth() async {
    try {
      print('Loading stored auth...');
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('token');
      print('SharedPreferences retrieved token: $storedToken');
      _token = storedToken;

      if (_token == null) {
        print('No token found in SharedPreferences after retrieval.');
        _user = null;
      } else {
        final userStr = prefs.getString('user');
        print('SharedPreferences retrieved user string: $userStr');
        if (userStr != null) {
          _user = json.decode(userStr);
          print('User data loaded: $_user');
        } else {
          _user = null;
        }
      }
      print(
          'Stored auth loaded - Final _token: ${_token != null}, Final User: ${_user != null}');
      notifyListeners();
    } catch (e) {
      print('Error loading stored auth: $e');
      _token = null;
      _user = null;
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    print('AUTH_CHECK: ===== STARTING AUTH CHECK =====');
    print(
        'AUTH_CHECK: Current state - isAuthenticated: $isAuthenticated, token exists: ${_token != null}, user exists: ${_user != null}');

    if (_token == null) {
      print('AUTH_CHECK: No token found, clearing user and returning');
      _user = null;
      notifyListeners();
      return;
    }

    if (isTokenExpired()) {
      print('AUTH_CHECK: Token is expired, logging out');
      await logout();
      return;
    }

    try {
      print('AUTH_CHECK: Verifying token with server...');
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      print('AUTH_CHECK: Server response status: ${response.statusCode}');
      print('AUTH_CHECK: Server response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = data['user'];
        print('AUTH_CHECK: Token verified - User role: ${_user?['role']}');
        notifyListeners();
      } else {
        print('AUTH_CHECK: Token verification failed, logging out');
        await logout();
      }
    } catch (e) {
      print('AUTH_CHECK: Error verifying token: $e');
      print('AUTH_CHECK: Logging out due to error');
      await logout();
    }
    print('AUTH_CHECK: ===== AUTH CHECK COMPLETED =====');
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // If useMock (in mock_service.dart) is true, call the mock service; otherwise, call the real API.
      if (useMock) {
        final response = await _mockAuthService.login(email, password);
        _token = response["token"];
        _user = response["user"];
        await _saveAuthToPrefs(); // Save updated user info after login
      } else {
        // TODO: Replace with real API call (e.g., POST /api/auth/login) using http or dio.
        // For example:
        // final response = await http.post(Uri.parse("http://yourbackend.com/api/auth/login"), body: json.encode({ "email": email, "password": password }));
        // if (response.statusCode == 200) { final data = json.decode(response.body); _token = data["token"]; _user = data["user"]; } else { _error = "Invalid email or password"; }
        throw UnimplementedError("Real API call not implemented.");
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return (_token != null);
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (useMock) {
        final success = await _mockAuthService.sendPasswordResetEmail(email);
        return success;
      } else {
        // TODO: Replace with real API call (e.g., POST $_baseUrl/auth/forgot-password).
        // Example:
        // final response = await http.post(
        //   Uri.parse('$_baseUrl/auth/forgot-password'),
        //   headers: {'Content-Type': 'application/json'},
        //   body: json.encode({'email': email}),
        // );
        // if (response.statusCode == 200) {
        //   return true;
        // } else {
        //   final data = json.decode(response.body);
        //   _error = data['message'] ?? 'Failed to send password reset email';
        //   return false;
        // }
        throw UnimplementedError(
            "Real API call for password reset not implemented.");
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    print('Logging out...');
    _token = null;
    _user = null;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');

      // Clear profile data
      final profileProvider = Provider.of<ProfileProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      await profileProvider.clearProfile();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  void reset() {
    _token = null;
    _user = null;
    _error = null;
    _saveAuthToPrefs(); // Clear stored info on reset
    notifyListeners(); // Notify listeners for immediate UI update
  }

  Future<void> requestPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/request-reset'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final data = json.decode(response.body);

      if (response.statusCode != 200) {
        _error = data['message'] ?? 'Failed to request password reset';
      }
    } catch (e) {
      _error = 'Network error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'password': newPassword}),
      );

      final data = json.decode(response.body);

      if (response.statusCode != 200) {
        _error = data['message'] ?? 'Failed to reset password';
      }
    } catch (e) {
      _error = 'Network error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isTokenExpired() {
    if (_token == null) return true;
    final isExpired = JwtDecoder.isExpired(_token!);
    print('Token expired check: $isExpired');
    return isExpired;
  }

  Future<bool> registerUser(
    String name,
    String email,
    String password,
    String role,
    String department,
    String position,
  ) async {
    print('Registering user: $email');
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('Current Token: $_token');
    print('Is Authenticated: $isAuthenticated');
    try {
      print('Sending register request to: $_baseUrl/auth/register');
      print('Authorization Token: Bearer $_token');
      final requestBody = json.encode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'department': department,
        'position': position,
      });
      print('Request Body: $requestBody');
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token'
        },
        body: requestBody,
      );

      final data = json.decode(response.body);
      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      if (response.statusCode == 201) {
        // 201 Created for successful registration
        _error = null;
        return true;
      } else {
        _error = data['message'] ?? 'Registration failed';
        return false;
      }
    } catch (e) {
      print('Registration error: $e');
      _error = 'Network error occurred: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> forceClearAuth() async {
    print('FORCE_CLEAR: ===== FORCE CLEARING AUTH STATE =====');

    // Clear in-memory state
    _token = null;
    _user = null;
    _error = null;
    notifyListeners();
    print('FORCE_CLEAR: In-memory state cleared');

    // Clear persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      await prefs.clear();

      // Verify clear
      final verifyToken = prefs.getString('token');
      final verifyUser = prefs.getString('user');
      print(
          'FORCE_CLEAR: Storage verification - token exists: ${verifyToken != null}, user exists: ${verifyUser != null}');
    } catch (e) {
      print('FORCE_CLEAR: Error clearing storage: $e');
    }

    print('FORCE_CLEAR: ===== AUTH STATE CLEARED =====');
  }

  // Method to update user information from other providers (e.g., ProfileProvider)
  Future<void> updateUser(Map<String, dynamic> updatedUserData) async {
    _user = updatedUserData;
    await _saveAuthToPrefs(); // Save the updated user data
    notifyListeners();
  }

  // Helper to save token and user to SharedPreferences
  Future<void> _saveAuthToPrefs() async {
    try {
      print('Saving auth to preferences...');
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString('token', _token!);
        print('Token saved to preferences');
      } else {
        await prefs.remove('token');
        print('Token removed from preferences');
      }

      if (_user != null) {
        await prefs.setString('user', json.encode(_user));
        print('User data saved to preferences');
      } else {
        await prefs.remove('user');
        print('User data removed from preferences');
      }
      print('Auth data saved to preferences');
    } catch (e) {
      print('Error saving auth to preferences: $e');
    }
  }
}
