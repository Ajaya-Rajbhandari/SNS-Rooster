import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import '../utils/logger.dart';
import 'privacy_service.dart';

class NotificationService {
  final AuthProvider authProvider;
  final PrivacyService _privacyService = PrivacyService.instance;

  NotificationService(this.authProvider);

  /// Check if notifications should be sent (respects privacy settings)
  Future<bool> shouldSendNotification() async {
    try {
      return await _privacyService.shouldAllowNotifications();
    } catch (e) {
      Logger.error('Error checking notification privacy setting: $e');
      return true; // Default to allowed if error
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    try {
      // Check privacy settings first
      if (!await shouldSendNotification()) {
        Logger.info('Notifications blocked by privacy settings');
        return [];
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notifications/simple'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
          'x-company-id': authProvider.user?['companyId'] ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Log analytics event if enabled
        await _privacyService
            .logAnalyticsEvent('notifications_fetched', parameters: {
          'count': (data['notifications'] as List).length,
        });

        return List<Map<String, dynamic>>.from(data['notifications']);
      } else {
        throw Exception('Failed to fetch notifications');
      }
    } catch (e) {
      Logger.error('Error fetching notifications: $e');
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      // Check privacy settings first
      if (!await shouldSendNotification()) {
        Logger.info('Notification count blocked by privacy settings');
        return 0;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notifications/simple/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
          'x-company-id': authProvider.user?['companyId'] ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final count = data['count'] ?? 0;

        // Log analytics event if enabled
        await _privacyService
            .logAnalyticsEvent('unread_count_checked', parameters: {
          'count': count,
        });

        return count;
      } else {
        throw Exception('Failed to fetch unread count');
      }
    } catch (e) {
      Logger.error('Error getting unread count: $e');
      return 0;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      // Check privacy settings first
      if (!await shouldSendNotification()) {
        Logger.info('Mark as read blocked by privacy settings');
        return;
      }

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        // Log analytics event if enabled
        await _privacyService
            .logAnalyticsEvent('notification_marked_read', parameters: {
          'notificationId': notificationId,
        });
      } else {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      Logger.error('Error marking notification as read: $e');
    }
  }

  /// Send a local notification (respects privacy settings)
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // Check privacy settings first
      if (!await shouldSendNotification()) {
        Logger.info('Local notification blocked by privacy settings: $title');
        return;
      }

      // TODO: Implement local notification sending
      Logger.info('Local notification would be sent: $title - $body');

      // Log analytics event if enabled
      await _privacyService
          .logAnalyticsEvent('local_notification_sent', parameters: {
        'title': title,
        'body': body,
        'payload': payload,
      });
    } catch (e) {
      Logger.error('Error sending local notification: $e');
    }
  }

  /// Send a push notification (respects privacy settings)
  Future<void> sendPushNotification({
    required String title,
    required String body,
    String? data,
  }) async {
    try {
      // Check privacy settings first
      if (!await shouldSendNotification()) {
        Logger.info('Push notification blocked by privacy settings: $title');
        return;
      }

      // TODO: Implement push notification sending
      Logger.info('Push notification would be sent: $title - $body');

      // Log analytics event if enabled
      await _privacyService
          .logAnalyticsEvent('push_notification_sent', parameters: {
        'title': title,
        'body': body,
        'data': data,
      });
    } catch (e) {
      Logger.error('Error sending push notification: $e');
    }
  }
}
