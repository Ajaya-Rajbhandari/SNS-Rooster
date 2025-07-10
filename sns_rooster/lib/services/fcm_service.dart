import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import 'dart:typed_data';

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

  Future<void> setupNotificationChannel() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  String? _fcmToken;
  bool _isInitialized = false;

  // Getter for FCM token
  String? get fcmToken => _fcmToken;

  // Initialize FCM service
  Future<void> initialize() async {
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

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      Logger.info('FCM Token:  [32m [1m [4m [47m$_fcmToken [0m');
      if (_fcmToken != null) {
        // Print the FCM token to the debug console for developer
        // (This makes it easy to copy for Firebase Console testing)
        // ignore: avoid_print
        print('==== FCM TOKEN FOR TESTING ====');
        // ignore: avoid_print
        print(_fcmToken);
        // ignore: avoid_print
        print('===============================');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        Logger.info('FCM Token refreshed: $newToken');
        _saveTokenToPrefs(newToken);
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
      Logger.info('FCM Service initialized successfully');
    } catch (e) {
      Logger.error('FCM Service initialization failed: $e');
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
  }

  // Handle notification taps
  void _handleNotificationTap(RemoteMessage message) {
    Logger.info('FCM: Notification tapped: ${message.messageId}');

    // Handle navigation based on notification data
    _handleNotificationNavigation(message.data);
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

  // Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // You can implement navigation logic here based on notification data
    // For example, navigate to specific screens based on notification type
    Logger.info('FCM: Handling navigation for data: $data');

    // Example navigation logic:
    // if (data['type'] == 'attendance') {
    //   // Navigate to attendance screen
    // } else if (data['type'] == 'leave') {
    //   // Navigate to leave screen
    // }
  }

  // Save FCM token to preferences
  Future<void> _saveTokenToPrefs(String token) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      Logger.error('FCM: Failed to save token to preferences: $e');
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
      await _firebaseMessaging.subscribeToTopic(topic);
      Logger.info('FCM: Subscribed to topic: $topic');
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
