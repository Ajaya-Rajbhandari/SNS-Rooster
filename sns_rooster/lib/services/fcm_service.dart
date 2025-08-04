import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import '../config/api_config.dart';
import 'dart:typed_data';
import '../utils/global_navigator.dart';
import '../providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart'; // Added for Color

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Add these fields inside the class
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id (must match AndroidManifest.xml)
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  // Add persistent notification channel for break status
  static const AndroidNotificationChannel persistentChannel =
      AndroidNotificationChannel(
    'persistent_status_channel', // id
    'Status Notifications', // title
    description:
        'This channel is used for persistent status notifications like break timers.',
    importance: Importance.low, // Low importance to avoid sound/vibration
    playSound: false,
    enableVibration: false,
    showBadge: false,
  );

  Future<void> setupNotificationChannel() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Setup persistent channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(persistentChannel);
  }

  String? _fcmToken;
  bool _isInitialized = false;

  // Getter for FCM token
  String? get fcmToken => _fcmToken;

  // Debug method to refresh FCM token
  Future<void> debugRefreshToken({String? authToken, String? userId}) async {
    try {
      Logger.info('FCM: Debug - Getting fresh token...');
      final token = await _firebaseMessaging.getToken();
      Logger.info('FCM: Debug - Fresh token: ${token?.substring(0, 30)}...');

      _fcmToken = token;

      if (token != null && authToken != null && userId != null) {
        Logger.info('FCM: Debug - Saving fresh token to backend...');
        await _saveTokenToDatabase(token, authToken, userId);
        Logger.info('FCM: Debug - Fresh token saved successfully');
      }
    } catch (e) {
      Logger.error('FCM: Debug - Error refreshing token: $e');
    }
  }

  // Initialize FCM service
  Future<void> initialize({String? authToken, String? userId}) async {
    if (_isInitialized) return;

    try {
      // Request permission for iOS
      if (Platform.isIOS) {
        NotificationSettings settings =
            await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          Logger.info('FCM: User granted permission');
        } else {
          Logger.warning('FCM: User declined or has not accepted permission');
        }
      }

      // Get FCM token with detailed error handling
      try {
        Logger.info('FCM: 🔄 Attempting to get FCM token...');
        _fcmToken = await _firebaseMessaging.getToken();

        if (_fcmToken != null) {
          Logger.info(
              'FCM: ✅ Token generated successfully: ${_fcmToken!.substring(0, 20)}...');

          // Save token to preferences
          await _saveTokenToPrefs(_fcmToken!);

          // Save token to database if auth credentials are available
          if (authToken != null && userId != null) {
            await _saveTokenToDatabase(_fcmToken!, authToken, userId);
          } else {
            Logger.info(
                'FCM: Auth credentials not available, will save to database later');
          }
        } else {
          Logger.error(
              'FCM: ❌ Token is null - this indicates a Firebase configuration issue');
          Logger.error('FCM: Please check:');
          Logger.error('FCM: 1. google-services.json is properly configured');
          Logger.error('FCM: 2. Firebase project has FCM enabled');
          Logger.error('FCM: 3. Google Play Services is up to date');
          Logger.error('FCM: 4. Device has internet connection');
        }
      } catch (e) {
        Logger.error('FCM: ❌ Error getting FCM token: $e');
        Logger.error(
            'FCM: This is likely a Firebase configuration or network issue');

        // Try to get more specific error information
        if (e.toString().contains('FIS_AUTH_ERROR')) {
          Logger.error('FCM: FIS_AUTH_ERROR detected - this usually means:');
          Logger.error('FCM: 1. Firebase project configuration issue');
          Logger.error('FCM: 2. Google Play Services authentication problem');
          Logger.error('FCM: 3. Network connectivity issues');
        }
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        Logger.info('FCM Token refreshed: $newToken');
        _saveTokenToPrefs(newToken);
        // Note: We'll need to save to database when auth is available
      });

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from notification
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _isInitialized = true;
      Logger.info('FCM: ✅ Service initialized');
    } catch (e) {
      Logger.error('FCM: ❌ Initialization failed: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await setupNotificationChannel();
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    Logger.info('FCM: Received foreground message: ${message.messageId}');

    // Show local notification
    _showLocalNotification(message);

    // refresh unread count badge
    try {
      final context = GlobalNavigator.navigatorKey.currentContext;
      if (context != null) {
        final provider =
            Provider.of<NotificationProvider>(context, listen: false);
        provider.fetchNotifications(refresh: true);
      }
    } catch (_) {}
  }

  // Handle notification taps
  void _handleNotificationTap(RemoteMessage message) {
    Logger.info('FCM: Notification tapped: ${message.messageId}');

    // Handle navigation based on notification data
    _handleNotificationNavigation(message.data);

    // mark unread count refreshed
    try {
      final context = GlobalNavigator.navigatorKey.currentContext;
      if (context != null) {
        final provider =
            Provider.of<NotificationProvider>(context, listen: false);
        provider.fetchNotifications(refresh: true);
      }
    } catch (_) {}
  }

  // Handle local notification taps
  void _onNotificationTapped(NotificationResponse response) {
    Logger.info('FCM: Local notification tapped: ${response.payload}');

    if (response.payload != null) {
      Map<String, dynamic> data = json.decode(response.payload!);
      _handleNotificationNavigation(data);
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // <-- must match manifest and channel setup
      'High Importance Notifications',
      channelDescription: 'Notifications for SNS Rooster app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      enableVibration: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'SNS Rooster',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: json.encode(message.data),
    );
  }

  // Show persistent break status notification
  Future<void> showPersistentBreakNotification({
    required String breakType,
    required DateTime startTime,
    required int? maxDurationMinutes,
    required int totalBreaksToday,
  }) async {
    final now = DateTime.now();
    final elapsed = now.difference(startTime);
    final remaining = maxDurationMinutes != null
        ? Duration(minutes: maxDurationMinutes) - elapsed
        : null;

    final isOvertime =
        maxDurationMinutes != null && elapsed.inMinutes >= maxDurationMinutes;

    String statusText =
        'Started: ${_formatTime(startTime)} | Elapsed: ${_formatDuration(elapsed)}';
    if (remaining != null) {
      if (remaining.isNegative) {
        statusText += ' | Overtime: ${_formatDuration(-remaining)}';
      } else {
        statusText += ' | Remaining: ${_formatDuration(remaining)}';
      }
    }
    statusText += ' | Breaks today: $totalBreaksToday';

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'persistent_status_channel',
      'Status Notifications',
      channelDescription: 'Persistent status notifications for SNS Rooster app',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Makes notification persistent
      autoCancel: false, // Prevents auto-dismissal
      showWhen: false, // Don't show timestamp
      playSound: false,
      enableVibration: false,

      icon: '@mipmap/launcher_icon',
      color: isOvertime
          ? const Color(0xFFFF4444)
          : const Color(0xFFFF8800), // Red for overtime, orange for normal
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: false, // Don't show alert on iOS
      presentBadge: false,
      presentSound: false,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      999, // Fixed ID for persistent notification
      'Break Status: $breakType',
      statusText,
      platformChannelSpecifics,
      payload: json.encode({
        'type': 'break_status',
        'breakType': breakType,
        'startTime': startTime.toIso8601String(),
        'maxDurationMinutes': maxDurationMinutes,
        'totalBreaksToday': totalBreaksToday,
      }),
    );
  }

  // Update persistent break notification
  Future<void> updatePersistentBreakNotification({
    required String breakType,
    required DateTime startTime,
    required int? maxDurationMinutes,
    required int totalBreaksToday,
  }) async {
    // Recalculate elapsed time for real-time updates
    final now = DateTime.now();
    final elapsed = now.difference(startTime);
    final remaining = maxDurationMinutes != null
        ? Duration(minutes: maxDurationMinutes) - elapsed
        : null;

    final isOvertime =
        maxDurationMinutes != null && elapsed.inMinutes >= maxDurationMinutes;

    String statusText =
        'Started: ${_formatTime(startTime)} | Elapsed: ${_formatDuration(elapsed)}';
    if (remaining != null) {
      if (remaining.isNegative) {
        statusText += ' | Overtime: ${_formatDuration(-remaining)}';
      } else {
        statusText += ' | Remaining: ${_formatDuration(remaining)}';
      }
    }
    statusText += ' | Breaks today: $totalBreaksToday';

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'persistent_status_channel',
      'Status Notifications',
      channelDescription: 'Persistent status notifications for SNS Rooster app',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Makes notification persistent
      autoCancel: false, // Prevents auto-dismissal
      showWhen: false, // Don't show timestamp
      playSound: false,
      enableVibration: false,

      icon: '@mipmap/launcher_icon',
      color: isOvertime
          ? const Color(0xFFFF4444)
          : const Color(0xFFFF8800), // Red for overtime, orange for normal
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: false, // Don't show alert on iOS
      presentBadge: false,
      presentSound: false,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      999, // Fixed ID for persistent notification
      'Break Status: $breakType',
      statusText,
      platformChannelSpecifics,
      payload: json.encode({
        'type': 'break_status',
        'breakType': breakType,
        'startTime': startTime.toIso8601String(),
        'maxDurationMinutes': maxDurationMinutes,
        'totalBreaksToday': totalBreaksToday,
      }),
    );
  }

  // Cancel persistent break notification
  Future<void> cancelPersistentBreakNotification() async {
    await _localNotifications.cancel(999);
  }

  // Helper method to format time
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Helper method to format duration
  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      duration = -duration;
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final nav = GlobalNavigator.navigatorKey.currentState;
    switch (data['screen']) {
      case 'leave_management':
        nav?.pushNamed('/admin/leave_management');
        break;
      case 'leave_detail':
        // Currently no dedicated detail screen; navigate to leave_request list.
        nav?.pushNamed('/leave_request');
        break;
      default:
        nav?.pushNamed('/notification');
    }
  }

  // Save FCM token to preferences
  Future<void> _saveTokenToPrefs(String token) async {
    try {
      Logger.info(
          'FCM: Saving token to preferences: ${token.substring(0, 20)}...');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      Logger.info('FCM: Token saved successfully');
    } catch (e) {
      Logger.error('FCM: Failed to save token to preferences: $e');
    }
  }

  // Save FCM token to database
  Future<void> _saveTokenToDatabase(
      String token, String? authToken, String? userId) async {
    try {
      if (authToken == null || userId == null) {
        Logger.warning(
            'FCM: Cannot save token to database - missing auth token or user ID');
        return;
      }

      Logger.info('FCM: Saving token to database for user: $userId');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'fcmToken': token,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        Logger.info('FCM: Token saved to database successfully');
      } else {
        Logger.error(
            'FCM: Failed to save token to database. Status: ${response.statusCode}, Response: ${response.body}');
      }
    } catch (e) {
      Logger.error('FCM: Error saving token to database: $e');
    }
  }

  // Get FCM token from preferences
  Future<String?> getTokenFromPrefs() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      Logger.error('FCM: Failed to get token from preferences: $e');
      return null;
    }
  }

  // Subscribe to topics
  Future<void> subscribeToTopic(String topic) async {
    try {
      Logger.info('FCM: Attempting to subscribe to topic: $topic');
      await _firebaseMessaging.subscribeToTopic(topic);
      Logger.info('FCM: Successfully subscribed to topic: $topic');
    } catch (e) {
      Logger.error('FCM: Failed to subscribe to topic $topic: $e');
    }
  }

  // Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      Logger.info('FCM: Unsubscribed from topic: $topic');
    } catch (e) {
      Logger.error('FCM: Failed to unsubscribe from topic $topic: $e');
    }
  }

  // Subscribe user to role-based topics
  Future<void> subscribeToRoleTopics(String userRole) async {
    // Subscribe to general notifications
    await subscribeToTopic('all_users');

    // Subscribe to role-specific notifications
    if (userRole == 'admin') {
      await subscribeToTopic('admins');
    } else if (userRole == 'employee') {
      await subscribeToTopic('employees');
    }
  }

  // Method to save token to database when auth becomes available
  Future<void> saveTokenToDatabase(String authToken, String userId) async {
    if (_fcmToken != null) {
      await _saveTokenToDatabase(_fcmToken!, authToken, userId);
    } else {
      Logger.warning('FCM: No FCM token available to save to database');
    }
  }

  // Manual FCM token test method for debugging
  Future<void> testFCMTokenGeneration() async {
    try {
      Logger.info('FCM: 🔧 Manual FCM token test started...');

      // Check if Firebase is initialized
      Logger.info('FCM: Checking Firebase initialization...');

      // Try to get token directly
      Logger.info('FCM: Attempting to get FCM token...');
      final token = await _firebaseMessaging.getToken();

      if (token != null) {
        Logger.info(
            'FCM: ✅ Manual test successful! Token: ${token.substring(0, 20)}...');
        _fcmToken = token;
        await _saveTokenToPrefs(token);
      } else {
        Logger.error('FCM: ❌ Manual test failed - token is null');
      }
    } catch (e) {
      Logger.error('FCM: ❌ Manual test failed with error: $e');
      Logger.error('FCM: Error type: ${e.runtimeType}');
      Logger.error('FCM: Error details: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background handling
  await Firebase.initializeApp();

  Logger.info(
      'FCM: Background message received:  [32m [1m [4m [47m${message.messageId} [0m');

  // Handle background message data
  Logger.info('FCM: Background message data: ${message.data}');
}
