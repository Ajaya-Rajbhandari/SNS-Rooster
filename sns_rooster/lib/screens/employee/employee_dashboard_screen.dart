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
import 'package:shared_preferences/shared_preferences.dart';
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
  String _lastSavedProfileJson = "";

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
        // Fetch backend-driven attendance status for today
        final attendanceProvider =
            Provider.of<AttendanceProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.user?['_id'];
        if (userId != null) {
          attendanceProvider.fetchTodayStatus(userId);
          // Note: fetchTodayStatus now also fetches currentAttendance data
        }
      });
    } catch (e) {
      print(
          'ERROR: ProfileProvider is not accessible in EmployeeDashboardScreen: $e');
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?['_id'];
    if (userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {});
    }
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

  void _saveProfileToSharedPreferences(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'profile',
        json.encode({
          'name': profile['firstName'] + ' ' + profile['lastName'],
          'role': profile['role'],
          'avatar': profile['avatar'],
        }));
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
    // Note: fetchTodayStatus now also fetches currentAttendance data
    setState(() {});
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
                return ListTile(
                  leading: Icon(
                    _getIconFromString(breakType['icon']),
                    color: colorFromHex(breakType['color']),
                  ),
                  title: Text(breakType['displayName']),
                  subtitle: Text(breakType['description']),
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
        // Note: fetchTodayStatus now also fetches currentAttendance data
        setState(() {
          _isOnBreak = false;
        });
        // Force rebuild of QuickActions by calling setState at parent level
        // and ensure AttendanceProvider notifies listeners
        // Optionally, you can also call context.read<AttendanceProvider>().notifyListeners();
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
      if (userId != null) {
        Provider.of<AttendanceProvider>(context, listen: false)
            .fetchTodayStatus(userId);
        // Fetch attendance summary without date range
        Provider.of<AttendanceProvider>(context, listen: false)
            .fetchAttendanceSummary(userId);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user == null) {
      // Not logged in, show fallback or redirect
      return Scaffold(
        body: Center(child: Text('Not logged in. Please log in.')),
      );
    }
    final uid = user['_id'] as String;
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
          // Only save profile to SharedPreferences if it has changed
          if (_lastSavedProfileJson != json.encode(profile)) {
            _saveProfileToSharedPreferences(profile);
            _lastSavedProfileJson = json.encode(profile);
          }
          return SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Use Consumer to always get latest profile data
                  Consumer<ProfileProvider>(
                    builder: (context, profileProvider, _) {
                      final profile = profileProvider.profile;
                      return _DashboardHeader(profile: profile);
                    },
                  ),
                  const SizedBox(height: 28),
                  const StatusCard(), const SizedBox(height: 28),
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
                    applyLeave: _applyLeave,
                    openTimesheet: _openTimesheet,
                    openProfile: _openProfile,
                  ),
                  const SizedBox(height: 28),
                  // Remove DocumentListItem widgets from dashboard
                  // DocumentListItem(label: 'ID Card', filePath: 'https://example.com/id_card.png', fileType: 'image'),
                  // DocumentListItem(label: 'Passport', filePath: 'https://example.com/passport.png', fileType: 'image'),
                  // DocumentListItem(label: 'Resume', filePath: 'https://example.com/resume.pdf', fileType: 'pdf'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Correct the usage of context in methods
void _applyLeave(BuildContext context) {
  print('EMPLOYEE DASHBOARD: Navigating to Leave Request Screen');
  Navigator.pushNamed(context, '/leave_request');
}

void _openTimesheet(BuildContext context) {
  print('EMPLOYEE DASHBOARD: Navigating to Timesheet Screen');
  Navigator.pushNamed(context, '/timesheet');
}

// Add _openProfile method to _EmployeeDashboardScreenState
void _openProfile(BuildContext context) {
  print('EMPLOYEE DASHBOARD: Navigating to Profile Screen');
  Navigator.pushNamed(context, '/profile');
}

