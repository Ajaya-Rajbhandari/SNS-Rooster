import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class PrivacyService {
  static const String _locationKey = 'privacy_location_enabled';
  static const String _notificationsKey = 'privacy_notifications_enabled';
  static const String _analyticsKey = 'privacy_analytics_enabled';
  static const String _cameraKey = 'privacy_camera_enabled';
  static const String _storageKey = 'privacy_storage_enabled';

  static PrivacyService? _instance;
  static PrivacyService get instance => _instance ??= PrivacyService._();

  PrivacyService._();

  /// Check if location services are enabled in privacy settings
  Future<bool> isLocationEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_locationKey) ?? true;
    } catch (e) {
      Logger.error('Error checking location privacy setting: $e');
      return true; // Default to enabled if error
    }
  }

  /// Check if notifications are enabled in privacy settings
  Future<bool> areNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_notificationsKey) ?? true;
    } catch (e) {
      Logger.error('Error checking notifications privacy setting: $e');
      return true; // Default to enabled if error
    }
  }

  /// Check if analytics are enabled in privacy settings
  Future<bool> isAnalyticsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_analyticsKey) ?? true;
    } catch (e) {
      Logger.error('Error checking analytics privacy setting: $e');
      return true; // Default to enabled if error
    }
  }

  /// Check if camera access is enabled in privacy settings
  Future<bool> isCameraEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_cameraKey) ?? true;
    } catch (e) {
      Logger.error('Error checking camera privacy setting: $e');
      return true; // Default to enabled if error
    }
  }

  /// Check if storage access is enabled in privacy settings
  Future<bool> isStorageEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_storageKey) ?? true;
    } catch (e) {
      Logger.error('Error checking storage privacy setting: $e');
      return true; // Default to enabled if error
    }
  }

  /// Update a privacy setting
  Future<void> updatePrivacySetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      Logger.info('Privacy setting updated: $key = $value');
    } catch (e) {
      Logger.error('Error updating privacy setting: $e');
    }
  }

  /// Get all privacy settings
  Future<Map<String, bool>> getAllPrivacySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'location': prefs.getBool(_locationKey) ?? true,
        'notifications': prefs.getBool(_notificationsKey) ?? true,
        'analytics': prefs.getBool(_analyticsKey) ?? true,
        'camera': prefs.getBool(_cameraKey) ?? true,
        'storage': prefs.getBool(_storageKey) ?? true,
      };
    } catch (e) {
      Logger.error('Error getting all privacy settings: $e');
      return {
        'location': true,
        'notifications': true,
        'analytics': true,
        'camera': true,
        'storage': true,
      };
    }
  }

  /// Check if location access should be allowed (respects privacy settings)
  Future<bool> shouldAllowLocationAccess() async {
    final locationEnabled = await isLocationEnabled();
    Logger.info('Privacy check - Location enabled: $locationEnabled');
    if (!locationEnabled) {
      Logger.info('Location access blocked by privacy settings');
      return false;
    }
    Logger.info('Location access allowed by privacy settings');
    return true;
  }

  /// Check if notifications should be allowed (respects privacy settings)
  Future<bool> shouldAllowNotifications() async {
    final notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) {
      Logger.info('Notifications blocked by privacy settings');
      return false;
    }
    return true;
  }

  /// Check if analytics should be collected (respects privacy settings)
  Future<bool> shouldCollectAnalytics() async {
    final analyticsEnabled = await isAnalyticsEnabled();
    if (!analyticsEnabled) {
      Logger.info('Analytics collection blocked by privacy settings');
      return false;
    }
    return true;
  }

  /// Check if camera access should be allowed (respects privacy settings)
  Future<bool> shouldAllowCameraAccess() async {
    final cameraEnabled = await isCameraEnabled();
    if (!cameraEnabled) {
      Logger.info('Camera access blocked by privacy settings');
      return false;
    }
    return true;
  }

  /// Check if storage access should be allowed (respects privacy settings)
  Future<bool> shouldAllowStorageAccess() async {
    final storageEnabled = await isStorageEnabled();
    if (!storageEnabled) {
      Logger.info('Storage access blocked by privacy settings');
      return false;
    }
    return true;
  }

  /// Log analytics event (only if analytics are enabled)
  Future<void> logAnalyticsEvent(String eventName,
      {Map<String, dynamic>? parameters}) async {
    if (await shouldCollectAnalytics()) {
      Logger.info('Analytics event: $eventName ${parameters ?? {}}');
      // TODO: Implement actual analytics logging
    } else {
      Logger.info(
          'Analytics event skipped due to privacy settings: $eventName');
    }
  }

  /// Reset all privacy settings to defaults
  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_locationKey, true);
      await prefs.setBool(_notificationsKey, true);
      await prefs.setBool(_analyticsKey, true);
      await prefs.setBool(_cameraKey, true);
      await prefs.setBool(_storageKey, true);
      Logger.info('Privacy settings reset to defaults');
    } catch (e) {
      Logger.error('Error resetting privacy settings: $e');
    }
  }
}
