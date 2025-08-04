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
import 'package:geolocator/geolocator.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../../../widgets/user_avatar.dart';
import '../../services/attendance_service.dart';
import 'live_clock.dart';
import 'package:sns_rooster/utils/color_utils.dart';
import '../../widgets/admin_side_navigation.dart';
import '../../widgets/notification_bell.dart';
import '../../providers/notification_provider.dart';
import '../../services/global_notification_service.dart';
import 'company_info_screen.dart';

import '../../widgets/real_time_break_timer.dart';

import '../notification/notification_screen.dart';
import 'package:sns_rooster/services/feature_service.dart';
import '../../widgets/employee_location_map_widget.dart';
import '../../services/fcm_service.dart';

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
  bool _isOnLeave = false;
  Map<String, dynamic>? _leaveInfo;

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

    // Show loading indicator
    final notificationService =
        Provider.of<GlobalNotificationService>(context, listen: false);
    notificationService.showInfo('Getting your location...');

    try {
      // Get current location
      double? latitude;
      double? longitude;

      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled');
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Location permission denied');
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permissions are permanently denied');
        }

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        latitude = position.latitude;
        longitude = position.longitude;
      } catch (locationError) {
        // If location fails, try clock-in without location (backend will handle)
        print('Location error: $locationError');
        latitude = null;
        longitude = null;
      }

      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final attendanceService = AttendanceService(authProvider);

      // Call check-in with location data
      await attendanceService.checkIn(
        userId,
        latitude: latitude,
        longitude: longitude,
      );

      await attendanceProvider.fetchTodayStatus(userId);
      notificationService.showSuccess('Clocked in successfully!');
    } catch (e) {
      String errorMessage = 'An error occurred while clocking in.';

      // Debug: Log the exact error string
      print('DEBUG: Raw error string: ${e.toString()}');

      // Handle specific error cases
      if (e.toString().contains('Already checked in for today')) {
        errorMessage = 'You have already clocked in for today.';
      } else if (e.toString().contains('E11000 duplicate key error')) {
        errorMessage =
            'A duplicate entry was detected. You might have already checked in.';
      } else if (e.toString().contains('on approved leave')) {
        errorMessage = 'You are on approved leave and cannot clock in.';
      } else if (e.toString().contains('Latitude and Longitude are required')) {
        errorMessage =
            'Location is required for clock-in. Please enable location services.';
      } else if (e.toString().contains('Invalid coordinates')) {
        errorMessage =
            'GPS signal is weak. Please move to an open area and try again.';
      } else if (e.toString().contains('400')) {
        // Try to extract JSON error message from the response FIRST
        try {
          final errorStr = e.toString();
          print('DEBUG: Attempting to parse JSON from: $errorStr');
          final jsonStart = errorStr.indexOf('{');
          if (jsonStart != -1) {
            final jsonStr = errorStr.substring(jsonStart);
            print('DEBUG: Extracted JSON string: $jsonStr');
            final errorData = json.decode(jsonStr);
            print('DEBUG: Parsed JSON data: $errorData');
            if (errorData['message'] != null) {
              errorMessage = errorData['message'];
              print('DEBUG: Using parsed message: $errorMessage');
            }
          } else {
            print('DEBUG: No JSON found in error string');
          }
        } catch (jsonError) {
          print('DEBUG: JSON parsing failed: $jsonError');
          // If JSON parsing fails, use the original error
          errorMessage = e
              .toString()
              .replaceAll('Exception: Failed to check in: 400 ', '');
        }
      } else if (e.toString().contains('away from') ||
          e.toString().contains('workplace')) {
        // Location validation failed - try to extract the specific message
        try {
          final errorStr = e.toString();
          final jsonStart = errorStr.indexOf('{');
          if (jsonStart != -1) {
            final jsonStr = errorStr.substring(jsonStart);
            final errorData = json.decode(jsonStr);
            if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            } else {
              errorMessage =
                  'You are too far from your workplace. Please move closer to check in.';
            }
          } else {
            errorMessage =
                'You are too far from your workplace. Please move closer to check in.';
          }
        } catch (jsonError) {
          errorMessage =
              'You are too far from your workplace. Please move closer to check in.';
        }
      } else if (e.toString().contains('Location validation failed') ||
          e.toString().contains('Unable to determine')) {
        errorMessage =
            'Unable to determine your location. Please check your GPS signal and try again.';
      }

      notificationService.showError(errorMessage);
    }
  }

  void _clockOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?['_id'];
    if (userId == null) {
      final notificationService =
          Provider.of<GlobalNotificationService>(context, listen: false);
      notificationService.showError('User not logged in. Please log in again.');
      return;
    }

    // Show loading indicator
    final notificationService =
        Provider.of<GlobalNotificationService>(context, listen: false);
    notificationService.showInfo('Getting your location...');

    try {
      // Get current location
      double? latitude;
      double? longitude;

      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled');
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Location permission denied');
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permissions are permanently denied');
        }

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        latitude = position.latitude;
        longitude = position.longitude;
      } catch (locationError) {
        // If location fails, try clock-out without location (backend will handle)
        print('Location error: $locationError');
        latitude = null;
        longitude = null;
      }

      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final attendanceService = AttendanceService(authProvider);

      // Call check-out with location data
      await attendanceService.checkOut(
        userId,
        latitude: latitude,
        longitude: longitude,
      );

      await attendanceProvider.fetchTodayStatus(userId);
      notificationService.showSuccess('Clocked out successfully!');
    } catch (e) {
      String errorMessage = 'Failed to clock out.';

      // Handle specific error cases
      if (e.toString().contains('Not checked in for today')) {
        errorMessage = 'You are not checked in for today.';
      } else if (e.toString().contains('away from') ||
          e.toString().contains('workplace')) {
        // Location validation failed - extract the specific message
        try {
          final errorStr = e.toString();
          final jsonStart = errorStr.indexOf('{');
          if (jsonStart != -1) {
            final jsonStr = errorStr.substring(jsonStart);
            final errorData = json.decode(jsonStr);
            if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            } else {
              errorMessage =
                  'You are too far from your workplace. Please move closer to check out.';
            }
          } else {
            errorMessage =
                'You are too far from your workplace. Please move closer to check out.';
          }
        } catch (jsonError) {
          errorMessage =
              'You are too far from your workplace. Please move closer to check out.';
        }
      } else if (e.toString().contains('Latitude and Longitude are required')) {
        errorMessage =
            'Location is required for clock-out. Please enable location services.';
      }

      notificationService.showError(errorMessage);
    }
  }

  Future<void> _startBreak() async {
    final selected = await _showBreakTypeSelectionDialog();
    if (selected == null) return;
    final uid = context.read<AuthProvider>().user!['_id'] as String;
    try {
      await context
          .read<AttendanceProvider>()
          .startBreakWithType(uid, selected);
      await context.read<AttendanceProvider>().fetchTodayStatus(uid);
      setState(() {
        _isOnBreak = true;
      });
    } catch (e) {
      String errorMessage = 'Failed to start break.';
      if (e.toString().contains('on approved leave')) {
        errorMessage = 'You are on approved leave and cannot take breaks.';
      }
      final notificationService =
          Provider.of<GlobalNotificationService>(context, listen: false);
      notificationService.showError(errorMessage);
    }
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
                                .withValues(alpha: 0.6),
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
        final data = json.decode(response.body);
        final List<dynamic> breakTypes = data['breakTypes'] ?? [];
        return List<Map<String, dynamic>>.from(breakTypes);
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

  // Build leave status widget
  Widget _buildLeaveStatusWidget() {
    if (_leaveInfo == null) return const SizedBox.shrink();

    final leaveType = _leaveInfo!['type'] ?? 'Leave';
    final startDate = DateTime.parse(_leaveInfo!['startDate']);
    final endDate = DateTime.parse(_leaveInfo!['endDate']);
    final reason = _leaveInfo!['reason'] ?? 'No reason provided';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade100, Colors.orange.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.beach_access,
                  color: Colors.orange.shade700,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'On Leave',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLeaveInfoRow('Type', leaveType),
            _buildLeaveInfoRow(
                'From', DateFormat('MMM dd, yyyy').format(startDate)),
            _buildLeaveInfoRow(
                'To', DateFormat('MMM dd, yyyy').format(endDate)),
            if (reason.isNotEmpty) _buildLeaveInfoRow('Reason', reason),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade200.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attendance actions are disabled during your leave period.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade800,
                  ),
            ),
          ),
        ],
      ),
    );
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

  @override
  void initState() {
    super.initState();
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

          // Check for leave status from the provider
          final leaveInfo = attendanceProvider.leaveInfo;
          setState(() {
            _isOnLeave = leaveInfo != null;
            _leaveInfo = leaveInfo;
          });
        });
        Provider.of<AttendanceProvider>(context, listen: false)
            .fetchAttendanceSummary(userId);
      }
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
      // Load features for the dashboard
      final authProviderForFeatures =
          Provider.of<AuthProvider>(context, listen: false);
      if (authProviderForFeatures.featureProvider != null) {
        authProviderForFeatures.featureProvider!.loadFeatures();
      }
      // Fetch upcoming events
      _fetchUpcomingEvents();
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
    // Listen for attendance toast
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    if (attendanceProvider.toastMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ScaffoldMessenger.maybeOf(context) != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(attendanceProvider.toastMessage!)),
          );
          attendanceProvider.clearToast();
        }
      });
    }

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
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
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
            // Location Information Card
            _buildLocationInfoCard(),
            const SizedBox(height: 28),
            // Leave Status Widget
            if (_isOnLeave && _leaveInfo != null) ...[
              _buildLeaveStatusWidget(),
              const SizedBox(height: 28),
            ],
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
              isOnLeave: _isOnLeave,
              clockIn: _clockIn,
              clockOut: _clockOut,
              startBreak: _startBreak,
              endBreak: _endBreak,
              applyLeave: (ctx) => _applyLeave(ctx),
              openTimesheet: (ctx) => _openTimesheet(ctx),
              openProfile: (ctx) => _openProfile(ctx),
              openEvents: (ctx) => _openEvents(ctx),
              openCompanyInfo: (ctx) => _openCompanyInfo(ctx),
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

  void _openCompanyInfo(BuildContext context) {
    print('EMPLOYEE DASHBOARD: Navigating to Company Info Screen');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompanyInfoScreen(),
      ),
    );
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
        final isAttending = attendees.any((attendee) =>
            attendee['user'] == currentUserId ||
            attendee['userId'] == currentUserId);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAttending
                      ? Colors.green.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isAttending ? Icons.event_available : Icons.event,
                  color: isAttending
                      ? Colors.green.shade600
                      : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'] ?? 'Untitled Event',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • HH:mm').format(eventDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAttending
                      ? Colors.green.shade100
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAttending ? 'Attending' : 'Not Attending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isAttending
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationInfoCard() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final profile = profileProvider.profile;
        final assignedLocation = profile?['assignedLocation'];

        if (assignedLocation == null) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade50, Colors.orange.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_off_rounded,
                    color: Colors.orange.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Location Assigned',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contact your administrator to assign a work location for clock-in',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.orange.shade700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.indigo.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with location icon and status
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.indigo.shade400
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Work Location',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.blue.shade600,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            assignedLocation['name'] ?? 'Unknown Location',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.blue.shade200,
                      Colors.transparent
                    ],
                  ),
                ),
              ),

              // Location details
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Address
                    if (assignedLocation['address'] != null) ...[
                      _buildDetailRow(
                        icon: Icons.place_rounded,
                        iconColor: Colors.blue.shade600,
                        title: 'Address',
                        value: _buildAddressString(assignedLocation['address']),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Geofence and coordinates
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailRow(
                            icon: Icons.radio_button_checked_rounded,
                            iconColor: Colors.green.shade600,
                            title: 'Geofence',
                            value:
                                '${assignedLocation['settings']?['geofenceRadius'] ?? 100}m radius',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDetailRow(
                            icon: Icons.gps_fixed_rounded,
                            iconColor: Colors.purple.shade600,
                            title: 'Coordinates',
                            value:
                                '${assignedLocation['coordinates']?['latitude']?.toStringAsFixed(6) ?? 'N/A'}, ${assignedLocation['coordinates']?['longitude']?.toStringAsFixed(6) ?? 'N/A'}',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Location Map
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.map_rounded,
                                  size: 16,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Location Map',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          EmployeeLocationMapWidget(
                            location: assignedLocation,
                            height: 180,
                            showGeofence: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Working hours
                    if (assignedLocation['settings']?['workingHours'] !=
                        null) ...[
                      _buildDetailRow(
                        icon: Icons.access_time_rounded,
                        iconColor: Colors.orange.shade600,
                        title: 'Working Hours',
                        value:
                            '${assignedLocation['settings']['workingHours']['start'] ?? '09:00'} - ${assignedLocation['settings']['workingHours']['end'] ?? '17:00'}',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildAddressString(Map<String, dynamic> address) {
    if (address['fullAddress']?.isNotEmpty == true) {
      return address['fullAddress'];
    }

    // Build address from components
    final parts = <String>[];

    // Add street address if available
    if (address['street']?.isNotEmpty == true) {
      parts.add(address['street']);
    }

    // Add city if available
    if (address['city']?.isNotEmpty == true) {
      parts.add(address['city']);
    }

    // Add state/province if available
    if (address['state']?.isNotEmpty == true) {
      parts.add(address['state']);
    }

    // Add postal code if available
    if (address['postalCode']?.isNotEmpty == true) {
      parts.add(address['postalCode']);
    }

    // Add country if available
    if (address['country']?.isNotEmpty == true) {
      parts.add(address['country']);
    }

    // If no structured address, try to use coordinates
    if (parts.isEmpty) {
      return 'Coordinates available';
    }

    return parts.join(', ');
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
            color: Colors.blue.shade100.withValues(alpha: 0.3),
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
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3)),
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
                        const SizedBox(height: 8),
                        // Real-time break timer widget
                        RealTimeBreakTimer(
                          breakStartTime: breakStartTime,
                          breakTypeName: breakTypeName,
                          maxDurationMinutes:
                              15, // Default coffee break duration
                          totalBreaksToday: totalBreaksToday,
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
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.3)),
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
                                    Text(_formatDuration(breakDuration),
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
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3)),
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
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3)),
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

class _QuickActions extends StatefulWidget {
  final bool isOnBreak;
  final bool isOnLeave;
  final VoidCallback clockIn;
  final VoidCallback clockOut;
  final VoidCallback startBreak;
  final VoidCallback endBreak;
  final Function(BuildContext) applyLeave;
  final Function(BuildContext) openTimesheet;
  final Function(BuildContext) openProfile;
  final Function(BuildContext) openEvents;
  final Function(BuildContext) openCompanyInfo;
  const _QuickActions({
    required this.isOnBreak,
    required this.isOnLeave,
    required this.clockIn,
    required this.clockOut,
    required this.startBreak,
    required this.endBreak,
    required this.applyLeave,
    required this.openTimesheet,
    required this.openProfile,
    required this.openEvents,
    required this.openCompanyInfo,
  });

  @override
  State<_QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<_QuickActions> {
  Map<String, bool> _availableFeatures = {};
  bool _loadingFeatures = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableFeatures();
  }

  Future<void> _loadAvailableFeatures() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final featureService = FeatureService(authProvider);
      final features = await featureService.getAvailableFeatures();

      if (mounted) {
        setState(() {
          _availableFeatures = features;
          _loadingFeatures = false;
        });
      }
    } catch (e) {
      print('Error loading features: $e');
      if (mounted) {
        setState(() {
          _loadingFeatures = false;
          // Default to basic features if there's an error
          _availableFeatures = {
            'attendance': true,
            'profile': true,
            'notifications': true,
            'timesheet': true,
            'events': true,
            'companyInfo': true,
          };
        });
      }
    }
  }

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
                    Text(
                      widget.isOnLeave
                          ? 'You are on leave and cannot clock in.'
                          : 'You have not clocked in today.',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.grey[800]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'Clock In',
                      button: true,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text('Clock In'),
                        onPressed: widget.isOnLeave ? null : widget.clockIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isOnLeave
                              ? Colors.grey.shade400
                              : const Color(0xFF1976D2), // Vibrant blue
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
                      color: (widget.isOnBreak || widget.isOnLeave)
                          ? const Color(0xFFB0B0B0)
                          : const Color(0xFFF44336), // Vibrant red
                      onPressed: (widget.isOnBreak || widget.isOnLeave)
                          ? null
                          : widget.clockOut,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.free_breakfast,
                      label: 'Start Break',
                      color: widget.isOnLeave
                          ? const Color(0xFFB0B0B0)
                          : const Color(0xFF00BCD4), // Vibrant cyan
                      onPressed: widget.isOnLeave ? null : widget.startBreak,
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
                      color: widget.isOnLeave
                          ? const Color(0xFFB0B0B0)
                          : const Color(0xFFE91E63), // Vibrant pink
                      onPressed: widget.isOnLeave ? null : widget.endBreak,
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
                color: widget.isOnLeave
                    ? const Color(0xFFB0B0B0)
                    : const Color(0xFF1976D2), // Vibrant blue
                onPressed: widget.isOnLeave ? null : widget.clockIn,
                isFullWidth: true,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _loadingFeatures
            ? const Center(child: CircularProgressIndicator())
            : GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
                children: [
                  // Apply Leave - only if leaveManagement is enabled
                  if (_availableFeatures['leaveManagement'] == true)
                    _buildQuickActionCard(
                      context,
                      icon: Icons.calendar_today,
                      label: 'Apply Leave',
                      color: const Color(0xFF4CAF50), // Vibrant green
                      onPressed: () => widget.applyLeave(context),
                    ),
                  // Timesheet - always available for employees
                  _buildQuickActionCard(
                    context,
                    icon: Icons.access_time,
                    label: 'Timesheet',
                    color: const Color(0xFF9C27B0), // Vibrant purple
                    onPressed: () => widget.openTimesheet(context),
                  ),
                  // Profile - always available
                  _buildQuickActionCard(
                    context,
                    icon: Icons.person,
                    label: 'Profile',
                    color: const Color(0xFF2196F3), // Vibrant blue
                    onPressed: () => widget.openProfile(context),
                  ),
                  // Events - always available for employees
                  _buildQuickActionCard(
                    context,
                    icon: Icons.event,
                    label: 'Events',
                    color: const Color(0xFFFF9800), // Vibrant orange
                    onPressed: () => widget.openEvents(context),
                  ),
                  // Company Info - always available for employees
                  _buildQuickActionCard(
                    context,
                    icon: Icons.business,
                    label: 'Company Info',
                    color: const Color(0xFF607D8B), // Vibrant blue-grey
                    onPressed: () => widget.openCompanyInfo(context),
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
    final cardColor = isDisabled ? color.withValues(alpha: 0.5) : color;

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
                colors: [cardColor, cardColor.withValues(alpha: 0.8)],
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
