import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/admin_side_navigation.dart';
import '../../providers/notification_provider.dart';
import 'package:intl/intl.dart';

class NotificationAlertScreen extends StatefulWidget {
  const NotificationAlertScreen({super.key});

  @override
  State<NotificationAlertScreen> createState() =>
      _NotificationAlertScreenState();
}

class _NotificationAlertScreenState extends State<NotificationAlertScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      drawer: const AdminSideNavigation(currentRoute: '/notification_alerts'),
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false)
                  .fetchNotifications();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            if (notificationProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final notifications = notificationProvider.notifications;
            if (notifications.isEmpty) {
              return Center(
                child:
                    Text('No notifications.', style: theme.textTheme.bodyLarge),
              );
            }
            return ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final n = notifications[index];
                final isUnread = n['isRead'] == false;
                return Card(
                  color: isUnread ? Colors.blue[50] : theme.colorScheme.surface,
                  elevation: isUnread ? 4 : 2,
                  child: ListTile(
                    leading: Icon(
                      n['type'] == 'alert'
                          ? Icons.warning
                          : Icons.notifications,
                      color: n['type'] == 'alert'
                          ? Colors.red
                          : theme.colorScheme.primary,
                    ),
                    title: Text(
                      n['title'] ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isUnread ? theme.colorScheme.primary : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n['message'] ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          n['createdAt'] != null
                              ? DateFormat('MMM d, y HH:mm').format(
                                  DateTime.tryParse(n['createdAt']) ??
                                      DateTime.now())
                              : '',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ],
                    ),
                    trailing: isUnread
                        ? IconButton(
                            icon: const Icon(Icons.mark_email_read),
                            tooltip: 'Mark as read',
                            onPressed: () {
                              Provider.of<NotificationProvider>(context,
                                      listen: false)
                                  .markAsRead(n['_id']);
                            },
                          )
                        : null,
                    onTap: () {
                      if (isUnread) {
                        Provider.of<NotificationProvider>(context,
                                listen: false)
                            .markAsRead(n['_id']);
                      }
                      final link = n['link'];
                      if (link != null && link.isNotEmpty) {
                        Navigator.of(context).pushNamed(link);
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
