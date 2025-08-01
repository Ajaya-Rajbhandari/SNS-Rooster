import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService notificationService;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  NotificationProvider(this.notificationService);

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await notificationService.fetchNotifications();
      _unreadCount = await notificationService.getUnreadCount();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await notificationService.markAsRead(notificationId);
      final idx = _notifications.indexWhere((n) => n['_id'] == notificationId);
      if (idx != -1) {
        _notifications[idx]['isRead'] = true;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await notificationService.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }
}
