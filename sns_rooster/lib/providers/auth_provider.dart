import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../providers/profile_provider.dart';
import '../config/api_config.dart';
import '../main.dart'; // Import main.dart to access MyApp class
import '../providers/attendance_provider.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;
  final bool _isLoggingOut = false;
  final _navigatorKey = GlobalKey<NavigatorState>();

  // Test credentials for developer convenience
  static const String devEmployeeEmail = 'employee2@snsrooster.com';
  static const String devEmployeePassword = 'Employee@456';
  static const String devAdminEmail = 'admin@snsrooster.com';
  static const String devAdminPassword = 'Admin@123';

  bool get isAuthenticated => _token != null && !isTokenExpired();
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isLoggingOut => _isLoggingOut;
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  AuthProvider() {
    print('AUTH PROVIDER: Initialized');
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
    print('AUTH_CHECK: Starting authentication status check...');
    print('AUTH_CHECK: Current state - isAuthenticated: $isAuthenticated, token exists: ${_token != null}, user exists: ${_user != null}');

    if (_token == null) {
      print('AUTH_CHECK: No token found, clearing user and returning.');
      _user = null;
      notifyListeners();
      return;
    }

    if (isTokenExpired()) {
      print('AUTH_CHECK: Token is expired, logging out.');
      await logout();
      return;
    }

    try {
      print('AUTH_CHECK: Verifying token with server...');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      print('AUTH_CHECK: Server response status: ${response.statusCode}');
      print('AUTH_CHECK: Server response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = data['user'];
        print('AUTH_CHECK: Token verified - User role: ${_user?['role']}');
        notifyListeners();
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Token verification failed';
        print('AUTH_CHECK: $errorMessage');
        await logout();
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('AUTH_CHECK: Error verifying token: $e');
      await logout();
      _error = 'Authentication failed: $e';
      notifyListeners();
    }

    print('AUTH_CHECK: Authentication status check completed.');
  }

  Future<Map<String, dynamic>?> registerUser(String name, String email,
      String password, String role, String department, String position) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify listeners only for loading state change

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'department': department,
          'position': position,
        }),
      );

      final data = jsonDecode(response.body);

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
    } catch (e) {
      _error = e.toString();
      return {'success': false, 'message': _error};
    } finally {
      _isLoading = false;
      // Removed notifyListeners() here to prevent main.dart from reacting to registration completion
    }
  }

  Future<bool> login(String email, String password) async {
    print('AUTH PROVIDER: Login called with email: $email');
    print('LOGIN_DEBUG: Starting login for email: $email');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('LOGIN_DEBUG: Making real API call to: ${ApiConfig.baseUrl}/auth/login');
      print('LOGIN_DEBUG: Sending request with email: $email');
      print('LOGIN_DEBUG: Request body: ${jsonEncode({'email': email, 'password': password})}');

      // Real API call implementation
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('LOGIN_DEBUG: Response status: ${response.statusCode}');
      print('LOGIN_DEBUG: Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _user = data['user'];
        print('LOGIN_DEBUG: Token received: $_token');
        print('LOGIN_DEBUG: User data received: $_user');
        await _saveAuthToPrefs();
        print('LOGIN_DEBUG: Real API login successful');
        return true;
      } else {
        _error = data['message'] ?? 'Login failed';
        print('LOGIN_DEBUG: Real API login failed: $_error');
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('LOGIN_DEBUG: Login exception: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
      print('LOGIN_DEBUG: Login completed, error: $_error');
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
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
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ProfileProvider? _profileProvider;

  void setProfileProvider(ProfileProvider profileProvider) {
    _profileProvider = profileProvider;
  }

  AttendanceProvider? _attendanceProvider;

  void setAttendanceProvider(AttendanceProvider attendanceProvider) {
    _attendanceProvider = attendanceProvider;
  }

  Future<void> logout() async {
    print('AUTH PROVIDER: Logout called');
    print('Logging out...');
    _token = null;
    _user = null;
    _error = null;
    notifyListeners();

    print('DEBUG: Starting logout process');
    print('DEBUG: Current token: \$_token');
    print('DEBUG: Current user: \$_user');

    try {
      final prefs = await SharedPreferences.getInstance();
      print('DEBUG: Clearing SharedPreferences');
      await prefs.remove('token');
      await prefs.remove('user');

      if (_profileProvider != null) {
        print('DEBUG: Clearing profile via ProfileProvider');
        await _profileProvider!.clearProfile();
      } else {
        print('DEBUG: ProfileProvider is not set');
      }
      if (_attendanceProvider != null) {
        print('DEBUG: Clearing attendance via AttendanceProvider');
        // _attendanceProvider!.clearAttendance();
      } else {
        print('DEBUG: AttendanceProvider is not set');
      }

      print('DEBUG: Logout process completed');
    } catch (e) {
      print('ERROR: Exception during logout: \$e');
    }

    // Navigate to login screen after logout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentContext != null) {
        Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
        print('DEBUG: Navigated to login screen');
      } else {
        print('ERROR: navigatorKey.currentContext is null, unable to navigate');
        // Fallback: Restart the app or log the error
        print('FALLBACK: Restarting app due to navigation failure');
        runApp(const MyApp());
      }
    });
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
        Uri.parse('${ApiConfig.baseUrl}/auth/request-reset'),
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
        Uri.parse('${ApiConfig.baseUrl}/auth/reset-password'),
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
    print('FORCE_CLEAR_AUTH: Clearing authentication state...');
    _token = null;
    _user = null;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      print('FORCE_CLEAR_AUTH: SharedPreferences cleared successfully.');
    } catch (e) {
      print('FORCE_CLEAR_AUTH: Error clearing SharedPreferences: $e');
    }

    print('FORCE_CLEAR_AUTH: Authentication state cleared.');
  }

  // Method to update user information from other providers (e.g., ProfileProvider)
  Future<void> updateUser(Map<String, dynamic> updatedUserData) async {
    _user = updatedUserData;
    await _saveAuthToPrefs(); // Save the updated user data
    notifyListeners();
  }
}
