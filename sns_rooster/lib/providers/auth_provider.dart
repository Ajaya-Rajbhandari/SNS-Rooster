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
  final bool useMock = true; // Explicitly set useMock to true

  bool get isAuthenticated => _token != null && !isTokenExpired();
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isLoggingOut => _isLoggingOut;
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  // API base URL
  final String _baseUrl =
      'http://192.168.1.71:5000/api'; // For Android emulator
  // Use 'http://localhost:5000/api' for iOS simulator

  String get baseUrl => _baseUrl; // Expose baseUrl as a getter

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

  Future<Map<String, dynamic>?> registerUser(String name, String email,
      String password, String role, String department, String position) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify listeners only for loading state change

    try {
      if (useMock) {
        final Map<String, dynamic>? response = await _mockAuthService
            .registerUser(name, email, password, role, department, position);
        // Do NOT modify _token, _user, or call _saveAuthToPrefs here for registration
        return response;
      } else {
        final response = await http.post(
          Uri.parse('$_baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': name,
            'email': email,
            'password': password,
            'role': role,
            'department': department,
            'position': position,
          }),
        );

        final data = json.decode(response.body);

        if (response.statusCode == 201) {
          // Do NOT modify _token, _user, or call _saveAuthToPrefs here for registration
          return {
            'success': true,
            'user': data['user'],
            'token': data['token']
          };
        } else {
          _error = data['message'] ?? 'Failed to register user';
          return {'success': false, 'message': _error};
        }
      }
    } catch (e) {
      _error = e.toString();
      return {'success': false, 'message': _error};
    } finally {
      _isLoading = false;
      // Removed notifyListeners() here to prevent main.dart from reacting to registration completion
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (useMock) {
        final response = await _mockAuthService.login(email, password);
        if (response != null) {
          _token = response["token"];
          _user = response["user"];
          await _saveAuthToPrefs();
          return true;
        }
        _error = "Invalid email or password";
        return false;
      } else {
        throw UnimplementedError("Real API call not implemented.");
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
        body: json.encode({
          'token': token,
          'newPassword': newPassword,
        }),
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
    if (_token == null) {
      return true;
    }
    try {
      final decodedToken = JwtDecoder.decode(_token!);
      final exp = decodedToken['exp'];
      if (exp == null) {
        return true; // Token has no expiration, consider it expired or invalid
      }
      final DateTime expirationDate =
          DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return expirationDate.isBefore(DateTime.now());
    } catch (e) {
      print('Error decoding token: $e');
      return true; // Invalid token
    }
  }

  Future<void> _saveAuthToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString('token', _token!);
      print('Token saved to SharedPreferences: $_token');
    } else {
      await prefs.remove('token');
      print('Token removed from SharedPreferences');
    }

    if (_user != null) {
      await prefs.setString('user', json.encode(_user));
      print('User saved to SharedPreferences: $_user');
    } else {
      await prefs.remove('user');
      print('User removed from SharedPreferences');
    }
  }

  Future<void> forceClearAuth() async {
    _token = null;
    _user = null;
    _error = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    print('Auth state forcibly cleared from SharedPreferences and memory.');
  }

  // Method to update user information from other providers (e.g., ProfileProvider)
  Future<void> updateUser(Map<String, dynamic> updatedUserData) async {
    _user = updatedUserData;
    await _saveAuthToPrefs(); // Save the updated user data
    notifyListeners();
  }
}
