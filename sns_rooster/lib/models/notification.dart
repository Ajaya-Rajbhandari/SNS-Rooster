import 'package:flutter/material.dart';

enum NotificationType {
  leave,
  timesheet,
  announcement,
  message,
  system,
  attendance
}

enum NotificationPriority { high, medium, low }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final NotificationPriority priority;
  final String? avatar;
  final bool isRead;
  final Map<String, dynamic>?
      data; // For additional data like leave request ID, etc.

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.priority = NotificationPriority.medium,
    this.avatar,
    this.isRead = false,
    this.data,
  });

  // Helper method to get icon based on notification type
  IconData get icon {
    switch (type) {
      case NotificationType.leave:
        return Icons.event;
      case NotificationType.timesheet:
        return Icons.access_time;
      case NotificationType.announcement:
        return Icons.announcement;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.attendance:
        return Icons.check_circle_outline;
    }
  }

  // Helper method to get color based on notification type
  Color get color {
    switch (type) {
      case NotificationType.leave:
        return Colors.blue;
      case NotificationType.timesheet:
        return Colors.orange;
      case NotificationType.announcement:
        return Colors.purple;
      case NotificationType.message:
        return Colors.green;
      case NotificationType.system:
        return Colors.grey;
      case NotificationType.attendance:
        return Colors.teal;
    }
  }

  // Helper method to get formatted time
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  // Helper method to get formatted date for grouping
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
