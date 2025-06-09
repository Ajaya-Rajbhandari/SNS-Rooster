import 'package:flutter/material.dart';

class NotificationProvider with ChangeNotifier {
  int _unreadNotifications = 0;
  int _unreadMessages = 0;

  int get unreadNotifications => _unreadNotifications;
  int get unreadMessages => _unreadMessages;

  NotificationProvider() {
    _fetchUnreadCounts();
  }

  // Mock fetching unread counts
  void _fetchUnreadCounts() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    _unreadNotifications = 3; // Mock value
    _unreadMessages = 2; // Mock value
    notifyListeners();
  }

  void markAllNotificationsAsRead() {
    _unreadNotifications = 0;
    notifyListeners();
  }

  void markAllMessagesAsRead() {
    _unreadMessages = 0;
    notifyListeners();
  }

  // You can add methods to increment/decrement counts as needed
  void incrementUnreadNotifications() {
    _unreadNotifications++;
    notifyListeners();
  }

  void decrementUnreadNotifications() {
    if (_unreadNotifications > 0) {
      _unreadNotifications--;
      notifyListeners();
    }
  }

  void incrementUnreadMessages() {
    _unreadMessages++;
    notifyListeners();
  }

  void decrementUnreadMessages() {
    if (_unreadMessages > 0) {
      _unreadMessages--;
      notifyListeners();
    }
  }
}
