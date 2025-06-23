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
  String? _authToken; // Nullable token
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

  // Getter for authToken
  String? get authToken => _authToken;

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
      print('LOAD_AUTH_DEBUG: Loading stored auth...');
      final prefs = await SharedPreferences.getInstance();

      final storedToken = prefs.getString('token');
      print('LOAD_AUTH_DEBUG: Token retrieved from SharedPreferences: $storedToken');
      _authToken = storedToken;

      final storedUser = prefs.getString('user');
      print('LOAD_AUTH_DEBUG: User data retrieved from SharedPreferences: $storedUser');
      _user = storedUser != null ? json.decode(storedUser) : null;

      _token = _authToken;
      print('LOAD_AUTH_DEBUG: Assigned _authToken to _token: $_token');

      print('LOAD_AUTH_DEBUG: Final _authToken: $_authToken, Final _user: $_user');
      print('LOAD_AUTH_DEBUG: Token after loading: $_authToken'); // Debugging log
      print('LOAD_AUTH_DEBUG: Token loaded from SharedPreferences: $_authToken'); // Debugging log
      notifyListeners();
    } catch (e) {
      print('LOAD_AUTH_DEBUG: Error loading stored auth: $e');
      _authToken = null;
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
    print('LOGIN_DEBUG: Starting login for email: $email');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('LOGIN_DEBUG: Making API call to [36m${ApiConfig.baseUrl}/auth/login[0m');

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

      print('LOGIN_DEBUG: Response status code: ${response.statusCode}');
      print('LOGIN_DEBUG: Response body: ${response.body}');

      final data = jsonDecode(response.body); // Define data here

      if (response.statusCode == 200) {
        _authToken = data['token'];
        _token = _authToken; // Assign to _token for consistency
        print('LOGIN_DEBUG: Token received: \\_authToken');
        print('LOGIN_DEBUG: Assigning token to _authToken: \\${data['token']}');
        _user = data['user'];
        print('LOGIN_DEBUG: User data received: \\_user');
        print('LOGIN_DEBUG: Backend token field: \\${data['token']}');
        print('LOGIN_DEBUG: Token received from backend response: \\_authToken');
        await _saveAuthToPrefs();
        // --- Ensure profile is refreshed after login ---
        if (_profileProvider != null) {
          print('LOGIN_DEBUG: Refreshing profile after login');
          await _profileProvider!.fetchProfile();
        } else {
          print('LOGIN_DEBUG: ProfileProvider is not set, cannot refresh profile');
        }
        // --- Wait for profile to be loaded before returning ---
        if (_profileProvider != null) {
          int tries = 0;
          while ((_profileProvider!.profile == null || _profileProvider!.isLoading) && tries < 20) {
            await Future.delayed(const Duration(milliseconds: 100));
            tries++;
          }
        }
        return true;
      } else {
        _error = data['message'] ?? 'Login failed';
        print('LOGIN_DEBUG: Login failed: $_error');
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('LOGIN_DEBUG: Exception during login: $e');
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

  bool isTokenExpired([String? token]) {
    final t = token ?? _token;
    if (t == null) {
      return true;
    }
    try {
      final decodedToken = JwtDecoder.decode(t);
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
    print('SAVE_AUTH_DEBUG: SharedPreferences instance obtained');

    if (_authToken != null) {
      print('SAVE_AUTH_DEBUG: Token before saving: $_authToken');
      await prefs.setString('token', _authToken!);
      print('SAVE_AUTH_DEBUG: Token saved to SharedPreferences: $_authToken');
    } else {
      await prefs.remove('token');
      print('SAVE_AUTH_DEBUG: Token removed from SharedPreferences');
    }

    if (_user != null) {
      await prefs.setString('user', json.encode(_user));
      print('SAVE_AUTH_DEBUG: User saved to SharedPreferences: $_user');
    } else {
      await prefs.remove('user');
      print('SAVE_AUTH_DEBUG: User removed from SharedPreferences');
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

  Future<void> clearToken() async {
    print('CLEAR_TOKEN_DEBUG: Clearing token from SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    _token = null;
    _user = null;
    print('CLEAR_TOKEN_DEBUG: Token and user data cleared');
    notifyListeners();
  }

  Future<void> forceRelogin(BuildContext context) async {
    print('FORCE_RELOGIN_DEBUG: Forcing re-login');
    clearToken();
    notifyListeners();
    Navigator.pushReplacementNamed(context, '/login');
    print('FORCE_RELOGIN_DEBUG: Navigated to login screen');
  }

  void debugToken(String? token) {
    if (token == null) {
      print('TOKEN_DEBUG: No token provided');
      return;
    }

    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      print('TOKEN_DEBUG: Decoded token payload: $decodedToken');
    } catch (e) {
      print('TOKEN_DEBUG: Error decoding token: $e');
    }
  }

  Future<void> fetchBreakTypes(BuildContext context) async {
    debugToken(_authToken);

    if (_authToken == null || isTokenExpired(_authToken!)) {
      print('TOKEN_EXPIRATION_CHECK_DEBUG: Token expired or null, forcing re-login');
      await forceRelogin(context);
      return;
    }

    // ...existing code for fetching break types...
  }
}
