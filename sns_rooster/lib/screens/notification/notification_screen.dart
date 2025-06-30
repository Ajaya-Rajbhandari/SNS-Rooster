// Placeholder for notification screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_drawer.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  NotificationType? _selectedType;
  NotificationPriority? _selectedPriority;
  bool? _showUnreadOnly;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch notifications when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .refreshNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedType == null,
                    onSelected: (selected) {
                      setState(() => _selectedType = null);
                    },
                  ),
                  ...NotificationType.values.map((type) => FilterChip(
                        label: Text(type.toString().split('.').last),
                        selected: _selectedType == type,
                        onSelected: (selected) {
                          setState(
                              () => _selectedType = selected ? type : null);
                        },
                      )),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Priority',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedPriority == null,
                    onSelected: (selected) {
                      setState(() => _selectedPriority = null);
                    },
                  ),
                  ...NotificationPriority.values.map((priority) => FilterChip(
                        label: Text(priority.toString().split('.').last),
                        selected: _selectedPriority == priority,
                        onSelected: (selected) {
                          setState(() =>
                              _selectedPriority = selected ? priority : null);
                        },
                      )),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _showUnreadOnly == null,
                    onSelected: (selected) {
                      setState(() => _showUnreadOnly = null);
                    },
                  ),
                  FilterChip(
                    label: const Text('Unread'),
                    selected: _showUnreadOnly == true,
                    onSelected: (selected) {
                      setState(() => _showUnreadOnly = selected ? true : null);
                    },
                  ),
                  FilterChip(
                    label: const Text('Read'),
                    selected: _showUnreadOnly == false,
                    onSelected: (selected) {
                      setState(() => _showUnreadOnly = selected ? false : null);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
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
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
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
                          _selectedType = null;
                          _selectedPriority = null;
                          _showUnreadOnly = null;
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
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu), // Hamburger icon
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Notifications'),
            Tab(text: 'Messages'),
          ],
          indicatorColor: Colors.white, // White indicator
          labelColor: Colors.white, // White label color
          unselectedLabelColor:
              Colors.white70, // Slightly transparent for unselected
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final currentTab = _tabController.index;
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'mark_all_read') {
                    if (currentTab == 0) {
                      notificationProvider.markAllNotificationsAsRead();
                    } else {
                      notificationProvider.markAllMessagesAsRead();
                    }
                  } else if (value == 'delete_all') {
                    if (currentTab == 0) {
                      notificationProvider.deleteAllNotifications();
                    } else {
                      notificationProvider.deleteAllMessages();
                    }
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'mark_all_read',
                    child: Text('Mark all as read'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete_all',
                    child: Text('Delete all'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(context), // Notifications Tab
          _buildMessageList(context), // Messages Tab
        ],
      ),
    );
  }

  Widget _buildNotificationList(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        if (notificationProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<AppNotification> filteredNotifications =
            notificationProvider.notifications.where((n) {
          bool matchesType = _selectedType == null || n.type == _selectedType;
          bool matchesPriority =
              _selectedPriority == null || n.priority == _selectedPriority;
          bool matchesReadStatus = _showUnreadOnly == null
              ? true
              : n.isRead ==
                  !_showUnreadOnly!; // if true, show unread; if false, show read
          bool matchesDate = true;
          if (_startDate != null &&
              n.timestamp.isBefore(DateTime(
                  _startDate!.year, _startDate!.month, _startDate!.day))) {
            matchesDate = false;
          }
          if (_endDate != null &&
              n.timestamp.isAfter(DateTime(_endDate!.year, _endDate!.month,
                  _endDate!.day, 23, 59, 59))) {
            matchesDate = false;
          }
          return matchesType &&
              matchesPriority &&
              matchesReadStatus &&
              matchesDate;
        }).toList();

        return filteredNotifications.isEmpty
            ? const Center(child: Text('No notifications.'))
            : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: filteredNotifications.length,
                itemBuilder: (context, index) {
                  final notification = filteredNotifications[index];
                  return NotificationCard(
                    notification: notification,
                    onDismissed: () {
                      notificationProvider.deleteNotification(notification.id);
                    },
                    onTap: () {
                      notificationProvider
                          .markNotificationAsRead(notification.id);
                      // TODO: Navigate to details or specific action
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Tapped on: ${notification.title}')),
                      );
                    },
                  );
                },
              );
      },
    );
  }

  Widget _buildMessageList(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        if (notificationProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<AppNotification> filteredMessages =
            notificationProvider.messages.where((m) {
          bool matchesType = _selectedType == null || m.type == _selectedType;
          bool matchesPriority =
              _selectedPriority == null || m.priority == _selectedPriority;
          bool matchesReadStatus =
              _showUnreadOnly == null ? true : m.isRead == !_showUnreadOnly!;
          bool matchesDate = true;
          if (_startDate != null &&
              m.timestamp.isBefore(DateTime(
                  _startDate!.year, _startDate!.month, _startDate!.day))) {
            matchesDate = false;
          }
          if (_endDate != null &&
              m.timestamp.isAfter(DateTime(_endDate!.year, _endDate!.month,
                  _endDate!.day, 23, 59, 59))) {
            matchesDate = false;
          }
          return matchesType &&
              matchesPriority &&
              matchesReadStatus &&
              matchesDate;
        }).toList();

        return filteredMessages.isEmpty
            ? const Center(child: Text('No messages.'))
            : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: filteredMessages.length,
                itemBuilder: (context, index) {
                  final message = filteredMessages[index];
                  return MessageCard(
                    message: message,
                    onDismissed: () {
                      notificationProvider.deleteMessage(message.id);
                    },
                    onTap: () {
                      notificationProvider.markMessageAsRead(message.id);
                      // TODO: Navigate to chat/message details
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Tapped on message from: ${message.title}')),
                      );
                    },
                  );
                },
              );
      },
    );
  }
}

// Move NotificationCard outside _NotificationScreenState
class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onDismissed;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onDismissed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        onDismissed();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        color: notification.isRead
            ? theme.colorScheme.surface
            : theme.colorScheme.secondary
                .withOpacity(0.05), // Subtle highlight for unread
        elevation: notification.isRead ? 2 : 4,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    notification.icon,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: notification.isRead
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          DateFormat('MMM d, y HH:mm')
                              .format(notification.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Move MessageCard outside _NotificationScreenState
class MessageCard extends StatelessWidget {
  final AppNotification message;
  final VoidCallback onDismissed;
  final VoidCallback onTap;

  const MessageCard({
    super.key,
    required this.message,
    required this.onDismissed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme
    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        onDismissed();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        color: message.isRead
            ? theme.colorScheme.surface
            : theme.colorScheme.surface.withOpacity(
                0.9), // Keep consistent with NotificationCard for unread
        elevation: message.isRead ? 2 : 4,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage:
                      message.avatar != null && message.avatar!.isNotEmpty
                          ? AssetImage(message.avatar!) as ImageProvider
                          : null,
                  child: message.avatar == null || message.avatar!.isEmpty
                      ? const Icon(Icons.person, size: 28)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: message.isRead
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          DateFormat('MMM d, y HH:mm')
                              .format(message.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
            primary: Theme.of(context).primaryColor,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              textStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      );
    },
  );
}
