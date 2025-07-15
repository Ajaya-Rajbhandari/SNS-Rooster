import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';
import '../utils/logger.dart';

class AuthMigrationService {
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  /// Migrate data from SharedPreferences to SecureStorage
  static Future<void> migrateFromSharedPreferences() async {
    try {
      Logger.info('AUTH_MIGRATION: Starting migration from SharedPreferences to SecureStorage');
      final prefs = await SharedPreferences.getInstance();

      final oldToken = prefs.getString('token');
      final oldUser = prefs.getString('user');
      final oldRememberMe = prefs.getBool(_rememberMeKey) ?? false;
      final oldEmail = prefs.getString(_savedEmailKey);
      final oldPassword = prefs.getString(_savedPasswordKey);

      if (oldToken != null || oldUser != null) {
        await SecureStorageService.migrateFromSharedPreferences(
          token: oldToken,
          userData: oldUser,
          email: oldEmail,
          password: oldPassword,
          rememberMe: oldRememberMe,
        );

        // Clear old data from SharedPreferences
        await prefs.remove('token');
        await prefs.remove('user');
        await prefs.remove(_rememberMeKey);
        await prefs.remove(_savedEmailKey);
        await prefs.remove(_savedPasswordKey);

        Logger.info('AUTH_MIGRATION: Migration completed successfully');
      }
    } catch (e) {
      Logger.error('AUTH_MIGRATION: Migration failed: $e');
    }
  }
}
