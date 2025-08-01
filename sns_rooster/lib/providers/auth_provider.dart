import 'dart:async';
import 'package:sns_rooster/utils/logger.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../providers/profile_provider.dart';
import '../config/api_config.dart';
import '../services/secure_storage_service.dart';
import '../services/auth_migration_service.dart';
// Import main.dart to access MyApp class
import '../providers/attendance_provider.dart';
import '../providers/company_provider.dart';
import '../services/fcm_service.dart';
import '../providers/company_settings_provider.dart';
import '../providers/feature_provider.dart';
import '../services/cache_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _authToken; // Nullable token
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;
  final bool _isLoggingOut = false;
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _rememberMe = false;
  bool _scheduleFeatureLoading = false; // Add this variable

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
      // Try to load from secure storage first
      final storedToken = await SecureStorageService.getAuthToken();
      _authToken = storedToken;

      final storedUserData = await SecureStorageService.getUserData();
      _user = storedUserData != null ? json.decode(storedUserData) : null;

      _token = _authToken;

      // Load features if user is authenticated
      if (_token != null && !isTokenExpired() && _featureProvider != null) {
        try {
          await _featureProvider!.loadFeatures();
        } catch (e) {
          log('AuthProvider: Error loading features: $e');
        }
      }

      // Load Remember Me and credentials from secure storage
      final rememberedCreds =
          await SecureStorageService.getRememberedCredentials();
      _rememberMe = rememberedCreds['remember_me'] == 'true';
      if (_rememberMe) {
        _savedEmail = rememberedCreds['email'];
        _savedPassword = rememberedCreds['password'];
      } else {
        _savedEmail = null;
        _savedPassword = null;
      }

      // Migration from SharedPreferences if secure storage is empty but SharedPreferences has data
      if (_authToken == null || _user == null) {
        await _migrateFromSharedPreferences();
      }

      notifyListeners();
    } catch (e) {
      log('Error loading stored auth: $e');
      _authToken = null;
      _user = null;
      notifyListeners();
    }
  }

  /// Migrate data from SharedPreferences to SecureStorage
  Future<void> _migrateFromSharedPreferences() async {
    await AuthMigrationService.migrateFromSharedPreferences();
  }

  Future<void> checkAuthStatus() async {
    log('AUTH_CHECK: Starting authentication status check...');

    try {
      // Check if we have a stored token
      if (_authToken == null) {
        log('AUTH_CHECK: No stored token found');
        await logout();
        return;
      }

      log('AUTH_CHECK: Verifying token with server...');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      log('AUTH_CHECK: Server response status: ${response.statusCode}');
      log('AUTH_CHECK: Server response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = data['user'];
        log('AUTH_CHECK: Token verified - User role: ${_user?['role']}');

        // Send FCM token to backend after successful auth verification
        await _saveFCMTokenToBackend();

        // Also try to save token to database via FCM service
        if (_authToken != null && _user != null) {
          Logger.info('AUTH: User authenticated, attempting to save FCM token');
          await FCMService().saveTokenToDatabase(_authToken!, _user!['_id']);
        }

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

  Future<bool> login(String email, String password, {String? companyId}) async {
    log('LOGIN_DEBUG: Starting login for email: $email, companyId: $companyId');
    log('LOGIN_DEBUG: Previous user data - Token: ${_token != null}, User: ${_user?['firstName']} ${_user?['lastName']}');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      log('LOGIN_DEBUG: Making API call to  ${ApiConfig.baseUrl}/auth/login');

      final requestBody = {
        'email': email,
        'password': password,
      };

      // Add companyId if provided
      if (companyId != null && companyId.isNotEmpty) {
        requestBody['companyId'] = companyId;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      log('LOGIN_DEBUG: Response status code: ${response.statusCode}');
      log('LOGIN_DEBUG: Response body: ${response.body}');

      final data = jsonDecode(response.body); // Define data here

      if (response.statusCode == 200) {
        _authToken = data['token'];
        _token = _authToken; // Assign to _token for consistency
        log('LOGIN_DEBUG: Token received: _authToken');
        _user = data['user'];
        log('LOGIN_DEBUG: User data received: ${_user?['firstName']} ${_user?['lastName']}');
        log('LOGIN_DEBUG: Backend token field: ${data['token']}');
        log('LOGIN_DEBUG: Token received from backend response: _authToken');

        // Extract and store company ID if available
        if (_user != null && _user!['companyId'] != null) {
          final companyId = _user!['companyId'].toString();
          await SecureStorageService.storeCompanyId(companyId);
          log('LOGIN_DEBUG: Company ID stored: $companyId');
        }

        // Always save auth token and user data to SecureStorage
        await _saveAuthToPrefs();

        // Store remembered credentials in secure storage
        await SecureStorageService.storeRememberedCredentials(
          email: email,
          password: password,
          rememberMe: _rememberMe,
        );

        // Force refresh all providers to prevent data mixing between users
        await _forceRefreshAllProviders();

        // Clear image cache to prevent showing previous user's avatars
        await _clearImageCache();
        // --- Ensure profile is refreshed after login ---
        if (_profileProvider != null) {
          log('LOGIN_DEBUG: Force refreshing profile after login');
          await _profileProvider?.forceRefreshProfile();
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

        // --- Load company settings after login ---
        if (_companySettingsProvider != null) {
          log('LOGIN_DEBUG: Loading company settings after login');
          try {
            await _companySettingsProvider!.autoLoad();
            log('LOGIN_DEBUG: Company settings autoLoad completed');
          } catch (e) {
            log('LOGIN_DEBUG: Company settings autoLoad failed: $e');
          }
        } else {
          log('LOGIN_DEBUG: CompanySettingsProvider is not set, cannot load company settings');
        }

        // --- Load features after login ---
        if (_featureProvider != null) {
          log('LOGIN_DEBUG: Loading features after login');
          // Use the same approach as CompanyInfoWidget - load features after UI is built
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await _featureProvider!.loadFeatures();
              log('LOGIN_DEBUG: Features loaded successfully');
            } catch (e) {
              log('LOGIN_DEBUG: Features loading failed: $e');
              // Try to force refresh features even if initial load fails
              try {
                await _featureProvider!.forceRefreshFeatures();
                log('LOGIN_DEBUG: Force refresh features successful');
              } catch (forceError) {
                log('LOGIN_DEBUG: Force refresh features also failed: $forceError');
              }
            }
          });
        } else {
          log('LOGIN_DEBUG: FeatureProvider is not set, cannot load features');
          // Schedule feature loading for when provider becomes available
          _scheduleFeatureLoading = true;
        }

        return true;
      } else {
        final errorMessage = data['message'] ?? 'Login failed';
        log('LOGIN_DEBUG: Login failed with message: $errorMessage');
        _error = errorMessage;
        return false;
      }
    } catch (e) {
      log('LOGIN_DEBUG: Exception during login: $e');
      _error = 'Network error: $e';
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

  // Provider references for clearing state during logout
  ProfileProvider? _profileProvider;
  AttendanceProvider? _attendanceProvider;
  CompanyProvider? _companyProvider;
  FeatureProvider? _featureProvider;
  CompanySettingsProvider? _companySettingsProvider;

  // Methods to set provider references
  void setProfileProvider(ProfileProvider provider) {
    _profileProvider = provider;
  }

  void setAttendanceProvider(AttendanceProvider provider) {
    _attendanceProvider = provider;
  }

  void setCompanyProvider(CompanyProvider provider) {
    _companyProvider = provider;
  }

  void setFeatureProvider(FeatureProvider provider) {
    _featureProvider = provider;

    // If features were scheduled to be loaded during login, load them now
    if (_scheduleFeatureLoading && isAuthenticated) {
      log('LOGIN_DEBUG: Loading delayed features after FeatureProvider setup');
      _scheduleFeatureLoading = false;
      // Use the same approach as CompanyInfoWidget - load features after UI is built
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await provider.loadFeatures();
          log('LOGIN_DEBUG: Delayed features loading successful');
        } catch (e) {
          log('LOGIN_DEBUG: Delayed features loading failed: $e');
          // Try force refresh as fallback
          try {
            await provider.forceRefreshFeatures();
            log('LOGIN_DEBUG: Delayed force refresh successful');
          } catch (forceError) {
            log('LOGIN_DEBUG: Delayed force refresh failed: $forceError');
          }
        }
      });
    }
  }

  void setCompanySettingsProvider(CompanySettingsProvider provider) {
    _companySettingsProvider = provider;
  }

  /// Clear all provider states during logout
  Future<void> _clearAllProviders() async {
    log('DEBUG: Clearing all providers');

    if (_profileProvider != null) {
      log('DEBUG: Clearing profile via ProfileProvider');
      await _profileProvider?.clearProfile();
    }

    if (_attendanceProvider != null) {
      log('DEBUG: Clearing attendance via AttendanceProvider');
      _attendanceProvider!.clearAttendance();
    }

    if (_companyProvider != null) {
      log('DEBUG: Clearing company data via CompanyProvider');
      await _companyProvider?.clearCompany();
    }

    if (_featureProvider != null) {
      log('DEBUG: Clearing features via FeatureProvider');
      _featureProvider!.clearFeatures();
    }

    if (_companySettingsProvider != null) {
      log('DEBUG: Clearing company settings');
      _companySettingsProvider!.clearSettings();
    }
  }

  /// Force refresh all providers when a new user logs in
  Future<void> _forceRefreshAllProviders() async {
    log('DEBUG: Force refreshing all providers for new user');

    if (_profileProvider != null) {
      log('DEBUG: Force refreshing profile');
      await _profileProvider?.forceRefreshProfile();
    }

    if (_attendanceProvider != null) {
      log('DEBUG: Clearing attendance data for new user');
      _attendanceProvider!.clearAttendance();
    }

    if (_companyProvider != null) {
      log('DEBUG: Refreshing company data for new user');
      await _companyProvider?.clearCompany();
      // Company data will be loaded when needed
    }

    if (_featureProvider != null) {
      log('DEBUG: Refreshing features for new user');
      _featureProvider!.clearFeatures();
    }

    if (_companySettingsProvider != null) {
      log('DEBUG: Refreshing company settings for new user');
      _companySettingsProvider!.clearSettings();
    }
  }

  FeatureProvider? get featureProvider => _featureProvider;

  Future<void> logout() async {
    log('AUTH PROVIDER: Logout called');
    log('Logging out...');
    _token = null;
    _authToken = null;
    _user = null;
    _error = null;
    notifyListeners();

    // Clear image cache to prevent showing previous user's avatars
    await _clearImageCache();

    log('DEBUG: Starting logout process');
    log('DEBUG: Current token: $_token');
    log('DEBUG: Current user: $_user');

    try {
      // Clear auth data from secure storage (includes company data)
      log('DEBUG: Clearing SecureStorage auth data');
      await SecureStorageService.clearAuthData();

      // Only clear remembered credentials if remember me is disabled
      if (!_rememberMe) {
        await SecureStorageService.clearRememberedCredentials();
        log('DEBUG: Cleared remembered credentials from SecureStorage');
      }

      // Clear all provider states
      await _clearAllProviders();

      log('DEBUG: Logout process completed');
    } catch (e) {
      log('ERROR: Exception during logout: $e');
    }

    // Invalidate cache after logout
    await cacheService.clear();

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
    log('SAVE_AUTH_DEBUG: Saving auth to SecureStorage');

    try {
      if (_authToken != null) {
        log('SAVE_AUTH_DEBUG: Token before saving: $_authToken');
        await SecureStorageService.storeAuthToken(_authToken!);
        log('SAVE_AUTH_DEBUG: Token saved to SecureStorage: $_authToken');
      } else {
        await SecureStorageService.clearAuthData();
        log('SAVE_AUTH_DEBUG: Auth data cleared from SecureStorage');
      }

      if (_user != null) {
        await SecureStorageService.storeUserData(json.encode(_user));
        log('SAVE_AUTH_DEBUG: User saved to SecureStorage: $_user');
      }

      // Save FCM token to backend if user is authenticated
      if (_authToken != null && _user != null) {
        Logger.info('AUTH: User authenticated, attempting to save FCM token');
        await _saveFCMTokenToBackend();
        // Also try to save token to database via FCM service
        Logger.info('AUTH: Calling FCM service to save token to database');
        await FCMService().saveTokenToDatabase(_authToken!, _user!['_id']);
      } else {
        Logger.warning(
            'AUTH: Cannot save FCM token - authToken: ${_authToken != null}, user: ${_user != null}');
      }
    } catch (e) {
      log('SAVE_AUTH_DEBUG: Error saving to SecureStorage: $e');
      // Fallback to SharedPreferences if SecureStorage fails
      await _saveAuthToSharedPrefs();
    }
  }

  /// Fallback method for saving to SharedPreferences if SecureStorage fails
  Future<void> _saveAuthToSharedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      log('SAVE_AUTH_DEBUG: Fallback to SharedPreferences');

      if (_authToken != null) {
        await prefs.setString('token', _authToken!);
      } else {
        await prefs.remove('token');
      }

      if (_user != null) {
        await prefs.setString('user', json.encode(_user));
      } else {
        await prefs.remove('user');
      }
    } catch (e) {
      log('SAVE_AUTH_DEBUG: Error saving to SharedPreferences: $e');
    }
  }

  Future<void> _clearAuthFromPrefs() async {
    try {
      log('CLEAR_AUTH_DEBUG: Clearing authentication state from SecureStorage');
      await SecureStorageService.clearAuthData();
      _token = null;
      _authToken = null;
      _user = null;
      log('CLEAR_AUTH_DEBUG: Authentication state cleared from SecureStorage');
      notifyListeners();
    } catch (e) {
      log('CLEAR_AUTH_DEBUG: Error clearing from SecureStorage: $e');
      // Fallback to SharedPreferences
      await _clearAuthFromSharedPrefs();
    }
  }

  /// Fallback method for clearing from SharedPreferences if SecureStorage fails
  Future<void> _clearAuthFromSharedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      log('CLEAR_AUTH_DEBUG: Fallback clearing from SharedPreferences');
      await prefs.remove('token');
      await prefs.remove('user');
      _token = null;
      _authToken = null;
      _user = null;
      notifyListeners();
    } catch (e) {
      log('CLEAR_AUTH_DEBUG: Error clearing from SharedPreferences: $e');
    }
  }

  /// Clear all stored authentication data
  Future<void> forceClearAuth() async {
    try {
      _token = null;
      _authToken = null;
      _user = null;
      _error = null;
      _isLoading = false;

      // Clear from secure storage
      await SecureStorageService.clearAllData();

      log('AuthProvider: All auth data cleared');
      notifyListeners();
    } catch (e) {
      log('AuthProvider: Error clearing auth data: $e');
    }
  }

  /// Clear auth data and redirect to login (for authentication issues)
  Future<void> clearAuthAndRedirect(BuildContext context) async {
    await forceClearAuth();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
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
      Logger.info('FCM: Attempting to save token to backend');
      Logger.info('FCM: Auth token available: ${_authToken != null}');
      Logger.info('FCM: User available: ${_user != null}');

      final fcmToken = FCMService().fcmToken;
      Logger.info('FCM: FCM token available: ${fcmToken != null}');

      if (fcmToken == null) {
        Logger.warning('FCM: ❌ No token available');
        return;
      }

      Logger.info('FCM: Sending token to backend API');
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

      Logger.info('FCM: Backend response status: ${response.statusCode}');
      Logger.info('FCM: Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        Logger.info('FCM: ✅ Token saved to backend');
        // Subscribe to role-based topics
        if (_user?['role'] != null) {
          Logger.info('FCM: Subscribing to role topics for: ${_user!['role']}');
          await FCMService().subscribeToRoleTopics(_user!['role']);
        }
      } else {
        Logger.error('FCM: ❌ Save failed (${response.statusCode})');
      }
    } catch (e) {
      Logger.error('FCM: ❌ Save error: $e');
    }
  }

  /// Clear the image cache to prevent showing cached avatars from previous users
  Future<void> _clearImageCache() async {
    try {
      log('CLEAR_CACHE: Clearing image cache to prevent avatar caching issues');
      // Clear all cached images
      final cacheManager = DefaultCacheManager();
      await cacheManager.emptyCache();
      log('CLEAR_CACHE: Image cache cleared successfully');
    } catch (e) {
      log('CLEAR_CACHE: Error clearing image cache: $e');
    }
  }

  // Method to manually save FCM token to database
  Future<void> saveFCMTokenManually() async {
    try {
      Logger.info('AUTH: Manual FCM token save requested');
      Logger.info('AUTH: Auth token available: ${_authToken != null}');
      Logger.info('AUTH: User available: ${_user != null}');

      if (_authToken != null && _user != null) {
        Logger.info('AUTH: Saving FCM token manually');
        await _saveFCMTokenToBackend();
        await FCMService().saveTokenToDatabase(_authToken!, _user!['_id']);
        Logger.info('AUTH: Manual FCM token save completed');
      } else {
        Logger.warning(
            'AUTH: Cannot save FCM token manually - missing auth data');
      }
    } catch (e) {
      Logger.error('AUTH: Error in manual FCM token save: $e');
    }
  }

  @override
  void dispose() {
    // Clean up any controllers, listeners, or resources here
    super.dispose();
  }
}
