import 'package:geolocator/geolocator.dart';
import '../utils/logger.dart';
import 'privacy_service.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();

  final PrivacyService _privacyService = PrivacyService.instance;

  LocationService._();

  /// Check if location access is allowed (respects privacy settings)
  Future<bool> isLocationAccessAllowed() async {
    try {
      // First check privacy settings
      if (!await _privacyService.shouldAllowLocationAccess()) {
        Logger.info('Location access blocked by privacy settings');
        return false;
      }

      // Then check system permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        Logger.info('Location permission denied by system');
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        Logger.info('Location permission permanently denied by system');
        return false;
      }

      return true;
    } catch (e) {
      Logger.error('Error checking location access: $e');
      return false;
    }
  }

  /// Get current position (respects privacy settings)
  Future<Position?> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
    Duration? timeLimit,
  }) async {
    try {
      // Check if location access is allowed
      if (!await isLocationAccessAllowed()) {
        Logger.info('Location access not allowed - returning null');
        return null;
      }

      // Log analytics event if enabled
      await _privacyService
          .logAnalyticsEvent('location_requested', parameters: {
        'accuracy': desiredAccuracy.toString(),
        'timeLimit': timeLimit?.inSeconds,
      });

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: desiredAccuracy,
        timeLimit: timeLimit,
      );

      Logger.info(
          'Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      Logger.error('Error getting current position: $e');
      return null;
    }
  }

  /// Request location permission (respects privacy settings)
  Future<LocationPermission> requestPermission() async {
    try {
      // Check privacy settings first
      if (!await _privacyService.shouldAllowLocationAccess()) {
        Logger.info('Location permission request blocked by privacy settings');
        return LocationPermission.denied;
      }

      // Log analytics event if enabled
      await _privacyService.logAnalyticsEvent('location_permission_requested');

      // Request system permission
      final permission = await Geolocator.requestPermission();
      Logger.info('Location permission result: $permission');
      return permission;
    } catch (e) {
      Logger.error('Error requesting location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Check current location permission status
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      Logger.error('Error checking location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Get last known position (respects privacy settings)
  Future<Position?> getLastKnownPosition() async {
    try {
      // Check if location access is allowed
      if (!await isLocationAccessAllowed()) {
        Logger.info(
            'Location access not allowed - returning null for last known position');
        return null;
      }

      // Log analytics event if enabled
      await _privacyService.logAnalyticsEvent('last_known_location_requested');

      // Get last known position
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        Logger.info(
            'Last known location: ${position.latitude}, ${position.longitude}');
      } else {
        Logger.info('No last known location available');
      }
      return position;
    } catch (e) {
      Logger.error('Error getting last known position: $e');
      return null;
    }
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      // First check privacy settings
      if (!await _privacyService.shouldAllowLocationAccess()) {
        Logger.info('Location services blocked by privacy settings');
        return false;
      }

      // Then check system location services
      final enabled = await Geolocator.isLocationServiceEnabled();
      Logger.info('Location services enabled: $enabled');
      return enabled;
    } catch (e) {
      Logger.error('Error checking location service status: $e');
      return false;
    }
  }

  /// Calculate distance between two positions
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if a position is within a geofence
  bool isWithinGeofence(
    double userLatitude,
    double userLongitude,
    double geofenceLatitude,
    double geofenceLongitude,
    double geofenceRadius,
  ) {
    final distance = calculateDistance(
      userLatitude,
      userLongitude,
      geofenceLatitude,
      geofenceLongitude,
    );

    final isWithin = distance <= geofenceRadius;
    Logger.info(
        'Geofence check: distance=$distance, radius=$geofenceRadius, within=$isWithin');
    return isWithin;
  }

  /// Get location with privacy compliance
  Future<Map<String, dynamic>?> getLocationForAttendance() async {
    try {
      // Check privacy settings
      if (!await _privacyService.shouldAllowLocationAccess()) {
        Logger.info(
            'Location access blocked by privacy settings for attendance');
        return null;
      }

      // Get current position
      final position = await getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (position == null) {
        Logger.warning('Could not get location for attendance');
        return null;
      }

      // Log analytics event if enabled
      await _privacyService
          .logAnalyticsEvent('location_used_for_attendance', parameters: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      });

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': position.timestamp?.toIso8601String(),
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
      };
    } catch (e) {
      Logger.error('Error getting location for attendance: $e');
      return null;
    }
  }
}
