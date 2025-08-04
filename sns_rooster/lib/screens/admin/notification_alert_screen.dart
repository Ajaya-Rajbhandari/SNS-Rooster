import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/admin_side_navigation.dart';
import '../../providers/notification_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';

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
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark All as Read',
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final token = authProvider.token;
              if (token == null) return;
              final url =
                  Uri.parse('${ApiConfig.baseUrl}/notifications/mark-all-read');
              final response = await http.patch(url, headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              });
              if (response.statusCode == 200) {
                Provider.of<NotificationProvider>(context, listen: false)
                    .fetchNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('All notifications marked as read.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Failed to mark all as read: ${response.body}')),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false)
                  .fetchNotifications();
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: 'Clear All',
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final token = authProvider.token;
              if (token == null) return;
              final url = Uri.parse('${ApiConfig.baseUrl}/notifications');
              final response = await http.delete(url, headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              });
              if (response.statusCode == 200) {
                Provider.of<NotificationProvider>(context, listen: false)
                    .fetchNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications cleared.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Failed to clear notifications: ${response.body}')),
                );
              }
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
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final userId = authProvider.user?['_id'];
            final notifications = notificationProvider.notifications.where((n) {
              final isForAdminRole = n['role'] == 'admin';
              final isBroadcast = n['role'] == 'all';
              final isForThisAdmin = n['user'] == userId;
              return isForAdminRole || isBroadcast || isForThisAdmin;
            }).toList();
            if (notifications.isEmpty) {
              return Center(
                child:
                    Text('No notifications.', style: theme.textTheme.bodyLarge),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: 'Swipe left on a notification to delete it.',
                  child: Row(
                    children: [
                      Icon(Icons.swipe_left, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Tip: Swipe left to delete a notification',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      final isUnread = n['isRead'] == false;
                      return Dismissible(
                        key: Key(n['_id']),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Icon(Icons.delete,
                              color: theme.colorScheme.onPrimary),
                        ),
                        onDismissed: (direction) async {
                          final authProvider =
                              Provider.of<AuthProvider>(context, listen: false);
                          final token = authProvider.token;
                          final url = Uri.parse(
                              '${ApiConfig.baseUrl}/notifications/${n['_id']}');
                          final response = await http.delete(url, headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          });
                          if (response.statusCode == 200) {
                            Provider.of<NotificationProvider>(context,
                                    listen: false)
                                .fetchNotifications();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Notification deleted.')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Failed to delete notification: \\${response.body}')),
                            );
                          }
                        },
                        child: Card(
                          color: isUnread
                              ? theme.colorScheme.primary
                                  .withValues(alpha: 0.08)
                              : theme.colorScheme.surface,
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
                                color:
                                    isUnread ? theme.colorScheme.primary : null,
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
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6)),
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
                              // Only navigate for actionable types
                              final actionableTypes = [
                                'leave',
                                'timesheet',
                                'action'
                              ];
                              if (actionableTypes.contains(n['type']) &&
                                  n['link'] != null &&
                                  n['link'].isNotEmpty) {
                                Navigator.of(context).pushNamed(n['link']);
                              }
                              // else: do nothing (just mark as read)
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
