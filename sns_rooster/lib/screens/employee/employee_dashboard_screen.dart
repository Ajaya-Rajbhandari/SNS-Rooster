// EmployeeDashboardScreen
// ----------------------
// Main dashboard for employees.
// - Shows user info, live clock, status, quick actions, and attendance summary.
// - All data is dynamic and ready for backend integration.
// - Modular: uses widgets from widgets/dashboard/ and models/services.
//
// To connect to backend, use AttendanceService and Employee model.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../widgets/user_avatar.dart';
import '../../services/attendance_service.dart';
import 'live_clock.dart';
import 'package:sns_rooster/utils/color_utils.dart';
import '../../widgets/admin_side_navigation.dart';
import '../../widgets/notification_bell.dart';
import '../../providers/notification_provider.dart';
import '../../services/global_notification_service.dart';
import 'employee_events_screen.dart';

/// Helper function to format duration in a human-readable format
/// Shows hours and minutes when duration is over 60 minutes
String _formatDuration(Duration duration) {
  final totalMinutes = duration.inMinutes;
  if (totalMinutes >= 60) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  } else {
    return '${totalMinutes}m';
  }
}

/// EmployeeDashboardScreen displays the main dashboard for employees.
//
/// - Shows user info, live clock, status, quick actions, and attendance summary.
/// - Fetches backend data only on load, after check-in/out, or on user action.
/// - Uses [LiveClock] widget to update the clock every second without rebuilding the parent widget tree.
class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen>
    with RouteAware {
  bool _isOnBreak = false;
  bool _profileDialogShown = false;
  List<Map<String, dynamic>> _upcomingEvents = [];
  bool _eventsLoading = false;

  RouteObserver<ModalRoute<void>>? _routeObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver =
        Provider.of<RouteObserver<ModalRoute<void>>>(context, listen: false);
    _routeObserver?.subscribe(this, ModalRoute.of(context)!);
    try {
      Provider.of<ProfileProvider>(context, listen: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkProfileCompletion();
        // Remove repeated attendance fetch here to prevent loop
      });
    } catch (e) {
      print(
          'ERROR: ProfileProvider is not accessible in EmployeeDashboardScreen: $e');
    }
    // Remove repeated attendance fetch here to prevent loop
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // Called when coming back to this screen
    // Refresh profile data when returning to check completion status
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.refreshProfile().then((_) {
      // Only check profile completion, don't reset the dialog flag
      _checkProfileCompletion();
    });
    setState(() {});
  }

  void _checkProfileCompletion() {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final profile = profileProvider.profile;
    if (profile != null &&
        profile['isProfileComplete'] == false &&
        !_profileDialogShown) {
      setState(() {
        _profileDialogShown = true;
      });
      // Delay the dialog until after the first frame to ensure the latest profile is shown
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Complete Your Profile'),
            content: const Text(
                'For your safety and to access all features, please complete your profile information.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Don't reset the flag when dismissing
                },
                child: const Text('Dismiss'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushNamed('/profile').then((_) {
                    // Reset the flag when returning from profile screen
                    // so dialog can show again if profile is still incomplete
                    _profileDialogShown = false;
                  });
                },
                child: const Text('Update Now'),
              ),
            ],
          ),
        );
      });
    }
  }

  void _clockIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?['_id'];
    if (userId == null) {
      final notificationService =
          Provider.of<GlobalNotificationService>(context, listen: false);
      notificationService.showError('User not logged in. Please log in again.');
      return;
    }
    try {
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final attendanceService = AttendanceService(authProvider);
      await attendanceService.checkIn(userId);
      await attendanceProvider.fetchTodayStatus(userId);
      // Note: fetchTodayStatus now also fetches currentAttendance data
      final notificationService =
          Provider.of<GlobalNotificationService>(context, listen: false);
      notificationService.showSuccess('Clocked in successfully!');
    } catch (e) {
      String errorMessage = 'An error occurred while clocking in.';
      if (e.toString().contains('Already checked in for today')) {
        errorMessage = 'You have already clocked in for today.';
      } else if (e.toString().contains('E11000 duplicate key error')) {
        errorMessage =
            'A duplicate entry was detected. You might have already checked in.';
      }
      final notificationService =
          Provider.of<GlobalNotificationService>(context, listen: false);
      notificationService.showError(errorMessage);
    }
  }

  void _clockOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?['_id'];
    if (userId != null) {
      try {
        final attendanceProvider =
            Provider.of<AttendanceProvider>(context, listen: false);
        final attendanceService = AttendanceService(authProvider);
        await attendanceService.checkOut(userId);
        await attendanceProvider.fetchTodayStatus(userId);
        // Note: fetchTodayStatus now also fetches currentAttendance data
        final notificationService =
            Provider.of<GlobalNotificationService>(context, listen: false);
        notificationService.showSuccess('Clocked out successfully!');
      } catch (e) {
        final notificationService =
            Provider.of<GlobalNotificationService>(context, listen: false);
        notificationService.showError('Failed to clock out: ${e.toString()}');
      }
    }
  }

  Future<void> _startBreak() async {
    final selected = await _showBreakTypeSelectionDialog();
    if (selected == null) return;
    final uid = context.read<AuthProvider>().user!['_id'] as String;
    await context.read<AttendanceProvider>().startBreakWithType(uid, selected);
    await context.read<AttendanceProvider>().fetchTodayStatus(uid);
    setState(() {
      _isOnBreak = true;
    });
  }

  Future<Map<String, dynamic>?> _showBreakTypeSelectionDialog() async {
    // Fetch available break types
    final breakTypes = await _fetchBreakTypes();
    if (breakTypes.isEmpty) {
      final notificationService =
          Provider.of<GlobalNotificationService>(context, listen: false);
      notificationService.showWarning('No break types available');
      return null;
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Break Type'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: breakTypes.length,
              itemBuilder: (context, index) {
                final breakType = breakTypes[index];
                String durationText = '';
                final min = breakType['minDuration'];
                final max = breakType['maxDuration'];
                if (min != null && max != null) {
                  durationText = 'Duration: $min–$max min';
                } else if (max != null) {
                  durationText = 'Duration: up to $max min';
                } else if (min != null) {
                  durationText = 'Duration: at least $min min';
                }
                return ListTile(
                  leading: Icon(
                    _getIconFromString(breakType['icon']),
                    color: colorFromHex(breakType['color']),
                  ),
                  title: Text(breakType['displayName']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(breakType['description'] ?? ''),
                      if (durationText.isNotEmpty)
                        Text(
                          durationText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pop(breakType);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchBreakTypes() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/break-types'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else if (response.statusCode == 401) {
        // Unauthorized: Token expired or invalid
        final notificationService =
            Provider.of<GlobalNotificationService>(context, listen: false);
        notificationService.showError('Session expired. Please log in again.');
        // Optionally, navigate to login screen
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        });
      } else {
        final notificationService =
            Provider.of<GlobalNotificationService>(context, listen: false);
        notificationService
            .showError('Failed to fetch break types: ${response.statusCode}');
      }
    } catch (e) {
      final notificationService =
          Provider.of<GlobalNotificationService>(context, listen: false);
      notificationService.showError('Error fetching break types: $e');
    }
    return [];
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'coffee':
        return Icons.coffee;
      case 'person':
        return Icons.person;
      case 'medical_services':
        return Icons.medical_services;
      case 'smoking_rooms':
        return Icons.smoking_rooms;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.free_breakfast;
    }
  }

  void _endBreak() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?['_id'];
    if (userId != null) {
      try {
        final attendanceProvider =
            Provider.of<AttendanceProvider>(context, listen: false);
        await attendanceProvider.endBreak(userId);
        await attendanceProvider.fetchTodayStatus(userId);
        setState(() {
          _isOnBreak = false;
        });
        final notificationService =
            Provider.of<GlobalNotificationService>(context, listen: false);
        notificationService.showSuccess('Break ended successfully!');
      } catch (e) {
        final notificationService =
            Provider.of<GlobalNotificationService>(context, listen: false);
        notificationService.showError('Failed to end break. Please try again.');
      }
    }
  }

  // Add network connectivity check
  /// Indicates whether the device is currently connected to a network.
  /// This is updated by [_checkNetworkConnectivity] and reflected in the app bar icon.
  bool _isConnected = true; // Assume connected by default

  @override
  void initState() {
    super.initState();
    _checkNetworkConnectivity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?['_id'];
      // Ensure profile is fetched on dashboard load
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      if (profileProvider.profile == null && userId != null) {
        profileProvider.refreshProfile();
      }
      if (userId != null) {
        Provider.of<AttendanceProvider>(context, listen: false)
            .fetchTodayStatus(userId)
            .then((_) {
          final attendanceProvider =
              Provider.of<AttendanceProvider>(context, listen: false);
          setState(() {
            _isOnBreak = attendanceProvider.todayStatus == 'on_break';
          });
        });
        Provider.of<AttendanceProvider>(context, listen: false)
            .fetchAttendanceSummary(userId);
      }
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
      // Fetch upcoming events
      _fetchUpcomingEvents();
    });
  }

  /// Checks the current network connectivity status using connectivity_plus.
  /// Updates [_isConnected] and triggers a UI update.
  void _checkNetworkConnectivity() async {
    var connectivityResult = await (Connectivity()).checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  /// Fetches upcoming events for the employee dashboard
  Future<void> _fetchUpcomingEvents() async {
    setState(() {
      _eventsLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.user?['_id'];

      if (token == null || userId == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/events'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final allEvents = List<Map<String, dynamic>>.from(data['events'] ?? []);

        // Filter for upcoming events (next 7 days)
        final now = DateTime.now();
        final nextWeek = now.add(const Duration(days: 7));

        final upcomingEvents = allEvents.where((event) {
          final eventDate = DateTime.parse(event['startDate'] ?? '');
          return eventDate.isAfter(now) && eventDate.isBefore(nextWeek);
        }).toList();

        setState(() {
          _upcomingEvents = upcomingEvents;
          _eventsLoading = false;
        });
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _eventsLoading = false;
      });
      // Don't show error to user for events, just log it
      print('Error fetching events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user == null) {
      // Not logged in, show fallback or redirect
      return const Scaffold(
        body: Center(child: Text('Not logged in. Please log in.')),
      );
    }
    final isAdmin = user['role'] == 'admin';
    if (isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Employee Dashboard')),
        body: const Center(child: Text('Access denied')),
        drawer: const AdminSideNavigation(currentRoute: '/employee_dashboard'),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        actions: [
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: _isConnected ? Colors.green : Colors.red,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, _) {
          if (profileProvider.isLoading || profileProvider.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = profileProvider.profile;
          if (profile == null) {
            return const Center(child: Text('No profile data available.'));
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 1200) {
                // Desktop mode: center and constrain width
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: _buildMainContent(profile),
                  ),
                );
              } else {
                // Mobile/tablet mode: full width
                return _buildMainContent(profile);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildMainContent(Map<String, dynamic> profile) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Consumer<ProfileProvider>(
              builder: (context, profileProvider, _) {
                final profile = profileProvider.profile;
                return _DashboardHeader(profile: profile);
              },
            ),
            const SizedBox(height: 28),
            const StatusCard(),
            const SizedBox(height: 28),
            Text(
              'Quick Actions',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _QuickActions(
              isOnBreak: _isOnBreak,
              clockIn: _clockIn,
              clockOut: _clockOut,
              startBreak: _startBreak,
              endBreak: _endBreak,
              applyLeave: (ctx) => _applyLeave(ctx),
              openTimesheet: (ctx) => _openTimesheet(ctx),
              openProfile: (ctx) => _openProfile(ctx),
              openEvents: (ctx) => _openEvents(ctx),
            ),
            const SizedBox(height: 28),
            // Upcoming Events Section
            if (_upcomingEvents.isNotEmpty || _eventsLoading) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Events',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/events'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildUpcomingEventsSection(),
              const SizedBox(height: 28),
            ],
          ],
        ),
      ),
    );
  }

  // --- Add missing navigation helpers as instance methods ---
  void _applyLeave(BuildContext context) {
    print('EMPLOYEE DASHBOARD: Navigating to Leave Request Screen');
    Navigator.pushNamed(context, '/leave_request');
  }

  void _openTimesheet(BuildContext context) {
    print('EMPLOYEE DASHBOARD: Navigating to Timesheet Screen');
    Navigator.pushNamed(context, '/timesheet');
  }

  void _openProfile(BuildContext context) {
    print('EMPLOYEE DASHBOARD: Navigating to Profile Screen');
    Navigator.pushNamed(context, '/profile');
  }

  void _openEvents(BuildContext context) {
    print('EMPLOYEE DASHBOARD: Navigating to Events Screen');
    Navigator.pushNamed(context, '/events');
  }

  Widget _buildUpcomingEventsSection() {
    if (_eventsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_upcomingEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: _upcomingEvents.take(3).map((event) {
        final eventDate = DateTime.parse(event['startDate'] ?? '');
        final attendees =
            List<Map<String, dynamic>>.from(event['attendees'] ?? []);
        final currentUserId =
            Provider.of<AuthProvider>(context, listen: false).user?['_id'];
        final isAttending =
            attendees.any((attendee) => attendee['user'] == currentUserId);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.event,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              event['title'] ?? 'Untitled Event',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(eventDate),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (event['location'] != null)
                  Text(
                    event['location'],
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                Text(
                  '${attendees.length} attending',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: isAttending
                ? Chip(
                    label: const Text('Attending'),
                    backgroundColor: Colors.green.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.green),
                  )
                : null,
            onTap: () => Navigator.pushNamed(context, '/events'),
          ),
        );
      }).toList(),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final Map<String, dynamic>? profile;
  const _DashboardHeader({this.profile});
  @override
  Widget build(BuildContext context) {
    // Use local helper for capitalization
    String capitalizeFirstLetter(String text) {
      if (text.isEmpty) return text;
      return text[0].toUpperCase() + text.substring(1).toLowerCase();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade500, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          UserAvatar(
            avatarUrl: profile?['avatar'],
            radius: 32,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Welcome Back,',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile != null
                      ? '${profile?['firstName'] ?? ''} ${profile?['lastName'] ?? ''}'
                          .trim()
                      : 'Guest',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  capitalizeFirstLetter(profile?['role'] ?? ''),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          const NotificationBell(iconColor: Colors.white),
        ],
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  const StatusCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Today's Status Card",
      container: true,
      child: Consumer<AttendanceProvider>(
        builder: (context, attendanceProvider, child) {
          final todayStatus = attendanceProvider.todayStatus;
          final currentAttendance = attendanceProvider.currentAttendance;

          String statusLabel = 'Unknown Status';
          IconData statusIcon = Icons.help_outline;
          Color statusColor = Colors.grey;
          List<Widget> statusDetails = [];

          switch (todayStatus) {
            case 'not_clocked_in':
              statusLabel = 'Not Clocked In';
              statusIcon = Icons.highlight_off;
              statusColor = Colors.red;
              statusDetails.add(
                Text(
                  'Tap Clock In to start your day',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              );
              break;
            case 'clocked_out':
              statusLabel = 'Clocked Out';
              statusIcon = Icons.check_circle_outline;
              statusColor = Colors.green;
              if (currentAttendance != null) {
                final checkInTime = currentAttendance['checkInTime'];
                final checkOutTime = currentAttendance['checkOutTime'];
                final breaks = currentAttendance['breaks'] as List?;
                if (checkOutTime != null) {
                  final checkOutDateTime =
                      DateTime.parse(checkOutTime).toLocal();
                  statusDetails.add(
                    Text(
                      'Clocked out at  ${DateFormat('HH:mm').format(checkOutDateTime)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  );
                }
                if (checkInTime != null && checkOutTime != null) {
                  final checkInDateTime = DateTime.parse(checkInTime).toLocal();
                  final checkOutDateTime =
                      DateTime.parse(checkOutTime).toLocal();
                  final totalWorkTime =
                      checkOutDateTime.difference(checkInDateTime);
                  int totalBreakMinutes = 0;
                  int breakCount = 0;
                  if (breaks != null) {
                    for (final breakEntry in breaks) {
                      if (breakEntry['startTime'] != null &&
                          breakEntry['endTime'] != null) {
                        final breakStart =
                            DateTime.parse(breakEntry['startTime']).toLocal();
                        final breakEnd =
                            DateTime.parse(breakEntry['endTime']).toLocal();
                        int diff = breakEnd.difference(breakStart).inMinutes;
                        if (diff < 0) diff = 0;
                        totalBreakMinutes += diff;
                        breakCount++;
                      }
                    }
                  }
                  final totalBreakDuration =
                      Duration(minutes: totalBreakMinutes);
                  final netWorkTime = totalWorkTime - totalBreakDuration;
                  final safeNetWorkTime =
                      netWorkTime.isNegative ? Duration.zero : netWorkTime;
                  statusDetails.addAll([
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Summary',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.login,
                                  size: 16, color: Colors.green[600]),
                              const SizedBox(width: 8),
                              Text('Started: ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w500)),
                              Text(DateFormat('HH:mm').format(checkInDateTime),
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.logout,
                                  size: 16, color: Colors.green[600]),
                              const SizedBox(width: 8),
                              Text('Finished: ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w500)),
                              Text(DateFormat('HH:mm').format(checkOutDateTime),
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.timer,
                                  size: 16, color: Colors.green[600]),
                              const SizedBox(width: 8),
                              Text('Total Time: ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w500)),
                              Text(
                                  '${totalWorkTime.inHours}h ${totalWorkTime.inMinutes % 60}m',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          if (breakCount > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.coffee,
                                    size: 16, color: Colors.green[600]),
                                const SizedBox(width: 8),
                                Text('Break Time: ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w500)),
                                Text(
                                    '${totalBreakDuration.inHours}h ${totalBreakDuration.inMinutes % 60}m',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.pause_circle,
                                    size: 16, color: Colors.green[600]),
                                const SizedBox(width: 8),
                                Text('Breaks Taken: ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w500)),
                                Text('$breakCount',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.work,
                                  size: 16, color: Colors.green[600]),
                              const SizedBox(width: 8),
                              Text('Net Work: ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w500)),
                              Text(
                                  '${safeNetWorkTime.inHours}h ${safeNetWorkTime.inMinutes % 60}m',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ]);
                }
              }
              break;
            case 'on_break':
              statusLabel = 'On Break';
              statusIcon = Icons.pause_circle_outline;
              statusColor = Colors.orange;
              if (currentAttendance != null) {
                final breaks = currentAttendance['breaks'] as List?;
                if (breaks != null && breaks.isNotEmpty) {
                  // Find the current break (where 'end' is null)
                  final currentBreak = breaks
                          .cast<Map<String, dynamic>>()
                          .where((b) => b['end'] == null)
                          .isNotEmpty
                      ? breaks
                          .cast<Map<String, dynamic>>()
                          .lastWhere((b) => b['end'] == null)
                      : null;
                  final totalBreaksToday = breaks.length;
                  if (currentBreak != null) {
                    final breakTypeId = currentBreak['type'];
                    final startTime = currentBreak['start'];
                    if (breakTypeId != null && startTime != null) {
                      final breakStartTime =
                          DateTime.parse(startTime).toLocal();
                      final duration =
                          DateTime.now().difference(breakStartTime);
                      String breakTypeName = 'Break';
                      if (breakTypeId == '68506da352d98bd74a976ea7') {
                        breakTypeName = 'Medical Break';
                      } else if (breakTypeId == '68506da352d98bd74a976ea6') {
                        breakTypeName = 'Break';
                      } else if (breakTypeId == '68506da352d98bd74a976ea5') {
                        breakTypeName = 'Coffee Break';
                      } else if (breakTypeId == '68506da352d98bd74a976ea4') {
                        breakTypeName = 'Lunch Break';
                      }
                      statusDetails.addAll([
                        Text(
                          '$breakTypeName since ${DateFormat('HH:mm').format(breakStartTime)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Duration: ${_formatDuration(duration)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 16, color: Colors.orange[700]),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Break Details',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[700],
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.label,
                                      size: 14, color: Colors.orange[600]),
                                  const SizedBox(width: 6),
                                  Text('Type: ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w500)),
                                  Text(breakTypeName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.schedule,
                                      size: 14, color: Colors.orange[600]),
                                  const SizedBox(width: 6),
                                  Text('Started: ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w500)),
                                  Text(
                                      DateFormat('hh:mm a')
                                          .format(breakStartTime),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.numbers,
                                      size: 14, color: Colors.orange[600]),
                                  const SizedBox(width: 6),
                                  Text('Breaks today: ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w500)),
                                  Text('$totalBreaksToday',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }
                  }
                }
              }
              break;
            case 'clocked_in':
              statusLabel = 'Clocked In';
              statusIcon = Icons.access_time;
              statusColor = Colors.blue.shade800; // Improved contrast
              if (currentAttendance != null) {
                final checkInTime = currentAttendance['checkInTime'];
                final breaks = currentAttendance['breaks'] as List?;
                if (checkInTime != null) {
                  final checkInDateTime = DateTime.parse(checkInTime).toLocal();
                  final workDuration =
                      DateTime.now().difference(checkInDateTime);
                  statusDetails.addAll([
                    Text(
                      'Since ${DateFormat('HH:mm').format(checkInDateTime)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    Text(
                      'Work time: ${workDuration.inHours}h ${workDuration.inMinutes % 60}m',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ]);
                  if (breaks != null && breaks.isNotEmpty) {
                    final completedBreaks =
                        breaks.where((b) => b['end'] != null).toList();
                    final totalBreaksToday = completedBreaks.length;
                    if (totalBreaksToday > 0) {
                      final mostRecentBreak = completedBreaks.last;
                      final breakTypeId = mostRecentBreak['type'];
                      final breakStartTime = mostRecentBreak['start'];
                      final breakEndTime = mostRecentBreak['end'];
                      if (breakStartTime != null && breakEndTime != null) {
                        final breakStart =
                            DateTime.parse(breakStartTime).toLocal();
                        final breakEnd = DateTime.parse(breakEndTime).toLocal();
                        final breakDuration = breakEnd.difference(breakStart);
                        String breakTypeName = 'Break';
                        if (breakTypeId == '68506da352d98bd74a976ea7') {
                          breakTypeName = 'Medical Break';
                        } else if (breakTypeId == '68506da352d98bd74a976ea6') {
                          breakTypeName = 'Break';
                        } else if (breakTypeId == '68506da352d98bd74a976ea5') {
                          breakTypeName = 'Coffee Break';
                        } else if (breakTypeId == '68506da352d98bd74a976ea4') {
                          breakTypeName = 'Lunch Break';
                        }
                        statusDetails.addAll([
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.coffee,
                                        size: 16, color: Colors.blue[700]),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Break Status',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 14, color: Colors.blue[600]),
                                    const SizedBox(width: 6),
                                    Text('Breaks taken: ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w500)),
                                    Text('$totalBreaksToday',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.label,
                                        size: 14, color: Colors.blue[600]),
                                    const SizedBox(width: 6),
                                    Text('Last break: ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w500)),
                                    Text(breakTypeName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.schedule,
                                        size: 14, color: Colors.blue[600]),
                                    const SizedBox(width: 6),
                                    Text('Time: ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w500)),
                                    Text(
                                        '${DateFormat('HH:mm').format(breakStart)} - ${DateFormat('HH:mm').format(breakEnd)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.timer,
                                        size: 14, color: Colors.blue[600]),
                                    const SizedBox(width: 6),
                                    Text('Duration: ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w500)),
                                    Text('${_formatDuration(breakDuration)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }
                    } else {
                      statusDetails.addAll([
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(
                                'No breaks taken today',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }
                  } else {
                    statusDetails.addAll([
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              'No breaks taken today',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ]);
                  }
                }
              }
              break;
            default:
              statusLabel = 'Status Not Available';
              statusIcon = Icons.info_outline;
              statusColor = Colors.grey.shade700;
              break;
          }

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Status',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.black87, // Improved contrast
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Semantics(
                              label: statusLabel,
                              child: Icon(statusIcon,
                                  color: statusColor, size: 30),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    statusLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...statusDetails,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: 'Refresh Status',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.refresh, size: 30),
                      onPressed: () {
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        final userId = authProvider.user?['_id'];
                        if (userId != null) {
                          attendanceProvider.fetchTodayStatus(userId);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ); // Padding
        }, // Card
      ), // Consumer
    ); // Semantics
  }
}

class _QuickActions extends StatelessWidget {
  final bool isOnBreak;
  final VoidCallback clockIn;
  final VoidCallback clockOut;
  final VoidCallback startBreak;
  final VoidCallback endBreak;
  final Function(BuildContext) applyLeave;
  final Function(BuildContext) openTimesheet;
  final Function(BuildContext) openProfile;
  final Function(BuildContext) openEvents;
  const _QuickActions({
    required this.isOnBreak,
    required this.clockIn,
    required this.clockOut,
    required this.startBreak,
    required this.endBreak,
    required this.applyLeave,
    required this.openTimesheet,
    required this.openProfile,
    required this.openEvents,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? 3 : 2;
    final childAspectRatio = isTablet ? 2.1 : 1.9;
    return Column(
      children: [
        Consumer<AttendanceProvider>(
          builder: (context, attendanceProvider, _) {
            final status = attendanceProvider.todayStatus;
            if (attendanceProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            // Not clocked in or no attendance: show clock in prompt
            if (status == 'not_clocked_in' ||
                attendanceProvider.currentAttendance == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      label: 'Not clocked in info',
                      child: Icon(Icons.info_outline,
                          size: 48, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 16),
                    Text('You have not clocked in today.',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.grey[800]),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'Clock In',
                      button: true,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text('Clock In'),
                        onPressed: clockIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF256029), // Improved contrast
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            // Clocked in: show clock out and start break
            if (status == 'clocked_in') {
              return Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.logout,
                      label: 'Clock Out',
                      color: isOnBreak
                          ? const Color(0xFFB0B0B0)
                          : const Color(0xFFB91C1C), // Improved contrast
                      onPressed: isOnBreak ? null : clockOut,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.free_breakfast,
                      label: 'Start Break',
                      color: const Color(0xFF374151), // Improved contrast
                      onPressed: startBreak,
                    ),
                  ),
                ],
              );
            }
            // On break: show end break, disable clock out
            if (status == 'on_break') {
              return Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.logout,
                      label: 'Clock Out',
                      color: const Color(0xFFB0B0B0),
                      onPressed: null, // Disabled during break
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.stop_circle,
                      label: 'End Break',
                      color: const Color(0xFFDD6B20), // Improved contrast
                      onPressed: endBreak,
                    ),
                  ),
                ],
              );
            }
            // Fallback: show only clock in
            return SizedBox(
              width: double.infinity,
              child: _buildQuickActionCard(
                context,
                icon: Icons.login,
                label: 'Clock In',
                color: const Color(0xFF256029), // Improved contrast
                onPressed: clockIn,
                isFullWidth: true,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            _buildQuickActionCard(
              context,
              icon: Icons.calendar_today,
              label: 'Apply Leave',
              color: const Color(0xFF1E40AF), // Improved contrast
              onPressed: () => applyLeave(context),
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.access_time,
              label: 'Timesheet',
              color: const Color(0xFF6D28D9), // Improved contrast
              onPressed: () => openTimesheet(context),
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.person,
              label: 'Profile',
              color: const Color(0xFF0F766E), // Improved contrast
              onPressed: () => openProfile(context),
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.event,
              label: 'Events',
              color: const Color(0xFF7C3AED), // Purple color for events
              onPressed: () => openEvents(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
    bool isFullWidth = false,
  }) {
    final isDisabled = onPressed == null;
    final cardColor = isDisabled ? color.withOpacity(0.5) : color;

    return Semantics(
      label: label,
      button: true,
      enabled: !isDisabled,
      child: Card(
        elevation: isDisabled ? 1 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: isFullWidth ? 80 : null,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cardColor, cardColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(14),
            child: isFullWidth
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                        size: 28,
                        semanticLabel: label, // Accessibility label
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                        size: 22,
                        semanticLabel: label, // Accessibility label
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Text(
                          label,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

// TODO: Audit for accessibility (color contrast) and add semantic labels for better screen reader support.
// Accessibility: Improved color contrast and added semantic labels for all interactive elements and status displays.
