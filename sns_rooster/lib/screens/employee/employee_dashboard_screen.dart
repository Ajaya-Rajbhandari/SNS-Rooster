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
import '../../providers/attendance_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
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

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen>
    with RouteAware {
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
        _checkProfileCompletion();
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
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/break-types'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['breakTypes']);
      }
    } catch (e) {
      print('Error fetching break types: $e');
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: SingleChildScrollView(
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
                                      ? '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'
                                          .trim()
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
                                  _capitalizeFirstLetter(
                                      profile?['role'] ?? ''),
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
                                  stream: Stream.periodic(
                                      const Duration(seconds: 1)),
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
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final isTablet = screenWidth > 600;
                        final crossAxisCount = isTablet ? 3 : 2;
                        final childAspectRatio = isTablet ? 2.1 : 1.9;

                        return Column(
                          children: [
                            // Clock In/Out Section (Always at top)
                            if (!_isClockedIn)
                              // Single Clock In button when not clocked in
                              SizedBox(
                                width: double.infinity,
                                child: _buildQuickActionCard(
                                  context,
                                  icon: Icons.login,
                                  label: 'Clock In',
                                  color: const Color(0xFF38A169),
                                  onPressed: _clockIn,
                                  isFullWidth: true,
                                ),
                              )
                            else
                              // Clock Out and Break buttons when clocked in
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildQuickActionCard(
                                      context,
                                      icon: Icons.logout,
                                      label: 'Clock Out',
                                      color: _isOnBreak
                                          ? const Color(0xFFB0B0B0)
                                          : const Color(0xFFE53E3E),
                                      onPressed: _isOnBreak
                                          ? null
                                          : _clockOut, // Disable when on break
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildQuickActionCard(
                                      context,
                                      icon: _isOnBreak ? Icons.stop_circle : Icons.free_breakfast,
                                      label: _isOnBreak ? 'End Break' : 'Start Break',
                                      color: _isOnBreak ? const Color(0xFFED8936) : const Color(0xFF718096),
                                      onPressed: _isOnBreak ? _endBreak : _startBreak,
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 16),

                            // Other Actions Grid
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
                                  onPressed: () => _applyLeave(context),
                                ),
                                _buildQuickActionCard(
                                  context,
                                  icon: Icons.access_time,
                                  label: 'Timesheet',
                                  color: const Color(0xFF805AD5),
                                  onPressed: () => _openTimesheet(context),
                                ),
                                _buildQuickActionCard(
                                  context,
                                  icon: Icons.person,
                                  label: 'Profile',
                                  color: const Color(0xFF319795),
                                  onPressed: () => _openProfile(context),
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

// Remove duplicate declarations
