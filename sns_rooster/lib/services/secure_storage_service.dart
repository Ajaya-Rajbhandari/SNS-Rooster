import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// Secure Storage Service for sensitive data
/// 
/// This service provides encrypted storage for sensitive information
/// like authentication tokens, passwords, and user credentials.
/// It uses platform-specific secure storage implementations.
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      groupId: 'group.com.snsrooster.app',
      accountName: 'SNS Rooster',
    ),
    lOptions: LinuxOptions(),
    mOptions: MacOsOptions(
      groupId: 'group.com.snsrooster.app',
      accountName: 'SNS Rooster',
    ),
    wOptions: WindowsOptions(),
  );

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _rememberedEmailKey = 'remembered_email';
  static const String _rememberedPasswordKey = 'remembered_password';
  static const String _rememberMeKey = 'remember_me';
  static const String _fcmTokenKey = 'fcm_token';

  /// Store authentication token securely
  static Future<void> storeAuthToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      log('SecureStorage: Auth token stored successfully');
    } catch (e) {
      Logger.error('Failed to store auth token: $e');
      rethrow;
    }
  }

  /// Retrieve authentication token
  static Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      Logger.error('Failed to retrieve auth token: $e');
      return null;
    }
  }

  /// Store refresh token securely
  static Future<void> storeRefreshToken(String refreshToken) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      log('SecureStorage: Refresh token stored successfully');
    } catch (e) {
      Logger.error('Failed to store refresh token: $e');
      rethrow;
    }
  }

  /// Retrieve refresh token
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      Logger.error('Failed to retrieve refresh token: $e');
      return null;
    }
  }

  /// Store user data securely
  static Future<void> storeUserData(String userData) async {
    try {
      await _storage.write(key: _userDataKey, value: userData);
      log('SecureStorage: User data stored successfully');
    } catch (e) {
      Logger.error('Failed to store user data: $e');
      rethrow;
    }
  }

  /// Retrieve user data
  static Future<String?> getUserData() async {
    try {
      return await _storage.read(key: _userDataKey);
    } catch (e) {
      Logger.error('Failed to retrieve user data: $e');
      return null;
    }
  }

  /// Store remembered credentials (if remember me is enabled)
  static Future<void> storeRememberedCredentials({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      if (rememberMe) {
        await _storage.write(key: _rememberedEmailKey, value: email);
        await _storage.write(key: _rememberedPasswordKey, value: password);
        await _storage.write(key: _rememberMeKey, value: 'true');
        log('SecureStorage: Remembered credentials stored successfully');
      } else {
        // Clear remembered credentials if remember me is disabled
        await clearRememberedCredentials();
      }
    } catch (e) {
      Logger.error('Failed to store remembered credentials: $e');
      rethrow;
    }
  }

  /// Retrieve remembered credentials
  static Future<Map<String, String?>> getRememberedCredentials() async {
    try {
      final rememberMe = await _storage.read(key: _rememberMeKey);
      
      if (rememberMe == 'true') {
        final email = await _storage.read(key: _rememberedEmailKey);
        final password = await _storage.read(key: _rememberedPasswordKey);
        
        return {
          'email': email,
          'password': password,
          'remember_me': 'true',
        };
      }
      
      return {
        'email': null,
        'password': null,
        'remember_me': 'false',
      };
    } catch (e) {
      Logger.error('Failed to retrieve remembered credentials: $e');
      return {
        'email': null,
        'password': null,
        'remember_me': 'false',
      };
    }
  }

  /// Clear remembered credentials
  static Future<void> clearRememberedCredentials() async {
    try {
      await _storage.delete(key: _rememberedEmailKey);
      await _storage.delete(key: _rememberedPasswordKey);
      await _storage.delete(key: _rememberMeKey);
      log('SecureStorage: Remembered credentials cleared');
    } catch (e) {
      Logger.error('Failed to clear remembered credentials: $e');
    }
  }

  /// Store FCM token
  static Future<void> storeFCMToken(String fcmToken) async {
    try {
      await _storage.write(key: _fcmTokenKey, value: fcmToken);
      log('SecureStorage: FCM token stored successfully');
    } catch (e) {
      Logger.error('Failed to store FCM token: $e');
    }
  }

  /// Retrieve FCM token
  static Future<String?> getFCMToken() async {
    try {
      return await _storage.read(key: _fcmTokenKey);
    } catch (e) {
      Logger.error('Failed to retrieve FCM token: $e');
      return null;
    }
  }

  /// Clear all stored data (logout)
  static Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
      log('SecureStorage: All data cleared successfully');
    } catch (e) {
      Logger.error('Failed to clear all data: $e');
    }
  }

  /// Clear only authentication data (keep remembered credentials if enabled)
  static Future<void> clearAuthData() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userDataKey);
      await _storage.delete(key: _fcmTokenKey);
      log('SecureStorage: Auth data cleared successfully');
    } catch (e) {
      Logger.error('Failed to clear auth data: $e');
    }
  }

  /// Check if secure storage is available
  static Future<bool> isSecureStorageAvailable() async {
    try {
      // Try to write and read a test value
      const testKey = 'test_availability';
      const testValue = 'test';
      
      await _storage.write(key: testKey, value: testValue);
      final result = await _storage.read(key: testKey);
      await _storage.delete(key: testKey);
      
      return result == testValue;
    } catch (e) {
      Logger.error('Secure storage not available: $e');
      return false;
    }
  }

  /// Get all stored keys (for debugging in development only)
  static Future<Set<String>> getAllKeys() async {
    if (kReleaseMode) {
      throw Exception('getAllKeys() is only available in debug mode');
    }
    
    try {
      final map = await _storage.readAll();
      return map.keys.toSet();
    } catch (e) {
      Logger.error('Failed to get all keys: $e');
      return <String>{};
    }
  }

  /// Migrate data from SharedPreferences to SecureStorage
  static Future<void> migrateFromSharedPreferences({
    String? token,
    String? userData,
    String? email,
    String? password,
    bool? rememberMe,
  }) async {
    try {
      if (token != null) {
        await storeAuthToken(token);
      }
      
      if (userData != null) {
        await storeUserData(userData);
      }
      
      if (email != null && password != null && rememberMe != null) {
        await storeRememberedCredentials(
          email: email,
          password: password,
          rememberMe: rememberMe,
        );
      }
      
      log('SecureStorage: Migration from SharedPreferences completed');
    } catch (e) {
      Logger.error('Failed to migrate from SharedPreferences: $e');
      rethrow;
    }
  }
}
