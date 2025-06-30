import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';

class NotificationBell extends StatelessWidget {
  final Color? iconColor;
  const NotificationBell({Key? key, this.iconColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<NotificationProvider, AuthProvider>(
      builder: (context, notificationProvider, authProvider, _) {
        final unread = notificationProvider.unreadCount;
        final isAdmin = authProvider.user?['role'] == 'admin';
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.notifications, color: iconColor),
              tooltip: 'Notifications',
              onPressed: () {
                Navigator.of(context).pushNamed(
                  isAdmin ? '/admin/notification_alerts' : '/notification',
                );
              },
            ),
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unread > 99 ? '99+' : unread.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
