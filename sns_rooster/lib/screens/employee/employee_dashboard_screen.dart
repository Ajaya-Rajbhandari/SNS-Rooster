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
import '../../providers/attendance_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/auth_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../widgets/user_avatar.dart';
import 'package:flutter/widgets.dart';
import '../../../main.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> with RouteAware {
  bool _isClockedIn = false;
  bool _isOnBreak = false;
  bool _profileDialogShown = false;
  String _lastSavedProfileJson = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes using the global routeObserver
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    try {
      Provider.of<ProfileProvider>(context, listen: false);
      // print('DEBUG: ProfileProvider is accessible in EmployeeDashboardScreen');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        final profile = profileProvider.profile;
        if (profile != null && profile['isProfileComplete'] == false && !_profileDialogShown) {
          setState(() {
            _profileDialogShown = true;
          });
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Complete Your Profile'),
              content: const Text('For your safety and to access all features, please complete your profile information.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Dismiss'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushNamed('/profile');
                  },
                  child: const Text('Update Now'),
                ),
              ],
            ),
          );
        }
      });
    } catch (e) {
      print(
          'ERROR: ProfileProvider is not accessible in EmployeeDashboardScreen: \$e');
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?['_id'];
    if (userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<AttendanceProvider>(context, listen: false)
            .fetchUserAttendance(userId);
      });
    }
  }

  @override
  void dispose() {
    // Unsubscribe from route changes
    final routeObserver = Provider.of<RouteObserver<ModalRoute<void>>>(context, listen: false);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back to this screen
    // Only refresh if profile data might be stale (e.g., after 5 minutes)
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final lastUpdate = profileProvider.lastUpdated;
    final now = DateTime.now();
    
    if (lastUpdate == null || now.difference(lastUpdate).inMinutes > 5) {
      profileProvider.refreshProfile();
    }
    setState(() {});
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
    if (userId != null) {
      try {
        final attendanceProvider =
            Provider.of<AttendanceProvider>(context, listen: false);
        await attendanceProvider.clockIn(userId);
        setState(() {
          _isClockedIn = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clocked in successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to clock in. Please try again.')),
        );
      }
    }
  }

  void _clockOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?['_id'];
    if (userId != null) {
      try {
        final attendanceProvider =
            Provider.of<AttendanceProvider>(context, listen: false);
        await attendanceProvider.clockOut(userId);
        setState(() {
          _isClockedIn = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clocked out successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to clock out. Please try again.')),
        );
      }
    }
  }

  void _startBreak() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?['_id'];
    if (userId != null) {
      try {
        final attendanceProvider =
            Provider.of<AttendanceProvider>(context, listen: false);
        await attendanceProvider.startBreak(userId);
        setState(() {
          _isOnBreak = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Break started successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to start break. Please try again.')),
        );
      }
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
        setState(() {
          _isOnBreak = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Break ended successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to end break. Please try again.')),
        );
      }
    }
  }

  void _showConfirmationDialog(String action, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text('Are you sure you want to $action?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // Add network connectivity check
   /// Indicates whether the device is currently connected to a network.
  /// This is updated by [_checkNetworkConnectivity] and reflected in the app bar icon.
  bool _isConnected = true; // Assume connected by default

  @override
  void initState() {
    super.initState();
    _checkNetworkConnectivity();
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
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final profile = profileProvider.profile;

    // Only save profile to SharedPreferences if it has changed
    if (profile != null) {
      if (_lastSavedProfileJson != json.encode(profile)) {
        _saveProfileToSharedPreferences(profile);
        _lastSavedProfileJson = json.encode(profile);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        actions: [
          /// Shows a green WiFi icon if connected, red WiFi-off icon if not connected.
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: _isConnected ? Colors.green : Colors.red,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
              child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Redesigned Header
                    Container(
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
                            offset: Offset(0, 6),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome Back, ${profile != null ? '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim() : 'Guest'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  profile?['role'] ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white70,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications,
                                color: Colors.white),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Redesigned Status Card
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Status",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  'Current Time',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Spacer(),
                                StreamBuilder(
                                  stream: Stream.periodic(const Duration(seconds: 1)),
                                  builder: (context, snapshot) {
                                    final now = TimeOfDay.now();
                                    return Text(
                                      now.format(context),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 24, thickness: 1),
                            Row(
                              children: [
                                Text(
                                  'Your Status',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Icon(
                                        _isClockedIn
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: _isClockedIn
                                            ? Colors.green
                                            : Colors.red),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isClockedIn
                                          ? 'Clocked In'
                                          : 'Not Clocked In',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: _isClockedIn
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Redesigned Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isClockedIn ? _clockOut : _clockIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isClockedIn ? Colors.red : Colors.green,
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Icon(
                                _isClockedIn ? Icons.logout : Icons.login,
                                color: Colors.white),
                            label:
                                Text(_isClockedIn ? 'Clock Out' : 'Clock In'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _applyLeave(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.calendar_today,
                                color: Colors.white),
                            label: const Text('Apply Leave'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openTimesheet(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.access_time,
                                color: Colors.white),
                            label: const Text('Timesheet'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isClockedIn)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isOnBreak ? _endBreak : _startBreak,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _isOnBreak ? Colors.orange : Colors.blueGrey,
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: Icon(
                                  _isOnBreak ? Icons.stop_circle : Icons.free_breakfast,
                                  color: Colors.white),
                              label:
                                  Text(_isOnBreak ? 'End Break' : 'Start Break'),
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ));
        },
      ),
    );
  }
}

// Correct the usage of context in methods
void _applyLeave(BuildContext context) {
  // Implement leave application logic here
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Leave application feature coming soon!')),
  );
}

void _openTimesheet(BuildContext context) {
  // Implement timesheet opening logic here
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Timesheet feature coming soon!')),
  );
}

// Remove duplicate declarations
