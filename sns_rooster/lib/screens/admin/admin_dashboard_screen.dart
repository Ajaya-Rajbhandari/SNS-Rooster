import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import 'package:sns_rooster/config/api_config.dart';
import 'package:sns_rooster/screens/admin/employee_management_screen.dart';
import 'package:sns_rooster/screens/admin/payroll_management_screen.dart';
import 'package:sns_rooster/screens/admin/leave_management_screen.dart';
import 'package:sns_rooster/screens/admin/notification_alert_screen.dart';
import 'package:sns_rooster/screens/admin/settings_screen.dart';
import 'package:sns_rooster/screens/admin/help_support_screen.dart';
import 'package:sns_rooster/screens/admin/attendance_management_screen.dart';
import 'package:sns_rooster/screens/admin/break_management_screen.dart';
import '../../widgets/admin_side_navigation.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Placeholder for dashboard data
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for user changes and refresh dashboard data
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.user != null) {
      // If the user has changed, re-fetch dashboard data
      _fetchDashboardData();
    }
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      String userName = authProvider.user?['name'] as String? ?? 'Admin';

      int totalEmployees = 0;
      int presentToday = 0;
      int onLeave = 0;
      int pendingRequests = 0;
      int absentToday = 0;
      Map<String, dynamic> departmentStats = {};
      List<dynamic> recentActivities = [];
      List<dynamic> attendanceChart = [];

      // Fetch total employees and department stats
      final usersResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (usersResponse.statusCode == 200) {
        final usersData = jsonDecode(usersResponse.body);
        if (usersData is List) {
          final usersList =
              usersData.where((user) => user['role'] == 'employee').toList();
          totalEmployees = usersList.length;
          for (var user in usersList) {
            final department = user['department'] ?? 'Unknown';
            if (departmentStats.containsKey(department)) {
              departmentStats[department]['total'] =
                  (departmentStats[department]['total'] ?? 0) + 1;
            } else {
              departmentStats[department] = {
                'total': 1,
                'present': 0,
              };
            }
          }
        } else {
          throw Exception('Unexpected data format for users');
        }
      } else {
        print(
            'Failed to load users: ${usersResponse.statusCode} ${usersResponse.body}');
        throw Exception('Failed to load users');
      }

      // Fetch attendance stats
      final attendanceResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/today'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (attendanceResponse.statusCode == 200) {
        final attendanceData = jsonDecode(attendanceResponse.body);
        if (attendanceData is Map &&
            attendanceData.containsKey('present') &&
            attendanceData.containsKey('absent') &&
            attendanceData.containsKey('onLeave')) {
          presentToday = attendanceData['present'] ?? 0;
          absentToday = attendanceData['absent'] ?? 0;
          onLeave = attendanceData['onLeave'] ?? 0;
        }
      } else {
        print(
            'Attendance endpoint failed: ${attendanceResponse.statusCode} ${attendanceResponse.body}');
      }

      // Fetch leave requests (pending)
      try {
        final employeeId = authProvider.user?['employeeId'];
        if (employeeId == null) {
          print('Error: employeeId is undefined for leave history request.');
          pendingRequests = 0;
        } else {
          final leaveRequestsResponse = await http.get(
            Uri.parse(
                '${ApiConfig.baseUrl}/leave/history?employeeId=$employeeId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          if (leaveRequestsResponse.statusCode == 200) {
            final leaveRequestsData = jsonDecode(leaveRequestsResponse.body);
            if (leaveRequestsData is Map &&
                leaveRequestsData.containsKey('leaveRequests')) {
              final leaveRequestsList = leaveRequestsData['leaveRequests'];
              if (leaveRequestsList is List) {
                pendingRequests = leaveRequestsList
                    .where((req) => req['status'] == 'pending')
                    .length;
              }
            }
          } else {
            print(
                'Failed to load leave requests: ${leaveRequestsResponse.statusCode} ${leaveRequestsResponse.body}');
          }
        }
      } catch (e) {
        print('Error fetching leave requests: $e');
        pendingRequests = 0;
      }

      // Optionally: Fetch recent activities and chart data if you have endpoints
      // (Retain your previous logic for these, or leave as empty for now)

      _dashboardData = {
        'welcomeMessage': 'Welcome, $userName!',
        'overviewText': 'Here\'s an overview of your admin dashboard.',
        'quickStats': {
          'totalEmployees': totalEmployees,
          'presentToday': presentToday,
          'onLeave': onLeave,
          'pendingRequests': pendingRequests,
          'absentToday': absentToday,
        },
        'departmentStats': departmentStats,
        'recentActivities': recentActivities,
        'chartData': {
          'attendance': attendanceChart,
        }
      };

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userName = user?['name'] ?? 'Admin';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      drawer: const AdminSideNavigation(currentRoute: '/admin_dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (_errorMessage != null) ...[
              Center(
                  child: Text('Error:  _errorMessage',
                      style: TextStyle(color: theme.colorScheme.error))),
            ] else ...[
              // --- Modern Analytics Section ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $userName!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(now),
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 24),
                  // Modern Stat Card Row
                  _buildStatCardRow(),
                  const SizedBox(height: 24),
                  // Attendance Pie Chart
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Today\'s Attendance',
                              style: theme.textTheme.titleLarge),
                          const SizedBox(height: 16),
                          SizedBox(
                              height: 200, child: _buildAttendancePieChart()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Upcoming Events (placeholder)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Upcoming Events',
                                  style: theme.textTheme.titleLarge),
                              TextButton(
                                  onPressed: () {},
                                  child: const Text('View All')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Events coming soon!'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Recent Activities (placeholder)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Recent Activities',
                                  style: theme.textTheme.titleLarge),
                              TextButton(
                                  onPressed: () {},
                                  child: const Text('View All')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Recent activities coming soon!'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Department Stats Table
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Department-wise Attendance',
                              style: theme.textTheme.titleLarge),
                          const SizedBox(height: 16),
                          _buildDepartmentStatsTable(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // TODO: Implement Upcoming Events and Recent Activities with real data
                ],
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Quick Actions & Shortcuts',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildPaginatedQuickActions(context),
            const SizedBox(height: 24),
            Text(
              'Real-Time Data & Analytics',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
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
                      'Charts & Graphs',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    // TODO: Implement _buildChartsSection with real data
                    // For now, showing a placeholder if no chart data is fetched
                    _dashboardData['chartData'] != null &&
                            (_dashboardData['chartData']['attendance'] as List)
                                .isNotEmpty
                        ? _buildChartsSection(theme)
                        : const Text(
                            'Chart data not available. (TODO: Connect to API)',
                            style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    Text(
                      'Live Metrics',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          context,
                          icon: Icons.people,
                          label: 'Employees',
                          value: '10',
                        ),
                        _buildSummaryItem(
                          context,
                          icon: Icons.payments,
                          label: 'Payslips',
                          value: '50',
                        ),
                        _buildSummaryItem(
                          context,
                          icon: Icons.notifications,
                          label: 'Notifications',
                          value: '5',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Notifications & Alerts',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
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
                      'Notification Center',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('Notifications coming soon!'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Alert Banner',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Critical: Payroll deadline approaching!',
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Employee Management',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
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
                      'Employee Directory',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('Employee Directory coming soon!'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to Add Employee screen
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add New Employee'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payroll Insights',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // --- Payroll Insights Section ---
            _PayrollInsightsSection(),
            const SizedBox(height: 24),
            Text(
              'Settings & Configuration',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
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
                      'Admin Preferences',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('Admin Preferences coming soon!'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'System Configuration',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('System Configuration coming soon!'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Help & Support',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
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
                      'FAQ or Help Center',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('FAQ coming soon!'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to Contact Support screen
                      },
                      icon: const Icon(Icons.contact_support),
                      label: const Text('Contact Support'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Security & Compliance',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
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
                      'Audit Logs',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('Audit Logs coming soon!'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Compliance Alerts',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('Compliance Alerts coming soon!'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Integration with External Tools',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
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
                      'Calendar Integration',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('Calendar Integration coming soon!'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Export Options',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('Export Options coming soon!'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context,
      {required IconData icon, required String label, required String value}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 40, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value, style: theme.textTheme.titleLarge),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.withOpacity(0.7), Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingEventsSection(ThemeData theme) {
    if (_isLoading ||
        _dashboardData['upcomingEvents'] == null ||
        (_dashboardData['upcomingEvents'] as List).isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('Events coming soon!'),
        ),
      );
    }

    List<dynamic> events = _dashboardData['upcomingEvents'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...events.map((event) => Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.event),
                title: Text(event['title'] ?? 'Untitled Event'),
                subtitle: Text(event['date'] ?? 'No date provided'),
              ),
            )),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // Navigate to detailed events page
            },
            child: const Text('View All'),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitiesSection(ThemeData theme) {
    if (_isLoading ||
        _dashboardData['recentActivities'] == null ||
        (_dashboardData['recentActivities'] as List).isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('Recent activities coming soon!'),
        ),
      );
    }

    List<dynamic> activities = _dashboardData['recentActivities'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...activities.map((activity) => Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(activity['description'] ?? 'No description'),
                subtitle: Text(activity['timestamp'] ?? 'No timestamp'),
              ),
            )),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // Navigate to detailed activities page
            },
            child: const Text('View All'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(10), // Reduced from 16
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 24), // Reduced from 28
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // Reduced from 16
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // Reduced from 12
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20, // Reduced from 24
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Modern Dashboard Widgets ---
  Widget _buildStatCardRow() {
    final stats = [
      {
        'title': 'Total Employees',
        'value':
            _dashboardData['quickStats']?['totalEmployees'].toString() ?? '0',
        'icon': Icons.people,
        'color': Theme.of(context).colorScheme.primary
      },
      {
        'title': 'Present',
        'value':
            _dashboardData['quickStats']?['presentToday'].toString() ?? '0',
        'icon': Icons.check_circle,
        'color': Colors.green
      },
      {
        'title': 'On Leave',
        'value': _dashboardData['quickStats']?['onLeave'].toString() ?? '0',
        'icon': Icons.event_busy,
        'color': Theme.of(context).colorScheme.secondary
      },
      {
        'title': 'Absent',
        'value': _dashboardData['quickStats']?['absentToday'].toString() ?? '0',
        'icon': Icons.cancel,
        'color': Colors.red
      },
      {
        'title': 'Pending',
        'value':
            _dashboardData['quickStats']?['pendingRequests'].toString() ?? '0',
        'icon': Icons.pending_actions,
        'color': Colors.orange
      },
    ];
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => SizedBox(
          width: 160,
          child: _buildStatCard(
            stats[i]['title'] as String,
            stats[i]['value'] as String,
            stats[i]['icon'] as IconData,
            stats[i]['color'] as Color,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendancePieChart() {
    final present =
        (_dashboardData['quickStats']?['presentToday'] ?? 0).toDouble();
    final absent =
        (_dashboardData['quickStats']?['absentToday'] ?? 0).toDouble();
    final onLeave = (_dashboardData['quickStats']?['onLeave'] ?? 0).toDouble();
    final total = present + absent + onLeave;
    if (total == 0) {
      return const Center(child: Text('No attendance data.'));
    }
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: present,
            title: 'Present',
            color: Colors.green,
            radius: 60,
          ),
          PieChartSectionData(
            value: absent,
            title: 'Absent',
            color: Colors.red,
            radius: 60,
          ),
          PieChartSectionData(
            value: onLeave,
            title: 'On Leave',
            color: Colors.orange,
            radius: 60,
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildDepartmentStatsTable() {
    final deptStats =
        _dashboardData['departmentStats'] as Map<String, dynamic>?;
    if (deptStats == null || deptStats.isEmpty) {
      return const Text('No department stats available.');
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowMinHeight: 32,
            dataRowMaxHeight: 40,
            columns: const [
              DataColumn(label: Text('Department')),
              DataColumn(label: Text('Total')),
            ],
            rows: deptStats.entries
                .map((e) => DataRow(cells: [
                      DataCell(Text(e.key)),
                      DataCell(Text(e.value['total'].toString())),
                    ]))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginatedQuickActions(BuildContext context) {
    final actions = [
      {
        'icon': Icons.payments,
        'title': 'Payroll',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const PayrollManagementScreen()))
      },
      {
        'icon': Icons.people,
        'title': 'Employee Management',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const EmployeeManagementScreen()))
      },
      {
        'icon': Icons.beach_access,
        'title': 'Leave',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const LeaveManagementScreen()))
      },
      {
        'icon': Icons.notifications,
        'title': 'Notifications',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const NotificationAlertScreen()))
      },
      {
        'icon': Icons.settings,
        'title': 'Settings',
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()))
      },
      {
        'icon': Icons.access_time,
        'title': 'Attendance',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AttendanceManagementScreen()))
      },
      {
        'icon': Icons.free_breakfast,
        'title': 'Break Management',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const BreakManagementScreen()))
      },
      {
        'icon': Icons.help_outline,
        'title': 'Help',
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const HelpSupportScreen()))
      },
    ];

    const itemsPerPage = 4;
    final totalPages = (actions.length / itemsPerPage).ceil();
    final PageController _pageController = PageController();
    int _currentPage = 0;

    List<Widget> buildPageActions(int page) {
      final startIndex = page * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage).clamp(0, actions.length);
      return actions.sublist(startIndex, endIndex).map((action) {
        return _buildActionCard(
          context,
          icon: action['icon'] as IconData,
          title: action['title'] as String,
          onTap: action['onTap'] as VoidCallback,
        );
      }).toList();
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            SizedBox(
              height: 360, // Increased for better layout
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalPages,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, page) {
                  final pageActions = buildPageActions(page);
                  // Ensure we always have 4 items (fill with empty containers if needed)
                  while (pageActions.length < 4) {
                    pageActions.add(Container());
                  }
                  return Column(
                    children: [
                      Row(
                        children: pageActions
                            .sublist(0, 2)
                            .map((card) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: AspectRatio(
                                      aspectRatio: 1.2,
                                      child: card,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: pageActions
                            .sublist(2, 4)
                            .map((card) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: AspectRatio(
                                      aspectRatio: 1.2,
                                      child: card,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalPages, (index) {
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentPage ? 12 : 8,
                    height: index == _currentPage ? 12 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentPage ? Colors.blue : Colors.grey,
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsSection(ThemeData theme) {
    if (_isLoading || _dashboardData['chartData'] == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('Chart data loading or unavailable...'),
        ),
      );
    }

    // Example: Display a simple text representation of chart data
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance Trend (Example)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Text(
                _dashboardData['chartData']['attendance']?.join(', ') ??
                    'No chart data',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayrollInsightsSection extends StatelessWidget {
  _PayrollInsightsSection({Key? key}) : super(key: key);

  // Mock payroll data
  final List<Map<String, dynamic>> payrollData = [
    {
      'employee': 'John Doe',
      'salary': 3500.0,
      'deductions': 500.0,
      'month': 'May'
    },
    {
      'employee': 'Jane Smith',
      'salary': 4000.0,
      'deductions': 600.0,
      'month': 'May'
    },
    {
      'employee': 'Bob Johnson',
      'salary': 3200.0,
      'deductions': 400.0,
      'month': 'May'
    },
    {
      'employee': 'John Doe',
      'salary': 3500.0,
      'deductions': 450.0,
      'month': 'Apr'
    },
    {
      'employee': 'Jane Smith',
      'salary': 4000.0,
      'deductions': 550.0,
      'month': 'Apr'
    },
    {
      'employee': 'Bob Johnson',
      'salary': 3200.0,
      'deductions': 350.0,
      'month': 'Apr'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Calculate summary stats
    const currentMonth = 'May';
    final currentMonthData =
        payrollData.where((e) => e['month'] == currentMonth).toList();
    final totalPayroll =
        currentMonthData.fold<double>(0, (sum, e) => sum + (e['salary'] ?? 0));
    final avgSalary = currentMonthData.isNotEmpty
        ? totalPayroll / currentMonthData.length
        : 0;
    final highest = currentMonthData.isNotEmpty
        ? currentMonthData.reduce((a, b) => a['salary'] > b['salary'] ? a : b)
        : null;
    final lowest = currentMonthData.isNotEmpty
        ? currentMonthData.reduce((a, b) => a['salary'] < b['salary'] ? a : b)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payroll Trend (Last 6 Months)',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: Text('Payroll Trend Chart coming soon!')),
        ),
        const SizedBox(height: 24),
        Text('Deduction Breakdown', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
              child: Text('Deduction Breakdown Chart coming soon!')),
        ),
        const SizedBox(height: 24),
        Text('Payroll Summary', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSummaryCard(
                  context,
                  'Total Payroll',
                  '₤${totalPayroll.toStringAsFixed(2)}',
                  Icons.payments,
                  Colors.blue),
              _buildSummaryCard(
                  context,
                  'Avg Salary',
                  '₤${avgSalary.toStringAsFixed(2)}',
                  Icons.bar_chart,
                  Colors.green),
              _buildSummaryCard(
                  context,
                  'Highest',
                  highest != null
                      ? '${highest['employee']}\n₤${highest['salary'].toStringAsFixed(2)}'
                      : '-',
                  Icons.trending_up,
                  Colors.orange),
              _buildSummaryCard(
                  context,
                  'Lowest',
                  lowest != null
                      ? '${lowest['employee']}\n₤${lowest['salary'].toStringAsFixed(2)}'
                      : '-',
                  Icons.trending_down,
                  Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
