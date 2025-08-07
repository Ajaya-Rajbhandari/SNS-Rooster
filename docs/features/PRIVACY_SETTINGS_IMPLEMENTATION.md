# Privacy Settings Implementation

## Overview

The SNS Rooster app now includes comprehensive privacy settings that allow users to control how their data is collected and used. These settings work for both admin and employee users and are enforced throughout the application.

## Privacy Settings Available

### 1. App Permissions
- **Location Services**: Controls access to device location for attendance tracking and geofencing
- **Camera Access**: Controls access to device camera for profile photos and document uploads
- **Storage Access**: Controls access to device storage for app data and file storage

### 2. Data Usage
- **Push Notifications**: Controls whether the app can send push notifications
- **Usage Analytics**: Controls whether anonymous usage data is collected to improve the app

### 3. Data Rights
- **Export My Data**: Allows users to request a copy of their data
- **Delete My Data**: Allows users to request permanent deletion of their data

## Implementation Details

### Privacy Service (`lib/services/privacy_service.dart`)

The `PrivacyService` is a singleton service that manages all privacy settings:

```dart
class PrivacyService {
  // Check if location access is allowed
  Future<bool> shouldAllowLocationAccess() async
  
  // Check if notifications should be allowed
  Future<bool> shouldAllowNotifications() async
  
  // Check if analytics should be collected
  Future<bool> shouldCollectAnalytics() async
  
  // Log analytics event (only if analytics are enabled)
  Future<void> logAnalyticsEvent(String eventName, {Map<String, dynamic>? parameters}) async
}
```

### Location Service (`lib/services/location_service.dart`)

The `LocationService` respects privacy settings before accessing location data:

```dart
class LocationService {
  // Check if location access is allowed (respects privacy settings)
  Future<bool> isLocationAccessAllowed() async
  
  // Get current position (respects privacy settings)
  Future<Position?> getCurrentPosition({...}) async
  
  // Get location with privacy compliance for attendance
  Future<Map<String, dynamic>?> getLocationForAttendance() async
}
```

### Notification Service (`lib/services/notification_service.dart`)

The `NotificationService` respects privacy settings before sending notifications:

```dart
class NotificationService {
  // Check if notifications should be sent (respects privacy settings)
  Future<bool> shouldSendNotification() async
  
  // Send local notification (respects privacy settings)
  Future<void> sendLocalNotification({...}) async
  
  // Send push notification (respects privacy settings)
  Future<void> sendPushNotification({...}) async
}
```

## How Privacy Settings Work

### 1. Location Services
- **When Enabled**: App can access device location for attendance tracking, geofencing, and location-based features
- **When Disabled**: All location requests are blocked, and location-based features are disabled
- **Implementation**: The `LocationService` checks privacy settings before any location access

### 2. Notifications
- **When Enabled**: App can send push notifications, local notifications, and fetch notification data
- **When Disabled**: All notification-related operations are blocked
- **Implementation**: The `NotificationService` checks privacy settings before any notification operations

### 3. Analytics
- **When Enabled**: Anonymous usage data is collected to improve the app
- **When Disabled**: No analytics data is collected
- **Implementation**: The `PrivacyService.logAnalyticsEvent()` method only logs events when analytics are enabled

### 4. Camera Access
- **When Enabled**: App can access device camera for profile photos and document uploads
- **When Disabled**: Camera access is blocked
- **Implementation**: Camera widgets should check privacy settings before accessing camera

### 5. Storage Access
- **When Enabled**: App can access device storage for app data and file storage
- **When Disabled**: Storage access is blocked
- **Implementation**: File operations should check privacy settings before accessing storage

## Privacy Settings Screen

### Features
- **Real-time Updates**: Settings are saved immediately when toggled
- **Loading State**: Shows loading indicator while fetching settings
- **Error Handling**: Displays error messages if settings fail to save
- **Reset to Defaults**: Option to reset all settings to default values
- **Privacy Policy Links**: Direct links to privacy policy and support

