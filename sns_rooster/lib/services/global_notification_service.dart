import 'package:flutter/material.dart';

enum GlobalNotificationType {
  success,
  error,
  info,
  warning,
}

class GlobalNotificationData {
  final String message;
  final GlobalNotificationType type;
  final Duration? duration;
  final VoidCallback? onDismiss;

  GlobalNotificationData({
    required this.message,
    required this.type,
    this.duration,
    this.onDismiss,
  });
}

class GlobalNotificationService extends ChangeNotifier {
  static final GlobalNotificationService _instance =
      GlobalNotificationService._internal();
  factory GlobalNotificationService() => _instance;
  GlobalNotificationService._internal();

  GlobalNotificationData? _currentNotification;
  bool _isVisible = false;

  GlobalNotificationData? get currentNotification => _currentNotification;
  bool get isVisible => _isVisible;

  void show({
    required String message,
    required GlobalNotificationType type,
    Duration? duration,
    VoidCallback? onDismiss,
  }) {
    _currentNotification = GlobalNotificationData(
      message: message,
      type: type,
      duration: duration ?? const Duration(seconds: 2),
      onDismiss: onDismiss,
    );
    _isVisible = true;
    notifyListeners();

    // Auto-dismiss after duration
    final effectiveDuration = duration ?? const Duration(seconds: 2);
    Future.delayed(effectiveDuration, () {
      if (_currentNotification == _currentNotification) {
        hide();
      }
    });
  }

  void showSuccess(String message,
      {Duration? duration, VoidCallback? onDismiss}) {
    show(
      message: message,
      type: GlobalNotificationType.success,
      duration: duration ?? const Duration(seconds: 2),
      onDismiss: onDismiss,
    );
  }

  void showError(String message,
      {Duration? duration, VoidCallback? onDismiss}) {
    print('DEBUG: showError called with message: $message');
    show(
      message: message,
      type: GlobalNotificationType.error,
      duration: duration ?? const Duration(seconds: 3),
      onDismiss: onDismiss,
    );
  }

  void showInfo(String message, {Duration? duration, VoidCallback? onDismiss}) {
    show(
      message: message,
      type: GlobalNotificationType.info,
      duration: duration ?? const Duration(seconds: 2),
      onDismiss: onDismiss,
    );
  }

  void showWarning(String message,
      {Duration? duration, VoidCallback? onDismiss}) {
    show(
      message: message,
      type: GlobalNotificationType.warning,
      duration: duration ?? const Duration(seconds: 2),
      onDismiss: onDismiss,
    );
  }

  void hide() {
    _isVisible = false;
    notifyListeners();

    // Clear notification data after animation
    Future.delayed(const Duration(milliseconds: 300), () {
      _currentNotification = null;
      notifyListeners();
    });
  }
}