// Helper method to capitalize first letter
String _capitalizeFirstLetter(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

// --- Extracted Widgets ---

class _DashboardHeader extends StatelessWidget {
  final Map<String, dynamic>? profile;
  const _DashboardHeader({this.profile});
  @override
  Widget build(BuildContext context) {
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
                  _capitalizeFirstLetter(profile?['role'] ?? ''),
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
    return Consumer<AttendanceProvider>(
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
                // Parse and convert to local time to handle timezone issues
                final checkOutDateTime = DateTime.parse(checkOutTime).toLocal();
                statusDetails.add(
                  Text(
                    'Clocked out at ${DateFormat('hh:mm a').format(checkOutDateTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                );
              }
              // Show comprehensive daily summary
              if (checkInTime != null && checkOutTime != null) {
                // Parse and convert to local time to handle timezone issues
                final checkInDateTime = DateTime.parse(checkInTime).toLocal();
                final checkOutDateTime = DateTime.parse(checkOutTime).toLocal();
                final totalWorkTime =
                    checkOutDateTime.difference(checkInDateTime);

                // Calculate total break time
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

                final totalBreakDuration = Duration(minutes: totalBreakMinutes);
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
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Summary',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
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
                            Text(DateFormat('hh:mm a').format(checkInDateTime),
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
                            Text(DateFormat('hh:mm a').format(checkOutDateTime),
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
                                      ?.copyWith(fontWeight: FontWeight.w500)),
                              Text(
                                  '${totalBreakDuration.inHours}h ${totalBreakDuration.inMinutes % 60}m',
                                  style: Theme.of(context).textTheme.bodySmall),
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
                                      ?.copyWith(fontWeight: FontWeight.w500)),
                              Text('$breakCount',
                                  style: Theme.of(context).textTheme.bodySmall),
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
                final currentBreak = breaks.lastWhere(
                  (b) => b['end'] == null, // Note: it's 'end', not 'endTime'
                  orElse: () => null,
                );

                // Count total breaks today (including current one)
                final totalBreaksToday = breaks.length;
                if (currentBreak != null) {
                  final breakTypeId = currentBreak[
                      'type']; // Note: it's 'type', not 'breakType'
                  final startTime = currentBreak[
                      'start']; // Note: it's 'start', not 'startTime'
                  if (breakTypeId != null && startTime != null) {
                    // Parse and convert to local time to handle timezone issues
                    final breakStartTime = DateTime.parse(startTime).toLocal();
                    final duration = DateTime.now().difference(breakStartTime);

                    // Default break type name (fallback)
                    String breakTypeName = 'Break';

                    // Try to map break type ID to name
                    // For now, we'll use a simple mapping based on common IDs
                    // In a real app, you'd fetch break types and match them
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
                        '$breakTypeName since ${DateFormat('hh:mm a').format(breakStartTime)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Duration: ${duration.inMinutes} minutes',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.orange.withOpacity(0.3)),
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
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
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
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
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
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
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
            statusColor = Colors.blue;
            if (currentAttendance != null) {
              final checkInTime = currentAttendance['checkInTime'];
              final breaks = currentAttendance['breaks'] as List?;

              if (checkInTime != null) {
                try {
                  // Parse and convert to local time to handle timezone issues
                  final checkInDateTime = DateTime.parse(checkInTime).toLocal();
                  final workDuration =
                      DateTime.now().difference(checkInDateTime);
                  statusDetails.addAll([
                    Text(
                      'Since ${DateFormat('hh:mm a').format(checkInDateTime)}',
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

                  // Add break status information
                  if (breaks != null && breaks.isNotEmpty) {
                    // Find the most recent completed break
                    final completedBreaks =
                        breaks.where((b) => b['end'] != null).toList();
                    final totalBreaksToday = completedBreaks.length;

                    if (totalBreaksToday > 0) {
                      final mostRecentBreak = completedBreaks.last;
                      final breakTypeId = mostRecentBreak['type'];
                      final breakStartTime = mostRecentBreak['start'];
                      final breakEndTime = mostRecentBreak['end'];

                      if (breakStartTime != null && breakEndTime != null) {
                        // Parse and convert to local time to handle timezone issues
                        final breakStart =
                            DateTime.parse(breakStartTime).toLocal();
                        final breakEnd = DateTime.parse(breakEndTime).toLocal();
                        final breakDuration = breakEnd.difference(breakStart);

                        // Map break type ID to name
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
                                        '${DateFormat('hh:mm a').format(breakStart)} - ${DateFormat('hh:mm a').format(breakEnd)}',
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
                                    Text('${breakDuration.inMinutes} minutes',
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
                      // No breaks taken today
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
                    // No breaks data available
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
                } catch (e) {
                  // Error parsing checkInTime - continue without showing additional details
                }
              }
            }
            break;
          default:
            statusLabel = 'Status Not Available';
            statusIcon = Icons.info_outline;
            statusColor = Colors.grey;
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
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 30),
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
                IconButton(
                  icon: const Icon(Icons.refresh, size: 30),
                  onPressed: () {
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    final userId = authProvider.user?['_id'];
                    if (userId != null) {
                      attendanceProvider.fetchTodayStatus(userId);
                      // Note: fetchTodayStatus now also fetches currentAttendance data
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
  const _QuickActions({
    required this.isOnBreak,
    required this.clockIn,
    required this.clockOut,
    required this.startBreak,
    required this.endBreak,
    required this.applyLeave,
    required this.openTimesheet,
    required this.openProfile,
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
                          : const Color(0xFFE53E3E),
                      onPressed: isOnBreak ? null : clockOut,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.free_breakfast,
                      label: 'Start Break',
                      color: const Color(0xFF718096),
                      onPressed: startBreak,
                    ),
                  ),
                ],
              );
            } else if (status == 'on_break') {
              return Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.logout,
                      label: 'Clock Out',
                      color: const Color(0xFFB0B0B0),
                      onPressed:
                          null, // Optionally disable clock out during break
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.stop_circle,
                      label: 'End Break',
                      color: const Color(0xFFED8936),
                      onPressed: endBreak,
                    ),
                  ),
                ],
              );
            } else {
              return SizedBox(
                width: double.infinity,
                child: _buildQuickActionCard(
                  context,
                  icon: Icons.login,
                  label: 'Clock In',
                  color: const Color(0xFF38A169),
                  onPressed: clockIn,
                  isFullWidth: true,
                ),
              );
            }
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
              color: const Color(0xFF3182CE),
              onPressed: () => applyLeave(context),
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.access_time,
              label: 'Timesheet',
              color: const Color(0xFF805AD5),
              onPressed: () => openTimesheet(context),
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.person,
              label: 'Profile',
              color: const Color(0xFF319795),
              onPressed: () => openProfile(context),
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

    return Card(
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
          padding:
              const EdgeInsets.all(14), // Reduced padding to prevent overflow
          child: isFullWidth
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Prevent overflow
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 22, // Slightly smaller icon
                    ),
                    const SizedBox(height: 6), // Reduced spacing
                    Flexible(
                      // Make text flexible
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13, // Slightly smaller font
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
    );
  }
}

// NOTE: All document viewing actions must use in-app dialogs (see DocumentListItem), not url_launcher or external apps.
