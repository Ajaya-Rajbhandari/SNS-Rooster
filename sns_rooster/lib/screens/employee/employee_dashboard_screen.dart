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
import '../../../main.dart';
import '../../services/attendance_service.dart';
import 'live_clock.dart';

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
  DateTime? _startDate;
  DateTime? _endDate;

  // Track last fetched params to avoid duplicate fetches
  String? _lastSummaryUserId;
  DateTime? _lastSummaryStart;
  DateTime? _lastSummaryEnd;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes using the global routeObserver
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    try {
      Provider.of<ProfileProvider>(context, listen: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkProfileCompletion();
        // Fetch backend-driven attendance status for today
        final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.user?['_id'];
        if (userId != null) {
          attendanceProvider.fetchTodayStatus(userId);
        }
      });
    } catch (e) {
      print('ERROR: ProfileProvider is not accessible in EmployeeDashboardScreen: $e');
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?['_id'];
    if (userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<AttendanceProvider>(context, listen: false).fetchUserAttendance(userId).then((_) {
          // No need to set _isClockedIn here; UI now uses provider state
        });
      });
    }
  }

  @override
  void dispose() {
    // Unsubscribe from route changes
    final routeObserver =
        Provider.of<RouteObserver<ModalRoute<void>>>(context, listen: false);
    routeObserver.unsubscribe(this);
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
    print('DEBUG: Attempting check-in with userId: ${userId?.toString() ?? 'null'}');
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in. Please log in again.')),
      );
      return;
    }
    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final attendanceService = AttendanceService(authProvider);
      print('DEBUG: Fetched userId from AuthProvider: ${authProvider.user?['_id']?.toString() ?? 'null'}');
      await attendanceService.checkIn(userId);
      await attendanceProvider.fetchTodayStatus(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clocked in successfully!')),
      );
    } catch (e) {
      String errorMessage = 'An error occurred while clocking in.';
      if (e.toString().contains('Already checked in for today')) {
        errorMessage = 'You have already clocked in for today.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    }
  }

  void _clockOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?['_id'];
    if (userId != null) {
      try {
        final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
        final attendanceService = AttendanceService(authProvider);
        await attendanceService.checkOut(userId);
        await attendanceProvider.fetchTodayStatus(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clocked out successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to clock out: \\${e.toString()}')),
        );
      }
    }
  }

  void _startBreak() async {
    // Show break type selection dialog
    final selectedBreakType = await _showBreakTypeSelectionDialog();
    if (selectedBreakType == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?['_id'];
    if (userId != null) {
      try {
        final attendanceProvider =
            Provider.of<AttendanceProvider>(context, listen: false);
        await attendanceProvider.startBreakWithType(userId, selectedBreakType);
        setState(() {
          _isOnBreak = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedBreakType['displayName']} started successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to start break. Please try again.')),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showBreakTypeSelectionDialog() async {
    // Fetch available break types
    final breakTypes = await _fetchBreakTypes();
    if (breakTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No break types available')),
      );
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
                    color: Color(int.parse(breakType['color'].replaceFirst('#', '0xFF'))),
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
      print('FETCH_BREAK_TYPES_DEBUG: Sending request to ${ApiConfig.baseUrl}/attendance/break-types');
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      print('FETCH_BREAK_TYPES_DEBUG: Token being sent: $token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/break-types'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer \$token',
        },
      );

      print('FETCH_BREAK_TYPES_DEBUG: Response status code: ${response.statusCode}');
      print('FETCH_BREAK_TYPES_DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('FETCH_BREAK_TYPES_DEBUG: Parsed data: $data');
        return List<Map<String, dynamic>>.from(data['breakTypes']);
      }
    } catch (e) {
      print('FETCH_BREAK_TYPES_DEBUG: Error fetching break types: $e');
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?['_id'];
      if (userId != null && _startDate == null && _endDate == null) {
        if (_lastSummaryUserId != userId || _lastSummaryStart != null || _lastSummaryEnd != null) {
          _lastSummaryUserId = userId;
          _lastSummaryStart = null;
          _lastSummaryEnd = null;
          Provider.of<AttendanceProvider>(context, listen: false)
              .fetchAttendanceSummary(userId);
        }
      }
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

  void _pickDateRange(BuildContext context, String userId) async {
    final initialStart = _startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final initialEnd = _endDate ?? DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );
    if (picked != null) {
      if (_lastSummaryUserId != userId || _lastSummaryStart != picked.start || _lastSummaryEnd != picked.end) {
        setState(() {
          _startDate = picked.start;
          _endDate = picked.end;
          _lastSummaryUserId = userId;
          _lastSummaryStart = picked.start;
          _lastSummaryEnd = picked.end;
        });
        Provider.of<AttendanceProvider>(context, listen: false)
            .fetchAttendanceSummary(userId, startDate: _startDate, endDate: _endDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?['_id'];
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DashboardHeader(profile: profile),
              const SizedBox(height: 28),
              const _StatusCard(),
              const SizedBox(height: 28),
              if (userId != null)
                Row(
                  children: [
                    Text(_startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : 'Start Date'),
                    const SizedBox(width: 8),
                    Text(_endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : 'End Date'),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _pickDateRange(context, userId),
                      child: const Text('Select Range'),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
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
            ],
          ),
        ),
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

// Helper method to capitalize first letter
String _capitalizeFirstLetter(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

// Helper method to build quick action cards
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
        padding: const EdgeInsets.all(16),
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
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    ),
  );
}

void _openProfile(BuildContext context) {
  // Implement profile opening logic here
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Profile feature coming soon!')),
  );
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
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile != null
                      ? '${profile?['firstName'] ?? ''} ${profile?['lastName'] ?? ''}'.trim()
                      : 'Guest',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _capitalizeFirstLetter(profile?['role'] ?? ''),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard();
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  "Today's Attendance Status",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Current Time:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                const LiveClock(),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<AttendanceProvider>(
              builder: (context, attendanceProvider, _) {
                final summary = attendanceProvider.attendanceSummary;
                if (attendanceProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (summary == null || (summary['totalDaysPresent'] == 0 && summary['totalHoursWorked'] == 0)) {
                  return const Text('No attendance records for this range.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Days Present:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Text(
                          '${summary['totalDaysPresent']} Days',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.hourglass_bottom, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Hours Worked:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Text(
                          '${summary['totalHoursWorked']} Hours',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.sync, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Status:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Chip(
                          label: Text(
                            'Checked In',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
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
                      color: isOnBreak ? const Color(0xFFB0B0B0) : const Color(0xFFE53E3E),
                      onPressed: isOnBreak ? null : clockOut,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: isOnBreak ? Icons.stop_circle : Icons.free_breakfast,
                      label: isOnBreak ? 'End Break' : 'Start Break',
                      color: isOnBreak ? const Color(0xFFED8936) : const Color(0xFF718096),
                      onPressed: isOnBreak ? endBreak : startBreak,
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
}