### UI Sections
1. **Privacy Overview**: Explains what privacy settings control
2. **App Permissions**: Toggle switches for location, camera, and storage access
3. **Data Usage**: Toggle switches for notifications and analytics
4. **Your Data Rights**: Options to export or delete data
5. **Privacy Information**: Links to privacy policy and support
6. **Reset to Defaults**: Option to reset all settings

## Integration Points

### 1. Location Access
All location widgets and services should use the `LocationService` instead of directly calling `Geolocator`:

```dart
// Instead of:
Position position = await Geolocator.getCurrentPosition();

// Use:
final locationService = LocationService.instance;
Position? position = await locationService.getCurrentPosition();
```

### 2. Notifications
All notification operations should use the `NotificationService`:

```dart
// Instead of direct notification calls:
// Use the NotificationService methods that respect privacy settings
final notificationService = NotificationService(authProvider);
await notificationService.sendLocalNotification(
  title: 'Attendance Reminder',
  body: 'Time to check in!',
);
```

### 3. Analytics
All analytics events should use the `PrivacyService`:

```dart
// Instead of direct analytics calls:
// Use the PrivacyService method that respects analytics settings
final privacyService = PrivacyService.instance;
await privacyService.logAnalyticsEvent('user_action', parameters: {
  'action': 'button_clicked',
  'screen': 'dashboard',
});
```

## Testing Privacy Settings

### Test Cases
1. **Location Privacy**: Disable location services and verify that location-based features are blocked
2. **Notification Privacy**: Disable notifications and verify that no notifications are sent
3. **Analytics Privacy**: Disable analytics and verify that no analytics events are logged
4. **Settings Persistence**: Verify that settings are saved and restored correctly
5. **Reset Functionality**: Test the reset to defaults functionality

### Test Scenarios
- **Employee Dashboard**: Test location access for attendance tracking
- **Profile Screen**: Test camera access for profile photos
- **Notification Center**: Test notification fetching and display
- **Settings Screen**: Test all privacy setting toggles

## Privacy Compliance

### GDPR Compliance
- **Data Minimization**: Only collect data that is necessary
- **User Control**: Users can control what data is collected
- **Transparency**: Clear explanation of what data is collected and why
- **Data Rights**: Users can export and delete their data

### Best Practices
- **Default Settings**: All privacy settings default to enabled (user-friendly)
- **Clear Communication**: Privacy settings are clearly explained
- **Easy Access**: Privacy settings are easily accessible from the side navigation
- **Immediate Effect**: Changes take effect immediately

## Future Enhancements

### Planned Features
1. **Granular Permissions**: More detailed control over specific features
2. **Privacy Dashboard**: Visual representation of data usage
3. **Data Export**: Actual implementation of data export functionality
4. **Privacy Notifications**: Notify users when privacy settings change
5. **Audit Log**: Track changes to privacy settings

### Technical Improvements
1. **Backend Integration**: Store privacy settings on the server
2. **Cross-Device Sync**: Sync privacy settings across devices
3. **Privacy Analytics**: Track how users interact with privacy settings
4. **Automated Compliance**: Automated checks for privacy compliance

## Troubleshooting

### Common Issues
1. **Settings Not Saving**: Check SharedPreferences permissions
2. **Location Still Working**: Ensure all location widgets use LocationService
3. **Notifications Still Coming**: Ensure all notification calls use NotificationService
4. **Analytics Still Logging**: Ensure all analytics calls use PrivacyService

### Debug Information
- Privacy settings are logged when changed
- Blocked operations are logged for debugging
- Analytics events are logged when enabled
- Error messages are displayed to users when operations fail

## Conclusion

The privacy settings implementation provides users with comprehensive control over their data while maintaining app functionality. The modular design ensures that privacy settings are respected throughout the application, and the clear UI makes it easy for users to understand and control their privacy preferences. 