import 'package:flutter/material.dart';
import '../services/global_notification_service.dart';
import 'package:provider/provider.dart';

class GlobalNotificationBanner extends StatefulWidget {
  const GlobalNotificationBanner({Key? key}) : super(key: key);

  @override
  State<GlobalNotificationBanner> createState() =>
      _GlobalNotificationBannerState();
}

class _GlobalNotificationBannerState extends State<GlobalNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final GlobalNotificationService _service;
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _service = GlobalNotificationService();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _service.addListener(_onServiceChanged);
  }

  void _onServiceChanged() {
    if (_service.isVisible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _controller.dispose();
    super.dispose();
  }

  Color _getColor(GlobalNotificationType type) {
    switch (type) {
      case GlobalNotificationType.success:
        return Colors.green.shade600;
      case GlobalNotificationType.error:
        return Colors.red.shade600;
      case GlobalNotificationType.info:
        return Colors.blue.shade600;
      case GlobalNotificationType.warning:
        return Colors.orange.shade700;
    }
  }

  IconData _getIcon(GlobalNotificationType type) {
    switch (type) {
      case GlobalNotificationType.success:
        return Icons.check_circle;
      case GlobalNotificationType.error:
        return Icons.error;
      case GlobalNotificationType.info:
        return Icons.info;
      case GlobalNotificationType.warning:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<GlobalNotificationService>(context);
    final notification = service.currentNotification;
    if (notification == null) return const SizedBox.shrink();
    final duration = notification.duration ?? const Duration(seconds: 1);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: SafeArea(
          child: Material(
            elevation: 8,
            color: Colors.transparent,
            child: Stack(
              children: [
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _getColor(notification.type),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(_getIcon(notification.type),
                          color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          notification.message,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          service.hide();
                          notification.onDismiss?.call();
                        },
                      ),
                    ],
                  ),
                ),
                // Progress bar at the top
                Positioned(
                  top: 0,
                  left: 12,
                  right: 12,
                  child: _NotificationProgressBar(
                      duration: duration, color: Colors.white.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationProgressBar extends StatefulWidget {
  final Duration duration;
  final Color color;
  const _NotificationProgressBar({required this.duration, required this.color});

  @override
  State<_NotificationProgressBar> createState() =>
      _NotificationProgressBarState();
}

class _NotificationProgressBarState extends State<_NotificationProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _NotificationProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.dispose();
      _controller = AnimationController(
        vsync: this,
        duration: widget.duration,
      )..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: 1.0 - _controller.value,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(widget.color),
          minHeight: 4,
        );
      },
    );
  }
}
