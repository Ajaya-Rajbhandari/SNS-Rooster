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
  DateTime? breakStart;
  Duration totalBreakDuration = Duration.zero;
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
    // Schedule the initial fetch for after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchInitialAttendance();
        _fetchLeaveData(); // Fetch leave data on init
      }
    });
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
        setState(() {
          isClockedIn = currentAttendance['checkIn'] != null &&
              currentAttendance['checkOut'] == null;
          if (isClockedIn) {
            lastClockIn = DateTime.parse(currentAttendance['checkIn']);

            // Check for ongoing break
            if (currentAttendance['breaks'] != null &&
                currentAttendance['breaks'].isNotEmpty) {
              final lastBreak = currentAttendance['breaks'].last;
              if (lastBreak['startTime'] != null &&
                  lastBreak['endTime'] == null) {
                isOnBreak = true;
                breakStart = DateTime.parse(lastBreak['startTime']);
              } else {
                isOnBreak = false; // No ongoing break
                breakStart = null;
              }
            } else {
              isOnBreak = false; // No breaks recorded
              breakStart = null;
            }
            // Sum total break duration from all completed breaks
            totalBreakDuration = Duration(
                milliseconds: currentAttendance['totalBreakDuration'] ?? 0);
          }
          isLoadingClock = false;
          print(
              'isClockedIn: $isClockedIn, lastClockIn: $lastClockIn, isOnBreak: $isOnBreak, breakStart: $breakStart, totalBreakDuration: $totalBreakDuration');
        });
      } else {
        // No active attendance record found or currentAttendance is null
        setState(() {
          isClockedIn = false;
          lastClockIn = null;
          isOnBreak = false;
          breakStart = null;
          totalBreakDuration = Duration.zero;
          isLoadingClock = false;
          print(
              'No active attendance record found or currentAttendance is null. Resetting state.');
        });
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

    if (isClockedIn && !isOnBreak) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Clock Out'),
          content: const Text('Are you sure you want to clock out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clock Out'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => isLoadingClock = true);

    try {
      if (isClockedIn) {
        if (isOnBreak) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please end your break before clocking out.'),
              backgroundColor: Colors.orange,
            ),
          );
          isLoadingClock = false;
          return;
        }
        await attendanceProvider.checkOut();
        if (attendanceProvider.error == null) {
          setState(() {
            isClockedIn = false;
            lastClockIn = null;
            isOnBreak = false; // Ensure break state is reset on clock out
            breakStart = null;
            totalBreakDuration = Duration.zero;
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
            lastClockIn = DateTime.now(); // Set based on successful check-in
            isOnBreak = false;
            breakStart = null;
            totalBreakDuration = Duration.zero;
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
      setState(() {
        isLoadingClock = false;
      });
    }
  }

  void _toggleBreak() async {
    if (isLoadingBreak) return;
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);

    print(
        'Debug: _toggleBreak called. Current isOnBreak: $isOnBreak, breakStart: $breakStart');

    if (!isClockedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please clock in before starting/ending a break.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoadingBreak = true);

    try {
      if (isOnBreak) {
        print('Debug: Attempting to end break.');
        await attendanceProvider.endBreak();
        print(
            'Debug: endBreak completed. Provider error: ${attendanceProvider.error}');
        if (attendanceProvider.error == null) {
          setState(() {
            isOnBreak = false;
            breakStart = null;
            // Update totalBreakDuration from provider after successful endBreak
            totalBreakDuration = Duration(
                milliseconds: attendanceProvider
                        .currentAttendance?['totalBreakDuration'] ??
                    0);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Break ended successfully!')),
          );
          print(
              'Debug: Break ended. Updated totalBreakDuration: $totalBreakDuration');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error ending break: ${attendanceProvider.error.toString()}')),
          );
          print('Debug: Error ending break: ${attendanceProvider.error}');
        }
      } else {
        print('Debug: Attempting to start break.');
        await attendanceProvider.startBreak();
        print(
            'Debug: startBreak completed. Provider error: ${attendanceProvider.error}');

        if (attendanceProvider.error == null) {
          setState(() {
            isOnBreak = true;
            breakStart = DateTime.now(); // Set based on successful startBreak
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Break started successfully!')),
          );
          print('Debug: Break started.');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error starting break: ${attendanceProvider.error.toString()}')),
          );
          print('Debug: Error starting break: ${attendanceProvider.error}');
        }
      }
    } catch (e) {
      if (!mounted) return;
      print('Debug: Exception in _toggleBreak: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingBreak = false;
        });
      }
    }
  }

  String _getStatusDisplay() {
    if (isOnBreak) {
      return 'On Break';
    } else if (isClockedIn) {
      return 'Clocked In';
    } else if (lastClockIn != null) {
      return 'Clocked Out'; // Or 'Completed for today'
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

  String _getBreakTimeDisplay() {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final currentAttendance = attendanceProvider.currentAttendance;

    if (currentAttendance != null &&
        currentAttendance['checkIn'] != null &&
        currentAttendance['checkOut'] == null) {
      final totalBreakMs = currentAttendance['totalBreakDuration'] ?? 0;
      Duration calculatedTotalBreakDuration =
          Duration(milliseconds: totalBreakMs);

      // If currently on break, add the current break duration to the total
      if (isOnBreak && breakStart != null) {
        final currentBreakDuration = DateTime.now().difference(breakStart!);
        calculatedTotalBreakDuration += currentBreakDuration;
      }
      return _formatDuration(calculatedTotalBreakDuration);
    } else {
      return _formatDuration(Duration.zero);
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
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

    // Calculate total annual leave days remaining (mock logic)
    // This should ideally come from backend with specific leave types
    final int totalAnnualLeaveDays = 20; // Example total
    final int usedAnnualLeaveDays = leaveProvider.leaveRequests
        .where((request) =>
            request['leaveType'] == 'annual' && request['status'] == 'approved')
        .map((request) => (DateTime.parse(request['endDate'])
                .difference(DateTime.parse(request['startDate']))
                .inDays +
            1))
        .fold(0,
            (sum, days) => sum + days as int); // Ensure sum + days returns int

    final int remainingAnnualLeaveDays =
        totalAnnualLeaveDays - usedAnnualLeaveDays;

    // Find the latest pending leave request for display
    final latestPendingLeaveRequest = leaveProvider.leaveRequests
            .where((request) => request['status'] == 'pending')
            .isNotEmpty
        ? leaveProvider.leaveRequests
            .where((request) => request['status'] == 'pending')
            .reduce((a, b) => DateTime.parse(a['startDate'])
                    .isAfter(DateTime.parse(b['startDate']))
                ? a
                : b) // Get the latest one
        : null;

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
            // Header with current time and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${(_now.value.hour < 12) ? 'Morning' : (_now.value.hour < 17) ? 'Afternoon' : 'Evening'}, ${authProvider.user?['name']?.split(' ')[0] ?? 'Employee'}!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold),
                    ),
                    ValueListenableBuilder<DateTime>(
                      valueListenable: _now,
                      builder: (context, value, child) {
                        return Text(
                          '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}',
                          style: theme.textTheme.displaySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${_getStatusDisplay()}',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8)),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Builder(
                    builder: (context) {
                      final avatarPath = authProvider.user?['avatar'];
                      if (avatarPath != null) {
                        // Check if it's a local file path (e.g., from image_picker)
                        if (avatarPath.startsWith('/') ||
                            avatarPath.startsWith('file://')) {
                          final file =
                              File(avatarPath.replaceFirst('file://', ''));
                          if (file.existsSync()) {
                            return ClipOval(
                              child: Image.file(
                                file,
                                width: 80, // Match radius * 2 (40 * 2)
                                height: 80, // Match radius * 2
                                fit: BoxFit.cover,
                              ),
                            );
                          } else {
                            // File not found, fallback to placeholder
                            print(
                                'Debug: Dashboard main avatar file not found: $avatarPath. Falling back to placeholder.');
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
                              'Debug: Dashboard main unsupported avatar path format: $avatarPath. Falling back to placeholder.');
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
              ],
            ),
            const SizedBox(height: 24),
            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: Row(
                key: ValueKey(isClockedIn.toString() + isOnBreak.toString()),
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (!isClockedIn)
                    Expanded(
                      child: DashboardActionButton(
                        icon: Icons.login,
                        label: 'Clock In',
                        onPressed: _toggleClockInOut,
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.9),
                        foregroundColor: theme.colorScheme.onPrimary,
                        loading: isLoadingClock,
                      ),
                    ),
                  if (isClockedIn && !isOnBreak)
                    Expanded(
                      child: DashboardActionButton(
                        icon: Icons.logout,
                        label: 'Clock Out',
                        onPressed: _toggleClockInOut,
                        backgroundColor:
                            theme.colorScheme.tertiary.withOpacity(0.9),
                        foregroundColor: theme.colorScheme.onTertiary,
                        loading: isLoadingClock,
                      ),
                    ),
                  if (isClockedIn && !isOnBreak) const SizedBox(width: 16),
                  if (isClockedIn && !isOnBreak)
                    Expanded(
                      child: DashboardActionButton(
                        icon: Icons.pause,
                        label: 'Start Break',
                        onPressed: _toggleBreak,
                        backgroundColor:
                            theme.colorScheme.secondary.withOpacity(0.9),
                        foregroundColor: theme.colorScheme.onSecondary,
                        loading: isLoadingBreak,
                      ),
                    ),
                  if (isOnBreak)
                    Expanded(
                      child: DashboardActionButton(
                        icon: Icons.play_arrow,
                        label: 'End Break',
                        onPressed: _toggleBreak,
                        backgroundColor: theme.colorScheme.secondaryContainer
                            .withOpacity(0.9),
                        foregroundColor: theme.colorScheme.onSecondaryContainer,
                        loading: isLoadingBreak,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Today's Attendance Summary
            Text(
              "Today's Attendance Summary",
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildSummaryRow('Total Time', _getTimeDisplay(), theme),
                    const Divider(height: 20),
                    _buildSummaryRow(
                        'Break Time', _getBreakTimeDisplay(), theme),
                    const Divider(height: 20),
                    _buildSummaryRow(
                      'Check-in',
                      lastClockIn != null
                          ? '${lastClockIn!.hour.toString().padLeft(2, '0')}:${lastClockIn!.minute.toString().padLeft(2, '0')}'
                          : 'N/A',
                      theme,
                    ),
                    const Divider(height: 20),
                    _buildSummaryRow(
                      'Check-out',
                      _getCheckoutTimeDisplay(attendanceProvider),
                      theme,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Add the new Dashboard Overview Tile here
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 700),
              child: DashboardOverviewTile(
                onStatTileTap: (label) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tapped $label tile!')),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('View Analytics'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Leave Balance and Request
            Text(
              'Leave Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LeaveBalanceTile(
                    type: 'Annual',
                    days: remainingAnnualLeaveDays, // Dynamic leave days
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LeaveRequestTile(
                    // Display latest pending leave request, or a default message
                    type: latestPendingLeaveRequest?['leaveType'] ??
                        'No Pending Leave',
                    date: latestPendingLeaveRequest?['startDate'] != null
                        ? '${DateTime.parse(latestPendingLeaveRequest!['startDate']).year}-${DateTime.parse(latestPendingLeaveRequest!['startDate']).month.toString().padLeft(2, '0')}-${DateTime.parse(latestPendingLeaveRequest!['startDate']).day.toString().padLeft(2, '0')}'
                        : 'N/A',
                    status: latestPendingLeaveRequest?['status'] ?? '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Apply for Leave button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/leave_request');
                },
                icon: const Icon(Icons.add_task), // Changed icon to add_task
                label: const Text('Apply for Leave'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme
                      .colorScheme.secondary, // Use secondary color for action
                  foregroundColor: theme.colorScheme.onSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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

  Widget _buildSummaryRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium
              ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8)),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
