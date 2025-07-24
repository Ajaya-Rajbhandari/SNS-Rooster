import 'dart:convert';
import 'package:sns_rooster/services/api_service.dart';
import 'package:sns_rooster/config/api_config.dart';

class LocationSettingsService {
  final ApiService _apiService = ApiService(baseUrl: ApiConfig.baseUrl);

  /// Get location settings from the backend
  Future<Map<String, dynamic>> getLocationSettings() async {
    try {
      final response = await _apiService.get('/admin/settings/location');

      if (response.success) {
        return response.data['locationSettings'] ?? {};
      } else {
        throw Exception(response.message ?? 'Failed to get location settings');
      }
    } catch (e) {
      throw Exception('Error fetching location settings: $e');
    }
  }

  /// Update location settings in the backend
  Future<Map<String, dynamic>> updateLocationSettings(
      Map<String, dynamic> settings) async {
    try {
      final response = await _apiService.put('/admin/settings/location', {
        'locationSettings': settings,
      });

      if (response.success) {
        return response.data['locationSettings'] ?? {};
      } else {
        throw Exception(
            response.message ?? 'Failed to update location settings');
      }
    } catch (e) {
      throw Exception('Error updating location settings: $e');
    }
  }

  /// Get default geofence radius
  Future<int> getDefaultGeofenceRadius() async {
    try {
      final settings = await getLocationSettings();
      return settings['defaultGeofenceRadius'] ?? 100;
    } catch (e) {
      return 100; // Default fallback
    }
  }

  /// Get default working hours
  Future<Map<String, String>> getDefaultWorkingHours() async {
    try {
      final settings = await getLocationSettings();
      final workingHours = settings['defaultWorkingHours'] ?? {};
      return {
        'start': workingHours['start'] ?? '09:00',
        'end': workingHours['end'] ?? '17:00',
      };
    } catch (e) {
      return {'start': '09:00', 'end': '17:00'}; // Default fallback
    }
  }

  /// Get default capacity
  Future<int> getDefaultCapacity() async {
    try {
      final settings = await getLocationSettings();
      return settings['defaultCapacity'] ?? 50;
    } catch (e) {
      return 50; // Default fallback
    }
  }

  /// Get notification settings
  Future<Map<String, bool>> getNotificationSettings() async {
    try {
      final settings = await getLocationSettings();
      final notifications = settings['notifications'] ?? {};
      return {
        'locationUpdates': notifications['locationUpdates'] ?? true,
        'employeeAssignments': notifications['employeeAssignments'] ?? true,
        'capacityAlerts': notifications['capacityAlerts'] ?? false,
      };
    } catch (e) {
      return {
        'locationUpdates': true,
        'employeeAssignments': true,
        'capacityAlerts': false,
      }; // Default fallback
    }
  }
}
