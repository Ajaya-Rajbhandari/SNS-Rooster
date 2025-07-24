import 'package:sns_rooster/services/location_settings_service.dart';

/// Test utility to verify location settings backend connection
class LocationSettingsConnectionTest {
  static final LocationSettingsService _service = LocationSettingsService();

  /// Test the connection and settings retrieval
  static Future<void> testConnection() async {
    print('🔍 Testing Location Settings Backend Connection...');

    try {
      // Test 1: Get all settings
      print('📡 Test 1: Getting all location settings...');
      final allSettings = await _service.getLocationSettings();
      print('✅ All settings retrieved: $allSettings');

      // Test 2: Get individual values
      print('📡 Test 2: Getting individual settings...');
      final geofenceRadius = await _service.getDefaultGeofenceRadius();
      final workingHours = await _service.getDefaultWorkingHours();
      final capacity = await _service.getDefaultCapacity();
      final notifications = await _service.getNotificationSettings();

      print('✅ Individual settings:');
      print('   - Geofence Radius: ${geofenceRadius}m');
      print(
          '   - Working Hours: ${workingHours['start']} - ${workingHours['end']}');
      print('   - Capacity: $capacity people');
      print('   - Notifications: $notifications');

      // Test 3: Update a setting
      print('📡 Test 3: Updating geofence radius...');
      final originalRadius = geofenceRadius;
      final newRadius = originalRadius + 10;

      await _service.updateLocationSettings({
        'defaultGeofenceRadius': newRadius,
      });

      // Test 4: Verify update
      print('📡 Test 4: Verifying update...');
      final updatedRadius = await _service.getDefaultGeofenceRadius();
      print('✅ Updated radius: ${updatedRadius}m (was ${originalRadius}m)');

      // Test 5: Reset to original
      print('📡 Test 5: Resetting to original value...');
      await _service.updateLocationSettings({
        'defaultGeofenceRadius': originalRadius,
      });

      final finalRadius = await _service.getDefaultGeofenceRadius();
      print('✅ Final radius: ${finalRadius}m');

      print(
          '🎉 Location settings backend connection test completed successfully!');
    } catch (error) {
      print('❌ Location settings connection test failed: $error');
      print('💡 This might indicate:');
      print('   - Backend server is not running');
      print('   - Network connectivity issues');
      print('   - Authentication problems');
      print('   - API endpoint configuration issues');
    }
  }
}
