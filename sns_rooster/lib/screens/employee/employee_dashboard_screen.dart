// EmployeeDashboardScreen
// ----------------------
// Main dashboard for employees.
// - Shows user info, live clock, status, quick actions, and attendance summary.
// - All data is dynamic and ready for backend integration.
// - Modular: uses widgets from widgets/dashboard/ and models/services.
//
// To connect to backend, use AttendanceService and Employee model.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../models/employee.dart';
import '../../widgets/dashboard/leave_balance_tile.dart';
import '../../widgets/dashboard/leave_request_tile.dart';
import '../../widgets/dashboard/dashboard_action_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/leave_request_provider.dart'; // Import LeaveRequestProvider
import '../../screens/splash/splash_screen.dart'; // Import SplashScreen
import '../../widgets/dashboard/dashboard_overview_tile.dart'; // Import the new overview tile
import 'analytics_screen.dart'; // Import AnalyticsScreen from the same directory
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sns_rooster/widgets/user_avatar.dart';
import '../../screens/notification/notification_screen.dart';
import '../../providers/notification_provider.dart'; // Import NotificationProvider

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  // Remove simulated employee
  // final Employee employee = Employee(
  //   id: '1',
  //   name: 'John Doe',
  //   role: 'Software Engineer',
  //   avatar: 'assets/images/profile_placeholder.png',
  // );

  bool isClockedIn = false;
  bool isOnBreak = false;
  DateTime? lastClockIn;
  late final ValueNotifier<DateTime> _now;
  bool isLoadingClock = false;
  bool isLoadingBreak = false;

  @override
  void initState() {
    super.initState();
    _now = ValueNotifier(DateTime.now());
    // Update clock every second
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false; // Stop the loop if widget is unmounted
      _now.value = DateTime.now();
      return true;
    });
    // Load saved clock state
    _loadClockState();
    // Schedule the initial fetch for after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchInitialAttendance();
        _fetchLeaveData(); // Fetch leave data on init
      }
    });
  }

  Future<void> _loadClockState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isClockedIn = prefs.getBool('dashboard_isClockedIn') ?? false;
      isOnBreak = prefs.getBool('dashboard_isOnBreak') ?? false;
      final lastClockInStr = prefs.getString('dashboard_lastClockIn');
      lastClockIn =
          lastClockInStr != null ? DateTime.tryParse(lastClockInStr) : null;
    });
  }

  Future<void> _saveClockState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dashboard_isClockedIn', isClockedIn);
    await prefs.setBool('dashboard_isOnBreak', isOnBreak);
    await prefs.setString(
        'dashboard_lastClockIn', lastClockIn?.toIso8601String() ?? '');
  }

  Future<void> _fetchInitialAttendance() async {
    if (!mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final userId = authProvider.user?['_id'];

      if (userId == null) {
        print('User ID not found, cannot fetch initial attendance.');
        return;
      }

      setState(() {
        isLoadingClock = true;
      });

      print('Fetching initial attendance for user: $userId');
      await attendanceProvider.fetchUserAttendance(userId);
      print('AttendanceProvider error: ${attendanceProvider.error}');
      print(
          'Current attendance fetched: ${attendanceProvider.currentAttendance}');

      if (!mounted) return;

      final currentAttendance = attendanceProvider.currentAttendance;

      if (currentAttendance != null && currentAttendance.isNotEmpty) {
        isClockedIn = currentAttendance['checkIn'] != null &&
            currentAttendance['checkOut'] == null;
        if (isClockedIn) {
          lastClockIn = DateTime.parse(currentAttendance['checkIn']);
        }
        // Check if on break
        final breaks =
            List<Map<String, dynamic>>.from(currentAttendance['breaks'] ?? []);
        if (breaks.isNotEmpty && breaks.last['end'] == null) {
          isOnBreak = true;
        }
        isLoadingClock = false;
        print('isClockedIn: $isClockedIn, lastClockIn: $lastClockIn');
      } else {
        isClockedIn = false;
        lastClockIn = null;
        isLoadingClock = false;
        print(
            'No active attendance record found or currentAttendance is null. Resetting state.');
      }
    } catch (e) {
      if (!mounted) return;
      print('Error fetching initial attendance: $e');
      setState(() {
        isLoadingClock = false;
      });
    }
  }

  Future<void> _fetchLeaveData() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final leaveProvider =
        Provider.of<LeaveRequestProvider>(context, listen: false);
    final userId = authProvider.user?['_id'];

    if (userId == null) {
      print('User ID not found, cannot fetch leave data.');
      return;
    }

    try {
      await leaveProvider.getUserLeaveRequests(userId);
      if (!mounted) return;
      // Data will be updated via Consumer in the build method
    } catch (e) {
      if (!mounted) return;
      print('Error fetching leave data: $e');
    }
  }

  @override
  void dispose() {
    _now.dispose();
    // Cancel any active timers or subscriptions here
    super.dispose();
  }

  void _toggleClockInOut() async {
    if (isLoadingClock) return;
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (isClockedIn && isOnBreak) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('End your break before clocking out.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => isLoadingClock = true);

    try {
      if (isClockedIn) {
        await attendanceProvider.checkOut();
        if (attendanceProvider.error == null) {
          setState(() {
            isClockedIn = false;
            isOnBreak = false;
            lastClockIn = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clocked out successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error clocking out: ${attendanceProvider.error.toString()}')),
          );
        }
      } else {
        await attendanceProvider.checkIn();
        if (attendanceProvider.error == null) {
          setState(() {
            isClockedIn = true;
            isOnBreak = false;
            lastClockIn = DateTime.now();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clocked in successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error clocking in: ${attendanceProvider.error.toString()}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: ${e.toString()}')),
      );
    } finally {
      await _saveClockState();
      setState(() {
        isLoadingClock = false;
      });
    }
  }

  void _toggleBreak() async {
    if (isLoadingBreak) return;
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    if (!isClockedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Clock in before starting/ending a break.'),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => isLoadingBreak = true);
    try {
      if (isOnBreak) {
        await attendanceProvider.endBreak();
        if (attendanceProvider.error == null) {
          setState(() {
            isOnBreak = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Break ended successfully!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Error ending break: ${attendanceProvider.error.toString()}')));
        }
      } else {
        await attendanceProvider.startBreak();
        if (attendanceProvider.error == null) {
          setState(() {
            isOnBreak = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Break started successfully!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Error starting break: ${attendanceProvider.error.toString()}')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: ${e.toString()}')));
    } finally {
      await _saveClockState();
      setState(() {
        isLoadingBreak = false;
      });
    }
  }

  String _getStatusDisplay() {
    if (isClockedIn) {
      return 'Clocked In';
    } else if (lastClockIn != null) {
      return 'Clocked Out';
    } else {
      return 'Not Clocked In';
    }
  }

  String _getTimeDisplay() {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final currentAttendance = attendanceProvider.currentAttendance;

    if (currentAttendance != null &&
        currentAttendance['checkIn'] != null &&
        currentAttendance['checkOut'] == null) {
      final checkInTime = DateTime.parse(currentAttendance['checkIn']);
      final currentTime = _now.value;
      final duration = currentTime.difference(checkInTime);
      final h = duration.inHours.toString().padLeft(2, '0');
      final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
      final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    } else {
      return '00:00:00';
    }
  }

  String _getCheckoutTimeDisplay(AttendanceProvider attendanceProvider) {
    final currentAttendance = attendanceProvider.currentAttendance;

    if (currentAttendance != null && currentAttendance['checkOut'] != null) {
      final checkOutDateTime = DateTime.parse(currentAttendance['checkOut']);
      return '${checkOutDateTime.hour.toString().padLeft(2, '0')}:${checkOutDateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final leaveProvider = Provider.of<LeaveRequestProvider>(
        context); // Listen to LeaveRequestProvider
    final notificationProvider = Provider.of<NotificationProvider>(
        context); // Listen to NotificationProvider

    // Calculate total annual leave days remaining (mock logic)
    // This should ideally come from backend with specific leave types
    final int totalAnnualLeaveDays = 20; // Example total
    final int usedAnnualLeaveDays = leaveProvider.leaveRequests
        .where((request) =>
            (request['leaveType']?.toString().toLowerCase() == 'annual') &&
            (request['status']?.toString().toLowerCase() == 'approved'))
        .map((request) {
      final startDateStr = request['startDate']?.toString();
      final endDateStr = request['endDate']?.toString();
      if (startDateStr == null || endDateStr == null)
        return 0; // Handle null dates
      final startDate = DateTime.tryParse(startDateStr);
      final endDate = DateTime.tryParse(endDateStr);
      if (startDate == null || endDate == null)
        return 0; // Handle invalid date strings
      return (endDate.difference(startDate).inDays + 1);
    }).fold(0,
            (sum, days) => sum + days as int); // Ensure sum + days returns int

    final int remainingAnnualLeaveDays =
        totalAnnualLeaveDays - usedAnnualLeaveDays;

    // Find the latest pending leave request for display
    final latestPendingLeaveRequest = leaveProvider.leaveRequests
            .where((request) =>
                (request['status']?.toString().toLowerCase() == 'pending'))
            .isNotEmpty
        ? leaveProvider.leaveRequests
            .where((request) =>
                (request['status']?.toString().toLowerCase() == 'pending'))
            .reduce((a, b) {
            final aStartDateStr = a['startDate']?.toString();
            final bStartDateStr = b['startDate']?.toString();

            if (aStartDateStr == null || bStartDateStr == null) {
              // Handle cases where a date is null, prioritize non-null dates or 'a' if both are null
              return aStartDateStr == null ? b : a;
            }

            final aStartDate = DateTime.tryParse(aStartDateStr);
            final bStartDate = DateTime.tryParse(bStartDateStr);

            if (aStartDate == null || bStartDate == null) {
              // Handle cases where date string is invalid, prioritize valid dates or 'a' if both are invalid
              return aStartDate == null ? b : a;
            }

            return aStartDate.isAfter(bStartDate) ? a : b;
          }) // Get the latest one
        : null;

    final currentAttendance = attendanceProvider.currentAttendance;
    String? clockInTime;
    String? clockOutTime;
    String? breakStartTime;
    if (currentAttendance != null) {
      if (currentAttendance['checkIn'] != null) {
        final dt = DateTime.parse(currentAttendance['checkIn']).toLocal();
        clockInTime =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      if (currentAttendance['checkOut'] != null) {
        final dt = DateTime.parse(currentAttendance['checkOut']).toLocal();
        clockOutTime =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      final breaks =
          List<Map<String, dynamic>>.from(currentAttendance['breaks'] ?? []);
      if (breaks.isNotEmpty && breaks.last['end'] == null) {
        final dt = DateTime.parse(breaks.last['start']).toLocal();
        breakStartTime =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: theme.colorScheme.surface,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: Builder(
                          builder: (context) {
                            final avatarPath = authProvider.user?['avatar'];
                            if (avatarPath != null) {
                              // Check if it's a local file path (e.g., from image_picker)
                              if (avatarPath.startsWith('/') ||
                                  avatarPath.startsWith('file://')) {
                                final file = File(
                                    avatarPath.replaceFirst('file://', ''));
                                if (file.existsSync()) {
                                  return ClipOval(
                                    child: Image.file(
                                      file,
                                      width: 64, // Match radius * 2
                                      height: 64, // Match radius * 2
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                } else {
                                  // File not found, fallback to placeholder
                                  print(
                                      'Debug: Dashboard avatar file not found: $avatarPath. Falling back to placeholder.');
                                  return SvgPicture.asset(
                                    'assets/images/profile_placeholder.png',
                                    width: 64,
                                    height: 64,
                                  );
                                }
                              } else if (avatarPath.startsWith('assets/')) {
                                // It's an SVG asset (e.g., default placeholder)
                                return SvgPicture.asset(
                                  avatarPath,
                                  width: 64,
                                  height: 64,
                                );
                              } else {
                                // Potentially a network image or other unsupported format, fall back.
                                print(
                                    'Debug: Dashboard unsupported avatar path format: $avatarPath. Falling back to placeholder.');
                                return SvgPicture.asset(
                                  'assets/images/profile_placeholder.png',
                                  width: 64,
                                  height: 64,
                                );
                              }
                            } else {
                              // No avatar path, use placeholder
                              return SvgPicture.asset(
                                'assets/images/profile_placeholder.png',
                                width: 64,
                                height: 64,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(authProvider.user?['name'] ?? 'Employee Name',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(authProvider.user?['role'] ?? 'Employee Role',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              _buildNavTile(context,
                  icon: Icons.dashboard, label: 'Dashboard', route: '/'),
              _buildNavTile(context,
                  icon: Icons.access_time,
                  label: 'Timesheet',
                  route: '/timesheet'),
              _buildNavTile(context,
                  icon: Icons.calendar_today,
                  label: 'Leave',
                  route: '/leave_request'),
              _buildNavTile(context,
                  icon: Icons.check_circle_outline,
                  label: 'Attendance',
                  route: '/attendance'),
              _buildNavTile(context,
                  icon: Icons.notifications_none,
                  label: 'Notifications',
                  route: '/notification',
                  trailing: _buildNotificationDot()),
              _buildNavTile(context,
                  icon: Icons.person_outline,
                  label: 'Profile',
                  route: '/profile'),
              const Divider(),
              _buildNavTile(context,
                  icon: Icons.support_agent,
                  label: 'Support',
                  route: '/support'),
              ListTile(
                leading: Icon(Icons.logout, color: theme.colorScheme.onSurface),
                title: Text(
                  'Logout',
                  style: theme.textTheme.bodyLarge,
                ),
                onTap: () async {
                  await authProvider.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SplashScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user avatar, welcome message, and notification icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    UserAvatar(
                        avatarUrl: authProvider.user?['avatar'],
                        radius: 24), // Add user avatar
                    const SizedBox(
                        width: 12), // Spacing between avatar and text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome,',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          authProvider.user?['name'] ?? 'Employee',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Notification and Message Icons with Badges
                Row(
                  children: [
                    // Bell Icon (Notifications)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none),
                          tooltip: 'Notifications',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationScreen(
                                    initialTabIndex:
                                        0), // Pass initialTabIndex for notifications
                              ),
                            );
                          },
                        ),
                        // Dynamic unread notification count
                        if (notificationProvider.unreadNotifications > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                notificationProvider.unreadNotifications
                                    .toString(), // Use dynamic unread count
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Message Icon (Messages)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.message_outlined),
                          tooltip: 'Messages',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationScreen(
                                    initialTabIndex:
                                        1), // Pass initialTabIndex for messages
                              ),
                            );
                          },
                        ),
                        // Dynamic unread message count
                        if (notificationProvider.unreadMessages > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                notificationProvider.unreadMessages
                                    .toString(), // Use dynamic unread count
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24.0), // Consistent spacing after header
            // Today's Status & Live Clock Section
            Card(
              elevation: 8, // Increased elevation for more prominence
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(18)), // More rounded corners
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.8),
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0), // Increased padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Status',
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                Colors.white), // Text color white for contrast
                      ),
                      const Divider(
                          height: 20, thickness: 1, color: Colors.white70),
                      // Main status display: Time and Status (Stacked vertically and prominent)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Current Time Display
                          Text(
                            'Current Time',
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: Colors.white70),
                          ),
                          ValueListenableBuilder<DateTime>(
                            valueListenable: _now,
                            builder: (context, value, child) {
                              return Text(
                                '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}',
                                style: theme.textTheme.displayMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                          const SizedBox(
                              height:
                                  24), // Increased space between time and status blocks
                          // Your Status Display
                          Text(
                            'Your Status',
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: Colors.white70),
                          ),
                          Row(
                            // Keep Row for icon and status text
                            children: [
                              Icon(
                                isClockedIn ? Icons.check_circle : Icons.cancel,
                                color: isClockedIn
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                size:
                                    28, // Reverting icon size for better visual balance
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                // Ensure text fills remaining space with ellipsis
                                child: Text(
                                  _getStatusDisplay(),
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                          // Reverting to headlineSmall for prominence
                                          color: isClockedIn
                                              ? Colors.greenAccent
                                              : Colors.redAccent,
                                          fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20), // Space before detailed times
                      // Detailed times (Clocked in/out, on break) - always aligned left within the card
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isClockedIn && clockInTime != null)
                            Row(
                              children: [
                                Icon(Icons.login,
                                    color: Colors.white70, size: 18),
                                const SizedBox(width: 8),
                                Text('Clocked in at: $clockInTime',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(color: Colors.white70)),
                              ],
                            ),
                          if (isOnBreak && breakStartTime != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.pause_circle_outline,
                                      color: Colors.yellowAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Text('On break since: $breakStartTime',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              color: Colors.yellowAccent)),
                                ],
                              ),
                            ),
                          if (!isClockedIn && clockOutTime != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.logout,
                                      color: Colors.white70, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Clocked out at: $clockOutTime',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.white70)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0), // Consistent spacing
            // Quick Actions Section
            Text(
              'Quick Actions',
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 16.0), // Consistent spacing
            Row(
              children: [
                Expanded(
                  child: DashboardActionButton(
                    label: isClockedIn ? 'Clock Out' : 'Clock In',
                    icon: isClockedIn ? Icons.logout : Icons.login,
                    onPressed: _toggleClockInOut,
                    loading: isLoadingClock,
                    backgroundColor: isClockedIn
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DashboardActionButton(
                    label: isOnBreak ? 'End Break' : 'Start Break',
                    icon: isOnBreak
                        ? Icons.play_arrow_outlined
                        : Icons.pause_outlined,
                    onPressed: _toggleBreak,
                    loading: isLoadingBreak,
                    backgroundColor: isOnBreak
                        ? theme.colorScheme.secondary
                        : Colors.orange[700]!,
                    foregroundColor: theme.colorScheme.onSecondary,
                    disabled: !isClockedIn || isLoadingBreak,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0), // Consistent spacing
            // My Leave Overview Section
            Text(
              'My Leave Overview',
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 16.0), // Consistent spacing
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LeaveBalanceTile(
                      type: 'Annual Leave',
                      days: remainingAnnualLeaveDays,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Latest Pending Leave Request',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary),
                    ),
                    const Divider(height: 20, thickness: 1),
                    latestPendingLeaveRequest != null
                        ? LeaveRequestTile(
                            type:
                                latestPendingLeaveRequest['leaveType'] ?? 'N/A',
                            date: latestPendingLeaveRequest['startDate'] != null
                                ? '${DateTime.parse(latestPendingLeaveRequest['startDate']).year}-${DateTime.parse(latestPendingLeaveRequest['startDate']).month.toString().padLeft(2, '0')}-${DateTime.parse(latestPendingLeaveRequest['startDate']).day.toString().padLeft(2, '0')}'
                                : 'N/A',
                            status:
                                latestPendingLeaveRequest['status'] ?? 'N/A',
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No pending leave requests.',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[700]),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24.0), // Consistent spacing
            // Recent Notifications / Announcements Section (Placeholder)
            Text(
              'Recent Updates',
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 16.0), // Consistent spacing
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No new announcements or notifications.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                    // TODO: Implement actual recent notifications/announcements here
                    // For example, a ListView.builder of the latest 2-3 items
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24.0), // Consistent spacing
            // Attendance & Work Overview Section
            const DashboardOverviewTile(),

            // TODO: Add other relevant sections like Timesheet Summary, etc.
            // Expanded section for analytics screen
            // AnalyticsScreen(),
            const SizedBox(height: 16.0), // Consistent spacing
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AnalyticsScreen()),
                  );
                },
                icon: Icon(Icons.analytics, color: theme.colorScheme.primary),
                label: Text(
                  'View Detailed Analytics',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationDot() {
    // Implement logic to show/hide notification dot based on unread notifications
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildNavTile(BuildContext context,
      {required IconData icon,
      required String label,
      required String route,
      Widget? trailing}) {
    final theme = Theme.of(context);
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: trailing,
      selected: isSelected,
      onTap: () {
        Navigator.pop(context); // Close the drawer
        if (currentRoute != route) {
          // For dashboard, use employee_dashboard route instead of '/'
          final targetRoute = route == '/' ? '/employee_dashboard' : route;
          Navigator.pushReplacementNamed(context, targetRoute);
        }
      },
    );
  }
}
