import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/logger.dart';
import '../providers/auth_provider.dart';

class NotificationApiService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthProvider _authProvider;

  NotificationApiService(this._authProvider);

  // Get notifications for current user
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/notifications?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        log('Error fetching notifications: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch notifications');
      }
    } catch (e) {
      log('Exception in getNotifications: $e');
      rethrow;
    }
  }

  // Mark notification as read
  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        log('Error marking notification as read: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      log('Exception in markAsRead: $e');
      rethrow;
    }
  }

  // Mark all notifications as read
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        log('Error marking all notifications as read: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to mark all notifications as read');
      }
    } catch (e) {
      log('Exception in markAllAsRead: $e');
      rethrow;
    }
  }

  // Delete a notification
  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        log('Error deleting notification: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to delete notification');
      }
    } catch (e) {
      log('Exception in deleteNotification: $e');
      rethrow;
    }
  }

  // Delete all notifications
  Future<Map<String, dynamic>> deleteAllNotifications() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        log('Error deleting all notifications: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to delete all notifications');
      }
    } catch (e) {
      log('Exception in deleteAllNotifications: $e');
      rethrow;
    }
  }
}
