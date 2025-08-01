// Placeholder for notification screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/global_notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String? _selectedStatus; // 'all', 'unread', 'read'
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Notifications',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedStatus == null,
                    onSelected: (selected) =>
                        setState(() => _selectedStatus = null),
                  ),
                  FilterChip(
                    label: const Text('Unread'),
                    selected: _selectedStatus == 'unread',
                    onSelected: (selected) => setState(
                        () => _selectedStatus = selected ? 'unread' : null),
                  ),
                  FilterChip(
                    label: const Text('Read'),
                    selected: _selectedStatus == 'read',
                    onSelected: (selected) => setState(
                        () => _selectedStatus = selected ? 'read' : null),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Date Range',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_startDate == null
                          ? 'Start Date'
                          : DateFormat('MMM d, y').format(_startDate!)),
                      onPressed: () async {
                        final date = await showCustomDatePicker(
                            context, _startDate ?? DateTime.now());
                        if (date != null) setState(() => _startDate = date);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_endDate == null
                          ? 'End Date'
                          : DateFormat('MMM d, y').format(_endDate!)),
                      onPressed: () async {
                        final date = await showCustomDatePicker(
                            context, _endDate ?? DateTime.now());
                        if (date != null) setState(() => _endDate = date);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedStatus = null;
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        this.setState(() {});
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
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
                final notificationService =
                    Provider.of<GlobalNotificationService>(context,
                        listen: false);
                notificationService
                    .showSuccess('All notifications marked as read.');
              } else {
                final notificationService =
                    Provider.of<GlobalNotificationService>(context,
                        listen: false);
                notificationService
                    .showError('Failed to mark all as read: ${response.body}');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false)
                  .fetchNotifications();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear All',
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final token = authProvider.token;
              if (token == null) return;
              final url =
                  Uri.parse('${ApiConfig.baseUrl}/notifications/clear-all');
              final response = await http.delete(url, headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              });
              if (response.statusCode == 200) {
                Provider.of<NotificationProvider>(context, listen: false)
                    .fetchNotifications();
                final notificationService =
                    Provider.of<GlobalNotificationService>(context,
                        listen: false);
                notificationService.showSuccess('All notifications cleared.');
              } else {
                final notificationService =
                    Provider.of<GlobalNotificationService>(context,
                        listen: false);
                notificationService.showError(
                    'Failed to clear notifications: ${response.body}');
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
              child: Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  if (notificationProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  List<Map<String, dynamic>> filteredNotifications =
                      notificationProvider.notifications.where((n) {
                    bool matchesStatus = _selectedStatus == null
                        ? true
                        : _selectedStatus == 'unread'
                            ? n['isRead'] == false
                            : n['isRead'] == true;
                    bool matchesDate = true;
                    if (_startDate != null && n['createdAt'] != null) {
                      final created = DateTime.tryParse(n['createdAt'] ?? '') ??
                          DateTime(2000);
                      if (created.isBefore(DateTime(_startDate!.year,
                          _startDate!.month, _startDate!.day))) {
                        matchesDate = false;
                      }
                    }
                    if (_endDate != null && n['createdAt'] != null) {
                      final created = DateTime.tryParse(n['createdAt'] ?? '') ??
                          DateTime(2100);
                      if (created.isAfter(DateTime(_endDate!.year,
                          _endDate!.month, _endDate!.day, 23, 59, 59))) {
                        matchesDate = false;
                      }
                    }
                    return matchesStatus && matchesDate;
                  }).toList();
                  final userRole =
                      Provider.of<AuthProvider>(context, listen: false)
                          .user?['role'];
                  filteredNotifications = filteredNotifications.where((n) {
                    // Hide admin-only notifications for non-admins
                    if (userRole != 'admin' && n['role'] == 'admin') {
                      return false;
                    }
                    // Hide 'Incomplete Employee Profile' for non-admins
                    if (userRole != 'admin' &&
                        n['title'] == 'Incomplete Employee Profile') {
                      return false;
                    }
                    return true;
                  }).toList();
                  return filteredNotifications.isEmpty
                      ? const Center(child: Text('No notifications.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = filteredNotifications[index];
                            return Dismissible(
                              key: Key(notification['_id']),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (direction) async {
                                final authProvider = Provider.of<AuthProvider>(
                                    context,
                                    listen: false);
                                final token = authProvider.token;
                                final url = Uri.parse(
                                    '${ApiConfig.baseUrl}/notifications/${notification['_id']}');
                                final response =
                                    await http.delete(url, headers: {
                                  'Content-Type': 'application/json',
                                  'Authorization': 'Bearer $token',
                                });
                                if (response.statusCode == 200) {
                                  Provider.of<NotificationProvider>(context,
                                          listen: false)
                                      .fetchNotifications();
                                  final notificationService =
                                      Provider.of<GlobalNotificationService>(
                                          context,
                                          listen: false);
                                  notificationService
                                      .showSuccess('Notification deleted.');
                                } else {
                                  final notificationService =
                                      Provider.of<GlobalNotificationService>(
                                          context,
                                          listen: false);
                                  notificationService.showError(
                                      'Failed to delete notification: ${response.body}');
                                }
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 8.0),
                                color: notification['isRead'] == true
                                    ? theme.colorScheme.surface
                                    : theme.colorScheme.secondary
                                        .withValues(alpha: 0.05),
                                elevation:
                                    notification['isRead'] == true ? 2 : 4,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    child: const Icon(Icons.notifications),
                                  ),
                                  title: Text(
                                    notification['title'] ?? '',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: notification['isRead'] == true
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification['message'] ?? '',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Text(
                                          notification['createdAt'] != null
                                              ? DateFormat('MMM d, y HH:mm')
                                                  .format(DateTime.tryParse(
                                                          notification[
                                                              'createdAt']) ??
                                                      DateTime.now())
                                              : '',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: notification['isRead'] == false
                                      ? IconButton(
                                          icon:
                                              const Icon(Icons.mark_email_read),
                                          tooltip: 'Mark as read',
                                          onPressed: () {
                                            Provider.of<NotificationProvider>(
                                                    context,
                                                    listen: false)
                                                .markAsRead(
                                                    notification['_id']);
                                          },
                                        )
                                      : null,
                                  onTap: () {
                                    if (notification['isRead'] == false) {
                                      Provider.of<NotificationProvider>(context,
                                              listen: false)
                                          .markAsRead(notification['_id']);
                                    }
                                    // Only navigate for actionable types
                                    final actionableTypes = [
                                      'leave',
                                      'timesheet',
                                      'action',
                                      'payroll'
                                    ];
                                    if (actionableTypes
                                            .contains(notification['type']) &&
                                        notification['link'] != null &&
                                        notification['link'].isNotEmpty) {
                                      Navigator.of(context)
                                          .pushNamed(notification['link']);
                                    }
                                    // else: do nothing (just mark as read)
                                  },
                                ),
                              ),
                            );
                          },
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<DateTime?> showCustomDatePicker(
    BuildContext context, DateTime initialDate,
    {DateTime? firstDate, DateTime? lastDate}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(2020),
    lastDate: lastDate ?? DateTime.now(),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
          ),
        ),
        child: child!,
      );
    },
  );
}
