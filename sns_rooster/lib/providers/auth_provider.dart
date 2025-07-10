import 'dart:async';
import 'package:sns_rooster/utils/logger.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../providers/profile_provider.dart';
import '../config/api_config.dart';
// Import main.dart to access MyApp class
import '../providers/attendance_provider.dart';
import '../services/fcm_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _authToken; // Nullable token
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;
  final bool _isLoggingOut = false;
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _rememberMe = false;

  // Test credentials for developer convenience
  static const String devEmployeeEmail = 'employee2@snsrooster.com';
  static const String devEmployeePassword = 'Employee@456';
  static const String devAdminEmail = 'admin@snsrooster.com';
  static const String devAdminPassword = 'Admin@123';

  // Add new keys for storing credentials
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  bool get isAuthenticated => _token != null && !isTokenExpired();
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  bool get isLoggingOut => _isLoggingOut;
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  // Getter for authToken
  String? get authToken => _authToken;

  // Add fields for saved credentials
  String? _savedEmail;
  String? _savedPassword;
  String? get savedEmail => _savedEmail;
  String? get savedPassword => _savedPassword;

  // Add a public getter for rememberMe
  bool get rememberMe => _rememberMe;

  AuthProvider() {
    log('AUTH PROVIDER: Initialized');
    _loadStoredAuth(); // Add this back to load stored auth on initialization
  }

  Future<void> initAuth() async {
    log('AuthProvider initAuth called.');
    // Force clear any existing auth state first
    await forceClearAuth();
    // Then try to load stored auth
    await _loadStoredAuth();
    await checkAuthStatus();
  }

  Future<void> _loadStoredAuth() async {
    try {
      log('LOAD_AUTH_DEBUG: Loading stored auth...');
      final prefs = await SharedPreferences.getInstance();

      final storedToken = prefs.getString('token');
      log('LOAD_AUTH_DEBUG: Token retrieved from SharedPreferences: $storedToken');
      _authToken = storedToken;

      final storedUser = prefs.getString('user');
      log('LOAD_AUTH_DEBUG: User data retrieved from SharedPreferences: $storedUser');
      _user = storedUser != null ? json.decode(storedUser) : null;

      _token = _authToken;
      log('LOAD_AUTH_DEBUG: Assigned _authToken to _token: $_token');

      // Load Remember Me and credentials
      _rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      if (_rememberMe) {
        _savedEmail = prefs.getString(_savedEmailKey);
        _savedPassword = prefs.getString(_savedPasswordKey);
      } else {
        _savedEmail = null;
        _savedPassword = null;
      }

      log('LOAD_AUTH_DEBUG: Final _authToken: $_authToken, Final _user: $_user');
      log('LOAD_AUTH_DEBUG: Token after loading: $_authToken'); // Debugging log
      log('LOAD_AUTH_DEBUG: Token loaded from SharedPreferences: $_authToken'); // Debugging log
      notifyListeners();
    } catch (e) {
      log('LOAD_AUTH_DEBUG: Error loading stored auth: $e');
      _authToken = null;
      _user = null;
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    log('AUTH_CHECK: Starting authentication status check...');
    log('AUTH_CHECK: Current state - isAuthenticated: $isAuthenticated, token exists: ${_token != null}, user exists: ${_user != null}');

    if (_token == null) {
      log('AUTH_CHECK: No token found, clearing user and returning.');
      _user = null;
      notifyListeners();
      return;
    }

    if (isTokenExpired()) {
      log('AUTH_CHECK: Token is expired, logging out.');
      await logout();
      return;
    }

    try {
      log('AUTH_CHECK: Verifying token with server...');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      log('AUTH_CHECK: Server response status: ${response.statusCode}');
      log('AUTH_CHECK: Server response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = data['user'];
        log('AUTH_CHECK: Token verified - User role: ${_user?['role']}');
        notifyListeners();
      } else {
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Token verification failed';
        log('AUTH_CHECK: $errorMessage');
        await logout();
        throw Exception(errorMessage);
      }
    } catch (e) {
      log('AUTH_CHECK: Error verifying token: $e');
      await logout();
      _error = 'Authentication failed: $e';
      notifyListeners();
    }

    log('AUTH_CHECK: Authentication status check completed.');
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
        return {'success': true, 'user': data['user'], 'token': data['token']};
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
    log('LOGIN_DEBUG: Starting login for email: $email');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      log('LOGIN_DEBUG: Making API call to  ${ApiConfig.baseUrl}/auth/login');

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

      log('LOGIN_DEBUG: Response status code: ${response.statusCode}');
      log('LOGIN_DEBUG: Response body: ${response.body}');

      final data = jsonDecode(response.body); // Define data here

      if (response.statusCode == 200) {
        _authToken = data['token'];
        _token = _authToken; // Assign to _token for consistency
        log('LOGIN_DEBUG: Token received: _authToken');
        _user = data['user'];
        log('LOGIN_DEBUG: User data received: _user');
        log('LOGIN_DEBUG: Backend token field: ${data['token']}');
        log('LOGIN_DEBUG: Token received from backend response: _authToken');

        // Always save auth token and user data to SharedPreferences
        await _saveAuthToPrefs();

        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setBool(_rememberMeKey, true);
          await prefs.setString(_savedEmailKey, email);
          await prefs.setString(_savedPasswordKey, password);
        } else {
          // Do NOT clear in-memory state; just avoid saving credentials
          await prefs.setBool(_rememberMeKey, false);
          await prefs.remove(_savedEmailKey);
          await prefs.remove(_savedPasswordKey);
        }
        // --- Ensure profile is refreshed after login ---
        if (_profileProvider != null) {
          log('LOGIN_DEBUG: Refreshing profile after login');
          await _profileProvider?.fetchProfile();
          int tries = 0;
          while (((_profileProvider?.profile == null ||
                  _profileProvider?.isLoading == true)) &&
              tries < 20) {
            await Future.delayed(const Duration(milliseconds: 100));
            tries++;
          }
        } else {
          log('LOGIN_DEBUG: ProfileProvider is not set, cannot refresh profile');
        }
        // --- Send FCM token to backend after login ---
        try {
          final fcmToken = FCMService().fcmToken ??
              await FCMService()
                  .initialize()
                  .then((_) => FCMService().fcmToken);
          if (fcmToken != null) {
            final fcmResponse = await http.post(
              Uri.parse('${ApiConfig.baseUrl}/fcm-token'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_token',
              },
              body: jsonEncode({
                'fcmToken': fcmToken,
                'platform': 'android',
                'appVersion': '1.0.0',
                'deviceModel': 'flutter-app',
              }),
            );
            print(
                'FCM: Token registration ${fcmResponse.statusCode == 200 ? "✅ SUCCESS" : "❌ FAILED"} (${fcmResponse.statusCode})');
          } else {
            print('FCM: ❌ No token available');
          }
        } catch (e) {
          print('FCM: ❌ Registration failed: $e');
        }
        return true;
      } else {
        _error = data['message'] ?? 'Login failed';
        log('LOGIN_DEBUG: Login failed: $_error');
        return false;
      }
    } catch (e) {
      _error = e.toString();
      log('LOGIN_DEBUG: Exception during login: $e');
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['message'] ?? 'Failed to send password reset email';
        return false;
      }
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
    log('AUTH PROVIDER: Logout called');
    log('Logging out...');
    _token = null;
    _user = null;
    _error = null;
    notifyListeners();

    log('DEBUG: Starting logout process');
    log('DEBUG: Current token: $_token');
    log('DEBUG: Current user: $_user');

    try {
      final prefs = await SharedPreferences.getInstance();
      log('DEBUG: Clearing SharedPreferences');
      await prefs.remove('token');
      await prefs.remove('user');
      if (!_rememberMe) {
        await prefs.setBool(_rememberMeKey, false);
        await prefs.remove(_savedEmailKey);
        await prefs.remove(_savedPasswordKey);
      }

      if (_profileProvider != null) {
        log('DEBUG: Clearing profile via ProfileProvider');
        await _profileProvider?.clearProfile();
      } else {
        log('DEBUG: ProfileProvider is not set');
      }
      if (_attendanceProvider != null) {
        log('DEBUG: Clearing attendance via AttendanceProvider');
        // _attendanceProvider!.clearAttendance();
      } else {
        log('DEBUG: AttendanceProvider is not set');
      }

      log('DEBUG: Logout process completed');
    } catch (e) {
      log('ERROR: Exception during logout: $e');
    }

    // Navigate to login screen after logout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentContext != null) {
        Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
        log('DEBUG: Navigated to login screen');
      } else {
        log('ERROR: navigatorKey.currentContext is null, unable to navigate');
        // Fallback: Log the error, do not restart the app
      }
    });

    await _clearAuthFromPrefs();
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
      log('Error decoding token: $e');
      return true; // Invalid token
    }
  }

  Future<void> _saveAuthToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    log('SAVE_AUTH_DEBUG: SharedPreferences instance obtained');

    if (_authToken != null) {
      log('SAVE_AUTH_DEBUG: Token before saving: $_authToken');
      await prefs.setString('token', _authToken!);
      log('SAVE_AUTH_DEBUG: Token saved to SharedPreferences: $_authToken');
    } else {
      await prefs.remove('token');
      log('SAVE_AUTH_DEBUG: Token removed from SharedPreferences');
    }

    if (_user != null) {
      await prefs.setString('user', json.encode(_user));
      log('SAVE_AUTH_DEBUG: User saved to SharedPreferences: $_user');
    } else {
      await prefs.remove('user');
      log('SAVE_AUTH_DEBUG: User removed from SharedPreferences');
    }

    // Save FCM token to backend if user is authenticated
    if (_authToken != null && _user != null) {
      await _saveFCMTokenToBackend();
    }
  }

  Future<void> _clearAuthFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    log('CLEAR_AUTH_DEBUG: Clearing authentication state from SharedPreferences');
    await prefs.remove('token');
    await prefs.remove('user');
    _token = null;
    _user = null;
    log('CLEAR_AUTH_DEBUG: Authentication state cleared from SharedPreferences');
    notifyListeners();
  }

  Future<void> forceClearAuth() async {
    log('FORCE_CLEAR_AUTH: Clearing authentication state...');
    _token = null;
    _user = null;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      log('FORCE_CLEAR_AUTH: SharedPreferences cleared successfully.');
    } catch (e) {
      log('FORCE_CLEAR_AUTH: Error clearing SharedPreferences: $e');
    }

    log('FORCE_CLEAR_AUTH: Authentication state cleared.');
  }

  // Method to update user information from other providers (e.g., ProfileProvider)
  Future<void> updateUser(Map<String, dynamic> updatedUserData) async {
    _user = updatedUserData;
    await _saveAuthToPrefs(); // Save the updated user data
    notifyListeners();
  }

  Future<void> clearToken() async {
    log('CLEAR_TOKEN_DEBUG: Clearing token from SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    _token = null;
    _user = null;
    log('CLEAR_TOKEN_DEBUG: Token and user data cleared');
    notifyListeners();
  }

  Future<void> forceRelogin(BuildContext context) async {
    log('FORCE_RELOGIN_DEBUG: Forcing re-login');
    clearToken();
    notifyListeners();
    Navigator.pushReplacementNamed(context, '/login');
    log('FORCE_RELOGIN_DEBUG: Navigated to login screen');
  }

  void debugToken(String? token) {
    if (token == null) {
      log('TOKEN_DEBUG: No token provided');
      return;
    }

    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      log('TOKEN_DEBUG: Decoded token payload: $decodedToken');
    } catch (e) {
      log('TOKEN_DEBUG: Error decoding token: $e');
    }
  }

  Future<void> fetchBreakTypes(BuildContext context) async {
    debugToken(_authToken);

    if (_authToken == null || isTokenExpired(_authToken!)) {
      log('TOKEN_EXPIRATION_CHECK_DEBUG: Token expired or null, forcing re-login');
      await forceRelogin(context);
      return;
    }

    // ...existing code for fetching break types...
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(updates),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        _user = data['profile'] ?? _user;
        await _saveAuthToPrefs();
        notifyListeners();
        return {'success': true, 'user': _user};
      } else {
        _error = data['message'] ?? 'Failed to update profile';
        return {'success': false, 'message': _error};
      }
    } catch (e) {
      _error = e.toString();
      return {'success': false, 'message': _error};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'password': newPassword,
          'currentPassword': currentPassword,
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        _error = data['message'] ?? 'Failed to change password';
        return {'success': false, 'message': _error};
      }
    } catch (e) {
      _error = e.toString();
      return {'success': false, 'message': _error};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add methods to save and clear credentials
  Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, true);
    await prefs.setString(_savedEmailKey, email);
    await prefs.setString(_savedPasswordKey, password);
    _savedEmail = email;
    _savedPassword = password;
    _rememberMe = true;
    notifyListeners();
  }

  Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, false);
    await prefs.remove(_savedEmailKey);
    await prefs.remove(_savedPasswordKey);
    _savedEmail = null;
    _savedPassword = null;
    _rememberMe = false;
    notifyListeners();
  }

  // Save FCM token to backend
  Future<void> _saveFCMTokenToBackend() async {
    try {
      final fcmToken = FCMService().fcmToken;
      if (fcmToken == null) {
        print('FCM: ❌ No token available');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({
          'fcmToken': fcmToken,
          'userId': _user?['_id'],
        }),
      );

      if (response.statusCode == 200) {
        print('FCM: ✅ Token saved to backend');
        // Subscribe to role-based topics
        if (_user?['role'] != null) {
          await FCMService().subscribeToRoleTopics(_user!['role']);
        }
      } else {
        print('FCM: ❌ Save failed (${response.statusCode})');
      }
    } catch (e) {
      print('FCM: ❌ Save error: $e');
    }
  }
}
