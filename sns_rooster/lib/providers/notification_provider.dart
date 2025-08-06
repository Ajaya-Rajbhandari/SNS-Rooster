import 'package:flutter/material.dart';
import '../services/notification_api_service.dart';
import '../providers/auth_provider.dart';
import '../utils/logger.dart';

class NotificationProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  late final NotificationApiService _notificationService;

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;
  int _currentPage = 1;
  bool _hasMore = true;

  NotificationProvider(this._authProvider) {
    _notificationService = NotificationApiService(_authProvider);
  }

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  bool get hasMore => _hasMore;

  // Fetch notifications
  Future<void> fetchNotifications({bool refresh = false}) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (refresh) {
        _currentPage = 1;
        _notifications = [];
        _hasMore = true;
      }

      final response = await _notificationService.getNotifications(
        page: _currentPage,
        limit: 20,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final newNotifications =
            List<Map<String, dynamic>>.from(data['notifications'] ?? []);

        if (refresh) {
          _notifications = newNotifications;
        } else {
          _notifications.addAll(newNotifications);
        }

        _unreadCount = data['unreadCount'] ?? 0;
        _hasMore = data['pagination']['page'] < data['pagination']['pages'];
        _currentPage++;
      } else {
        _error = response['message'] ?? 'Failed to fetch notifications';
      }
    } catch (e) {
      log('Error fetching notifications: $e');
      _error = 'Failed to fetch notifications';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await _notificationService.markAsRead(notificationId);

      if (response['success'] == true) {
        // Update the notification in the list
        final index =
            _notifications.indexWhere((n) => n['_id'] == notificationId);
        if (index != -1) {
          _notifications[index]['readStatus'] = true;
          _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
          notifyListeners();
        }
      } else {
        log('Failed to mark notification as read: ${response['message']}');
      }
    } catch (e) {
      log('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final response = await _notificationService.markAllAsRead();

      if (response['success'] == true) {
        // Update all notifications in the list
        for (var notification in _notifications) {
          notification['readStatus'] = true;
        }
        _unreadCount = 0;
        notifyListeners();
      } else {
        log('Failed to mark all notifications as read: ${response['message']}');
      }
    } catch (e) {
      log('Error marking all notifications as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final response =
          await _notificationService.deleteNotification(notificationId);

      if (response['success'] == true) {
        // Remove the notification from the list
        _notifications.removeWhere((n) => n['_id'] == notificationId);

        // Recalculate unread count
        _unreadCount =
            _notifications.where((n) => n['readStatus'] == false).length;
        notifyListeners();
      } else {
        log('Failed to delete notification: ${response['message']}');
      }
    } catch (e) {
      log('Error deleting notification: $e');
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      final response = await _notificationService.deleteAllNotifications();

      if (response['success'] == true) {
        _notifications.clear();
        _unreadCount = 0;
        _currentPage = 1;
        _hasMore = true;
        notifyListeners();
      } else {
        log('Failed to delete all notifications: ${response['message']}');
      }
    } catch (e) {
      log('Error deleting all notifications: $e');
    }
  }

  // Add a new notification (for real-time updates)
  void addNotification(Map<String, dynamic> notification) {
    _notifications.insert(0, notification);
    if (notification['readStatus'] == false) {
      _unreadCount++;
    }
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

}
