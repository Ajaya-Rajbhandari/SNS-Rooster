import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  List<AppNotification> _messages = [];
  bool _isLoading = false;
  static const String _notificationsKey = 'notifications';
  static const String _messagesKey = 'messages';

  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get messages => _messages;
  bool get isLoading => _isLoading;

  int get unreadNotifications => _notifications.where((n) => !n.isRead).length;
  int get unreadMessages => _messages.where((m) => !m.isRead).length;

  NotificationProvider() {
    _loadStoredNotifications();
  }

  Future<void> _loadStoredNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load notifications
      final notificationsJson = prefs.getString(_notificationsKey);
      if (notificationsJson != null) {
        final List<dynamic> decoded = json.decode(notificationsJson);
        _notifications = decoded
            .map((item) => AppNotification(
                  id: item['id'],
                  title: item['title'],
                  message: item['message'],
                  timestamp: DateTime.parse(item['timestamp']),
                  type: NotificationType.values.firstWhere(
                    (e) => e.toString() == item['type'],
                    orElse: () => NotificationType.system,
                  ),
                  priority: NotificationPriority.values.firstWhere(
                    (e) => e.toString() == item['priority'],
                    orElse: () => NotificationPriority.medium,
                  ),
                  avatar: item['avatar'],
                  isRead: item['isRead'] ?? false,
                  data: item['data'],
                ))
            .toList();
      }

      // Load messages
      final messagesJson = prefs.getString(_messagesKey);
      if (messagesJson != null) {
        final List<dynamic> decoded = json.decode(messagesJson);
        _messages = decoded
            .map((item) => AppNotification(
                  id: item['id'],
                  title: item['title'],
                  message: item['message'],
                  timestamp: DateTime.parse(item['timestamp']),
                  type: NotificationType.values.firstWhere(
                    (e) => e.toString() == item['type'],
                    orElse: () => NotificationType.system,
                  ),
                  priority: NotificationPriority.values.firstWhere(
                    (e) => e.toString() == item['priority'],
                    orElse: () => NotificationPriority.medium,
                  ),
                  avatar: item['avatar'],
                  isRead: item['isRead'] ?? false,
                  data: item['data'],
                ))
            .toList();
      }

      // If no stored data, fetch from API
      if (_notifications.isEmpty && _messages.isEmpty) {
        await _fetchNotifications();
      }
    } catch (e) {
      print('Error loading notifications: $e');
      await _fetchNotifications();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save notifications
      final notificationsJson = json.encode(_notifications
          .map((n) => {
                'id': n.id,
                'title': n.title,
                'message': n.message,
                'timestamp': n.timestamp.toIso8601String(),
                'type': n.type.toString(),
                'priority': n.priority.toString(),
                'avatar': n.avatar,
                'isRead': n.isRead,
                'data': n.data,
              })
          .toList());
      await prefs.setString(_notificationsKey, notificationsJson);

      // Save messages
      final messagesJson = json.encode(_messages
          .map((m) => {
                'id': m.id,
                'title': m.title,
                'message': m.message,
                'timestamp': m.timestamp.toIso8601String(),
                'type': m.type.toString(),
                'priority': m.priority.toString(),
                'avatar': m.avatar,
                'isRead': m.isRead,
                'data': m.data,
              })
          .toList());
      await prefs.setString(_messagesKey, messagesJson);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  Future<void> _fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Mock data
    _notifications = [
      AppNotification(
        id: '1',
        title: 'New Leave Request Approved',
        message: 'Your leave request for October 26, 2023 has been approved.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.leave,
        priority: NotificationPriority.high,
        avatar: 'assets/images/profile_placeholder.png',
        data: {'leaveRequestId': '123'},
      ),
      AppNotification(
        id: '2',
        title: 'Timesheet Reminder',
        message: 'Don\'t forget to submit your timesheet for this week.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.timesheet,
        priority: NotificationPriority.medium,
      ),
      AppNotification(
        id: '3',
        title: 'Company Announcement: Holiday Schedule',
        message:
            'Please review the updated holiday schedule for the upcoming year.',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        type: NotificationType.announcement,
        priority: NotificationPriority.high,
      ),
    ];

    _messages = [
      AppNotification(
        id: 'm1',
        title: 'HR Department',
        message: 'Your leave request has been processed.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: NotificationType.message,
        avatar: 'assets/images/profile_placeholder.png',
      ),
      AppNotification(
        id: 'm2',
        title: 'System',
        message: 'Your password has been changed successfully.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.system,
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    await _fetchNotifications();
    await _saveNotifications();
  }

  void markNotificationAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = AppNotification(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        timestamp: _notifications[index].timestamp,
        type: _notifications[index].type,
        priority: _notifications[index].priority,
        avatar: _notifications[index].avatar,
        isRead: true,
        data: _notifications[index].data,
      );
      _saveNotifications();
      notifyListeners();
    }
  }

  void markMessageAsRead(String id) {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index != -1) {
      _messages[index] = AppNotification(
        id: _messages[index].id,
        title: _messages[index].title,
        message: _messages[index].message,
        timestamp: _messages[index].timestamp,
        type: _messages[index].type,
        priority: _messages[index].priority,
        avatar: _messages[index].avatar,
        isRead: true,
        data: _messages[index].data,
      );
      _saveNotifications();
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    _notifications = _notifications
        .map((notification) => AppNotification(
              id: notification.id,
              title: notification.title,
              message: notification.message,
              timestamp: notification.timestamp,
              type: notification.type,
              priority: notification.priority,
              avatar: notification.avatar,
              isRead: true,
              data: notification.data,
            ))
        .toList();
    _saveNotifications();
    notifyListeners();
  }

  void markAllMessagesAsRead() {
    _messages = _messages
        .map((message) => AppNotification(
              id: message.id,
              title: message.title,
              message: message.message,
              timestamp: message.timestamp,
              type: message.type,
              priority: message.priority,
              avatar: message.avatar,
              isRead: true,
              data: message.data,
            ))
        .toList();
    _saveNotifications();
    notifyListeners();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _saveNotifications();
    notifyListeners();
  }

  void deleteMessage(String id) {
    _messages.removeWhere((m) => m.id == id);
    _saveNotifications();
    notifyListeners();
  }

  void deleteAllNotifications() {
    _notifications.clear();
    _saveNotifications();
    notifyListeners();
  }

  void deleteAllMessages() {
    _messages.clear();
    _saveNotifications();
    notifyListeners();
  }

  // Add filter methods
  List<AppNotification> getFilteredNotifications({
    NotificationType? type,
    NotificationPriority? priority,
    bool? isRead,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _notifications.where((notification) {
      if (type != null && notification.type != type) return false;
      if (priority != null && notification.priority != priority) return false;
      if (isRead != null && notification.isRead != isRead) return false;
      if (startDate != null && notification.timestamp.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && notification.timestamp.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();
  }

  // Group notifications by date with filters
  Map<String, List<AppNotification>> getGroupedNotifications({
    NotificationType? type,
    NotificationPriority? priority,
    bool? isRead,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final filteredNotifications = getFilteredNotifications(
      type: type,
      priority: priority,
      isRead: isRead,
      startDate: startDate,
      endDate: endDate,
    );

    final grouped = <String, List<AppNotification>>{};
    for (var notification in filteredNotifications) {
      final date = notification.formattedDate;
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(notification);
    }
    return Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) {
          if (a.key == 'Today') return -1;
          if (b.key == 'Today') return 1;
          if (a.key == 'Yesterday') return -1;
          if (b.key == 'Yesterday') return 1;
          return b.key.compareTo(a.key);
        }),
    );
  }
}
