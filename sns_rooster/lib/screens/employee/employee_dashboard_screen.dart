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
import '../../widgets/dashboard/leave_balance_tile.dart';
import '../../widgets/dashboard/leave_request_tile.dart';
import '../../widgets/dashboard/dashboard_action_button.dart';
import '../../widgets/dashboard/user_info_header.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/leave_request_provider.dart'; // Import LeaveRequestProvider
// Import SplashScreen
import '../../widgets/dashboard/dashboard_overview_tile.dart'; // Import the new overview tile
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sns_rooster/widgets/user_avatar.dart';
import '../../providers/notification_provider.dart'; // Import NotificationProvider
import 'package:sns_rooster/widgets/app_drawer.dart'; // Import AppDrawer
import 'package:intl/intl.dart';
import 'package:sns_rooster/providers/holiday_provider.dart';

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
        print('isClockedIn: $isClockedIn, lastClockIn: $lastClockIn');
      } else {
        isClockedIn = false;
        lastClockIn = null;
        print(
            'No active attendance record found or currentAttendance is null. Resetting state.');
      }
    } catch (e) {
      if (!mounted) return;
      print('Error fetching initial attendance: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingClock = false;
        });
      }
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
    const int totalAnnualLeaveDays = 20; // Example total
    final int usedAnnualLeaveDays = leaveProvider.leaveRequests
        .where((request) =>
            (request['leaveType']?.toString().toLowerCase() == 'annual') &&
            (request['status']?.toString().toLowerCase() == 'approved'))
        .map((request) {
      final startDateStr = request['startDate']?.toString();
      final endDateStr = request['endDate']?.toString();
      if (startDateStr == null || endDateStr == null) {
        return 0; // Handle null dates
      }
      final startDate = DateTime.tryParse(startDateStr);
      final endDate = DateTime.tryParse(endDateStr);
      if (startDate == null || endDate == null) {
        return 0; // Handle invalid date strings
      }
      return (endDate.difference(startDate).inDays + 1);
    }).fold(0, (sum, days) => sum + days); // Ensure sum + days returns int

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
      drawer: const AppDrawer(), // Use the reusable AppDrawer
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user avatar, welcome message, and notification icons
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.user;
                return UserInfoHeader(
                  userName: user?['name'] ?? 'User',
                  userRole: user?['role'] ?? 'Employee',
                  userAvatar: user?['avatar'] ?? '',
                  onNotificationTap: () {
                    // Handle notification tap
                    Navigator.pushNamed(context, '/notification');
                  },
                );
              },
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
                                const Icon(Icons.login,
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
                                  const Icon(Icons.pause_circle_outline,
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
                                  const Icon(Icons.logout,
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
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: !isClockedIn
                  ? SizedBox(
                      key: const ValueKey('clockIn'),
                      width: double.infinity,
                      child: DashboardActionButton(
                        icon: Icons.access_time,
                        label: 'Clock In',
                        onPressed: _toggleClockInOut,
                        loading: isLoadingClock,
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    )
                  : Row(
                      key: const ValueKey('clockedIn'),
                      children: [
                        Expanded(
                          child: DashboardActionButton(
                            icon: isOnBreak ? Icons.play_arrow : Icons.pause,
                            label: isOnBreak ? 'End Break' : 'Start Break',
                            onPressed: _toggleBreak,
                            loading: isLoadingBreak,
                            backgroundColor:
                                isOnBreak ? Colors.orange : Colors.blueGrey,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DashboardActionButton(
                            icon: Icons.logout,
                            label: 'Clock Out',
                            onPressed: _toggleClockInOut,
                            loading: isLoadingClock,
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 110,
                  child: DashboardActionButton(
                    icon: Icons.event_note,
                    label: 'Apply Leave',
                    onPressed: () {
                      Navigator.pushNamed(context, '/leave_request');
                    },
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  height: 110,
                  child: DashboardActionButton(
                    icon: Icons.edit_document,
                    label: 'Timesheet',
                    onPressed: () {
                      Navigator.pushNamed(context, '/timesheet');
                    },
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
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
            // Upcoming Holidays & Events
            const SizedBox(height: 24),
            Text(
              'Upcoming Holidays & Events',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<HolidayProvider>(
              builder: (context, holidayProvider, child) {
                if (holidayProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (holidayProvider.error != null) {
                  return Center(
                    child: Text('Error: ${holidayProvider.error}'),
                  );
                } else if (holidayProvider.holidays.isEmpty) {
                  return const Center(
                    child: Text('No upcoming holidays or events.'),
                  );
                } else {
                  final upcomingHolidays = holidayProvider.holidays
                      .where((holiday) => DateTime.parse(holiday['date'])
                          .isAfter(DateTime.now().subtract(const Duration(
                              days: 1)))) // Filter out past events
                      .toList();

                  if (upcomingHolidays.isEmpty) {
                    return const Center(
                      child: Text('No upcoming holidays or events.'),
                    );
                  }

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: upcomingHolidays.length,
                      itemBuilder: (context, index) {
                        final holiday = upcomingHolidays[index];
                        final holidayDate = DateTime.parse(holiday['date']);
                        final formattedDate =
                            DateFormat('MMM d, y').format(holidayDate);

                        return Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                holiday['type'] == 'public_holiday'
                                    ? Icons.calendar_today
                                    : Icons.event,
                                color: theme.colorScheme.primary,
                              ),
                              title: Text(holiday['title']),
                              subtitle: Text(
                                  '$formattedDate - ${holiday['description']}'),
                            ),
                            if (index < upcomingHolidays.length - 1)
                              const Divider(indent: 16, endIndent: 16),
                          ],
                        );
                      },
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24.0), // Consistent spacing
            // Attendance & Work Overview Section
            const DashboardOverviewTile(),
            const SizedBox(height: 32),
            // User Info Section
            // ... existing code ...
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
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}
