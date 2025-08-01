import 'dart:convert';
import 'package:sns_rooster/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import 'package:sns_rooster/providers/feature_provider.dart';
import 'package:sns_rooster/config/api_config.dart';
import 'package:sns_rooster/screens/admin/employee_management_screen.dart';
import 'package:sns_rooster/screens/admin/payroll_management_screen.dart';
import 'package:sns_rooster/screens/admin/leave_management_screen.dart';
import 'package:sns_rooster/screens/admin/notification_alert_screen.dart';
import 'package:sns_rooster/screens/admin/settings_screen.dart';
import 'package:sns_rooster/screens/admin/help_support_screen.dart';
import 'package:sns_rooster/screens/admin/attendance_management_screen.dart';
import 'package:sns_rooster/screens/admin/break_management_screen.dart';
import 'package:sns_rooster/screens/admin/event_management_screen.dart';
import 'package:sns_rooster/widgets/admin_side_navigation.dart';
import '../../services/employee_service.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/notification_bell.dart';
import '../../providers/notification_provider.dart';
import '../../providers/payroll_analytics_provider.dart';
import '../../providers/payroll_cycle_settings_provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:sns_rooster/services/secure_storage_service.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
      // Load features for the dashboard
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.featureProvider != null) {
        Logger.info('Dashboard: Loading features on init');
        authProvider.featureProvider!.loadFeatures().then((_) {
          Logger.info('Dashboard: Features loaded successfully');
        }).catchError((e) {
          Logger.error('Dashboard: Failed to load features: $e');
        });
      } else {
        Logger.warning('Dashboard: FeatureProvider is null during init');
      }
    });
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

      // Also force refresh features to ensure UI is up to date
      if (authProvider.featureProvider != null) {
        Logger.info(
            'Dashboard: Force refreshing features on dependency change');
        authProvider.featureProvider!.forceRefreshFeatures().then((_) {
          Logger.info('Dashboard: Features force refreshed successfully');
        }).catchError((e) {
          Logger.error('Dashboard: Failed to force refresh features: $e');
        });
      }
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

      // Fetch main dashboard data
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/analytics/admin/overview'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _dashboardData = data;
      } else {
        throw Exception('Failed to load dashboard analytics');
      }

      // Fetch upcoming events
      final eventsResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/events/upcoming?limit=5'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (eventsResponse.statusCode == 200) {
        final eventsData = jsonDecode(eventsResponse.body);
        _dashboardData['upcomingEvents'] = eventsData['events'] ?? [];
      }

      // Fetch recent activities
      final activitiesResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/events/activities?limit=10'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (activitiesResponse.statusCode == 200) {
        final activitiesData = jsonDecode(activitiesResponse.body);
        _dashboardData['recentActivities'] = activitiesData['activities'] ?? [];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      log('Error fetching dashboard data: $e');
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

    // Ensure features are loaded when dashboard is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authProvider.featureProvider != null) {
        final featureProvider = authProvider.featureProvider!;

        if (!featureProvider.isSubscriptionPlanLoaded) {
          if (!featureProvider.isLoading) {
            featureProvider.forceRefreshFeatures();
          }
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          // Feature refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.featureProvider != null) {
                try {
                  await authProvider.featureProvider!.forceRefreshFeatures();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Features refreshed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to refresh features: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feature provider not available'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            tooltip: 'Refresh Features',
          ),
          // Debug: Clear company ID button (only in debug mode)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () async {
                try {
                  await SecureStorageService.clearCompanyId();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Company ID cleared. Please logout and login again.'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to clear company ID: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              tooltip: 'Clear Company ID (Debug)',
            ),
          NotificationBell(iconColor: colorScheme.onPrimary),
        ],
      ),
      drawer: const AdminSideNavigation(currentRoute: '/admin_dashboard'),
      body: Consumer<FeatureProvider>(
        builder: (context, featureProvider, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 1200) {
                // Desktop: Centered, constrained width
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: _buildMainContent(
                        theme, colorScheme, userName, now, featureProvider),
                  ),
                );
              } else {
                // Mobile/tablet: Full width
                return _buildMainContent(
                    theme, colorScheme, userName, now, featureProvider);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, ColorScheme colorScheme,
      String userName, DateTime now, FeatureProvider featureProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading) ...[
            const Center(child: CircularProgressIndicator()),
          ] else if (_errorMessage != null) ...[
            Center(
                child: Text('Error: $_errorMessage',
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
                      color: colorScheme.onSurface.withValues(alpha: 0.7)),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  // Only show chart if real data is available
                  if (_dashboardData['chartData'] != null &&
                      (_dashboardData['chartData']['attendance'] as List)
                          .isNotEmpty)
                    _buildChartsSection(theme),
                  const SizedBox(height: 24),
                  Text(
                    'Live Metrics',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  // Only show metrics if real data is available
                  if (_dashboardData['quickStats'] != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          context,
                          icon: Icons.people,
                          label: 'Employees',
                          value: _dashboardData['quickStats']['totalEmployees']
                              .toString(),
                        ),
                        _buildSummaryItem(
                          context,
                          icon: Icons.payments,
                          label: 'Payslips',
                          value: (_dashboardData['payslipCount'] ?? '-')
                              .toString(),
                        ),
                        _buildSummaryItem(
                          context,
                          icon: Icons.notifications,
                          label: 'Notifications',
                          value: (_dashboardData['notificationCount'] ?? '-')
                              .toString(),
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
          _buildAlertsSection(context),
          const SizedBox(height: 24),
          Text(
            'Employee Management',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future:
                        EmployeeService(ApiService(baseUrl: ApiConfig.baseUrl))
                            .getEmployees(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                            child: Text(
                                'Failed to load employees: \\${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No employees found.'));
                      }
                      final employees = snapshot.data!;
                      return SizedBox(
                        height: 200,
                        child: ListView.separated(
                          itemCount: employees.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final emp = employees[i];
                            return ListTile(
                              leading: emp['role'] == 'admin'
                                  ? const Icon(Icons.admin_panel_settings,
                                      color: Colors.purple)
                                  : const Icon(Icons.person),
                              title: Text(
                                  '${emp['firstName'] ?? ''} ${emp['lastName'] ?? ''}'
                                          .trim()
                                          .isEmpty
                                      ? 'Unknown'
                                      : '${emp['firstName'] ?? ''} ${emp['lastName'] ?? ''}'
                                          .trim()),
                              subtitle: Text(emp['email'] ?? 'No email'),
                            );
                          },
                        ),
                      );
                    },
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
          // Only show Payroll Insights if the feature is enabled
          if (featureProvider.hasPayroll) ...[
            const SizedBox(height: 24),
            Text(
              'Payroll Insights',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // --- Payroll Insights Section ---
            const _PayrollInsightsSection(),
          ],
          const SizedBox(height: 24),
          // Placeholder sections removed (Help & Support, Security & Compliance, Integration)
        ],
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
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.withValues(alpha: 0.7), Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: Colors.white),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12,
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

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(10), // Reduced from 16
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.7), color],
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
                Icon(icon, color: theme.colorScheme.onPrimary, size: 24),
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
        'value': _dashboardData['quickStats']?['totalEmployees']?.toString() ??
            _dashboardData['totalEmployees']?.toString() ??
            '0',
        'icon': Icons.people,
        'color': Theme.of(context).colorScheme.primary,
        'onTap': () => _showEmployeeListModal('All'), // Make clickable
      },
      {
        'title': 'Present',
        'value': _dashboardData['quickStats']?['presentToday']?.toString() ??
            _dashboardData['present']?.toString() ??
            '0',
        'icon': Icons.check_circle,
        'color': Colors.green,
        'onTap': () => _showEmployeeListModal('Present'),
      },
      {
        'title': 'On Leave',
        'value': _dashboardData['quickStats']?['onLeave']?.toString() ??
            _dashboardData['onLeave']?.toString() ??
            '0',
        'icon': Icons.event_busy,
        'color': Theme.of(context).colorScheme.secondary,
        'onTap': () => _showEmployeeListModal('On Leave'),
      },
      {
        'title': 'Absent',
        'value': _dashboardData['quickStats']?['absentToday']?.toString() ??
            _dashboardData['absent']?.toString() ??
            '0',
        'icon': Icons.cancel,
        'color': Colors.red,
        'onTap': () => _showEmployeeListModal('Absent'),
      },
      {
        'title': 'Pending',
        'value': _dashboardData['quickStats']?['pending']?.toString() ??
            _dashboardData['pending']?.toString() ??
            _dashboardData['quickStats']?['pendingRequests']?.toString() ??
            '0',
        'icon': Icons.pending_actions,
        'color': Colors.orange,
        'onTap': () => _showEmployeeListModal('Pending'),
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
          child: stats[i]['onTap'] != null
              ? GestureDetector(
                  onTap: stats[i]['onTap'] as void Function(),
                  child: _buildStatCard(
                    context,
                    stats[i]['title'] as String,
                    stats[i]['value'] as String,
                    stats[i]['icon'] as IconData,
                    stats[i]['color'] as Color,
                  ),
                )
              : _buildStatCard(
                  context,
                  stats[i]['title'] as String,
                  stats[i]['value'] as String,
                  stats[i]['icon'] as IconData,
                  stats[i]['color'] as Color,
                ),
        ),
      ),
    );
  }

  void _showEmployeeListModal(String status) async {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchEmployeesByStatus(status),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            } else if (snapshot.hasError) {
              return AlertDialog(content: Text('Error: \\${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const AlertDialog(content: Text('No employees found.'));
            }
            final employees = snapshot.data!;
            final employeesList =
                employees.where((e) => e['role'] == 'employee').toList();
            final adminsList =
                employees.where((e) => e['role'] == 'admin').toList();
            final totalCount = employeesList.length + adminsList.length;

            return _EmployeeModalContent(
              employeesList: employeesList,
              adminsList: adminsList,
              totalCount: totalCount,
            );
          },
        );
      },
    );
  }

  String _statusToParam(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return 'present';
      case 'absent':
        return 'absent';
      case 'on leave':
        return 'onleave';
      case 'pending':
        return 'pending';
      default:
        return status.toLowerCase();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchEmployeesByStatus(
      String status) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (status == 'All') {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/analytics/admin/active-users'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['users'] != null && data['users'] is List) {
            return List<Map<String, dynamic>>.from(data['users']);
          }
        }
        return [];
      }
      final statusParam = _statusToParam(status);
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/attendance/today-list?status=$statusParam'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['employees'] != null && data['employees'] is List) {
          return List<Map<String, dynamic>>.from(data['employees']);
        }
      } else {
        log('Failed to fetch employees by status: \\${response.body}');
      }
    } catch (e) {
      log('Error fetching employees by status: $e');
    }
    return [];
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
            color: Colors.green,
            title: 'Present',
            radius: 60,
          ),
          PieChartSectionData(
            value: absent,
            color: Colors.red,
            title: 'Absent',
            radius: 60,
          ),
          PieChartSectionData(
            value: onLeave,
            color: Colors.orange,
            title: 'On Leave',
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
    final columns = ['Department', 'Present', 'Absent', 'On Leave'];
    final rows = deptStats.entries.map((entry) {
      final dept = entry.key;
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        return DataRow(cells: [
          DataCell(Text(dept)),
          DataCell(Text(value['present']?.toString() ?? '0')),
          DataCell(Text(value['absent']?.toString() ?? '0')),
          DataCell(Text(value['onLeave']?.toString() ?? '0')),
        ]);
      } else if (value is int) {
        // If value is just an int, treat as present count
        return DataRow(cells: [
          DataCell(Text(dept)),
          DataCell(Text(value.toString())),
          const DataCell(Text('0')),
          const DataCell(Text('0')),
        ]);
      } else {
        // Unknown type, show zeros
        return DataRow(cells: [
          DataCell(Text(dept)),
          const DataCell(Text('0')),
          const DataCell(Text('0')),
          const DataCell(Text('0')),
        ]);
      }
    }).toList();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
            rows: rows,
          ),
        ),
      ),
    );
  }

  // Restore the original _buildPaginatedQuickActions function to show action cards
  Widget _buildPaginatedQuickActions(BuildContext context) {
    final actions = [
      {
        'icon': Icons.settings,
        'title': 'Settings',
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SettingsScreen())),
      },
      {
        'icon': Icons.access_time,
        'title': 'Attendance',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AttendanceManagementScreen())),
      },
      {
        'icon': Icons.free_breakfast,
        'title': 'Break Management',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const BreakManagementScreen())),
      },
      {
        'icon': Icons.people,
        'title': 'Employee Management',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const EmployeeManagementScreen())),
      },
      {
        'icon': Icons.beach_access,
        'title': 'Leave',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const LeaveManagementScreen())),
      },
      {
        'icon': Icons.payments,
        'title': 'Payroll',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const PayrollManagementScreen())),
      },
      {
        'icon': Icons.notifications,
        'title': 'Notifications',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const NotificationAlertScreen())),
      },
      {
        'icon': Icons.help_outline,
        'title': 'Help',
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const HelpSupportScreen())),
      },
      {
        'icon': Icons.event,
        'title': 'Create Event',
        'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const EventManagementScreen())),
      },
    ];

    // Responsive layout based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    int itemsPerPage;
    if (screenWidth > 1200) {
      itemsPerPage = 6;
    } else if (screenWidth > 800) {
      itemsPerPage = 4;
    } else if (screenWidth > 600) {
      itemsPerPage = 3;
    } else {
      itemsPerPage = 2;
    }

    final totalPages = (actions.length / itemsPerPage).ceil();
    final PageController pageController = PageController();
    int currentPage = 0;

    List<Widget> buildPageActions(int page) {
      final startIndex = page * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage).clamp(0, actions.length);
      return actions.sublist(startIndex, endIndex).map((action) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _buildActionCard(
              context,
              icon: action['icon'] as IconData,
              title: action['title'] as String,
              onTap: (action['onTap'] as VoidCallback?) ?? () {},
            ),
          ),
        );
      }).toList();
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            SizedBox(
              height: 120,
              child: PageView.builder(
                controller: pageController,
                itemCount: totalPages,
                onPageChanged: (page) {
                  setState(() {
                    currentPage = page;
                  });
                },
                itemBuilder: (context, page) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: buildPageActions(page),
                    ),
                  );
                },
              ),
            ),
            if (totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (i) {
                  return GestureDetector(
                    onTap: () => pageController.animateToPage(i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == currentPage ? Colors.blue : Colors.grey,
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

  Widget _buildAlertsSection(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    // Filter notifications: show only alerts or broadcasts for admin
    final rawAlerts = notificationProvider.notifications;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?['_id'];
    final alerts = rawAlerts
        .where((n) {
          final isAlertType = n['type'] == 'alert' ||
              n['type'] == 'payroll'; // extend as needed
          final isForAdminRole = n['role'] == 'admin';
          final isBroadcast = n['role'] == 'all';
          final isForThisAdmin = n['user'] == userId;
          return isAlertType &&
              (isForAdminRole || isBroadcast || isForThisAdmin);
        })
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Alerts',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (alerts.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('No critical alerts.')),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: alerts.map((alert) {
                return ListTile(
                  leading: Icon(
                    alert['type'] == 'alert'
                        ? Icons.warning
                        : Icons.notifications,
                    color: alert['type'] == 'alert'
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(alert['title'] ?? 'Untitled Alert'),
                  subtitle: Text(alert['message'] ?? 'No description'),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationAlertScreen(),
                ),
              );
            },
            child: const Text('View All Alerts'),
          ),
        ),
      ],
    );
  }
}

class _EmployeeModalContent extends StatefulWidget {
  final List<Map<String, dynamic>> employeesList;
  final List<Map<String, dynamic>> adminsList;
  final int totalCount;

  const _EmployeeModalContent({
    required this.employeesList,
    required this.adminsList,
    required this.totalCount,
  });

  @override
  State<_EmployeeModalContent> createState() => _EmployeeModalContentState();
}

class _EmployeeModalContentState extends State<_EmployeeModalContent> {
  bool employeesExpanded = true;
  bool adminsExpanded = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('All (${widget.totalCount})',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 350,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.employeesList.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Employees: All (${widget.employeesList.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(employeesExpanded
                          ? Icons.expand_less
                          : Icons.expand_more),
                      onPressed: () => setState(
                          () => employeesExpanded = !employeesExpanded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                  ],
                ),
                if (employeesExpanded) ...[
                  const SizedBox(height: 8),
                  ...widget.employeesList.map((e) => Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(
                                '${e['firstName'] ?? ''} ${e['lastName'] ?? ''}'
                                        .trim()
                                        .isEmpty
                                    ? 'Unknown'
                                    : '${e['firstName'] ?? ''} ${e['lastName'] ?? ''}'
                                        .trim()),
                            subtitle: Text(e['email'] ?? 'No email'),
                          ),
                          const Divider(height: 1),
                        ],
                      )),
                ],
              ],
              if (widget.adminsList.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Admins: All (${widget.adminsList.length})',
                        style: const TextStyle(
                            color: Colors.purple, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(adminsExpanded
                          ? Icons.expand_less
                          : Icons.expand_more),
                      onPressed: () =>
                          setState(() => adminsExpanded = !adminsExpanded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                      color: Colors.purple,
                    ),
                  ],
                ),
                if (adminsExpanded) ...[
                  const SizedBox(height: 8),
                  ...widget.adminsList.map((a) => Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.admin_panel_settings,
                                color: Colors.purple),
                            title: Text(
                                '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'
                                        .trim()
                                        .isEmpty
                                    ? 'Unknown'
                                    : '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'
                                        .trim()),
                            subtitle: Text(a['email'] ?? 'No email'),
                          ),
                          const Divider(height: 1),
                        ],
                      )),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _PayrollInsightsSection extends StatefulWidget {
  const _PayrollInsightsSection({Key? key}) : super(key: key);

  @override
  State<_PayrollInsightsSection> createState() =>
      _PayrollInsightsSectionState();
}

class _PayrollInsightsSectionState extends State<_PayrollInsightsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<PayrollAnalyticsProvider>(context, listen: false);
      final cycleProv =
          Provider.of<PayrollCycleSettingsProvider>(context, listen: false);
      final freq = (cycleProv.settings?['frequency'] ?? 'Monthly')
          .toString()
          .toLowerCase();
      provider.fetchTrend(freq: freq);
      provider.fetchDeductionBreakdown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<PayrollAnalyticsProvider>(context);

    if (provider.isLoading && provider.trend.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Text('Error: ${provider.error}',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.error));
    }

    final trend = provider.trend;
    final breakdown = provider.deductionBreakdown;

    // Compute summary stats from trend (use latest month if available)
    double totalPayroll = 0;
    double latestGross = 0;
    double latestDeductions = 0;
    DateTime? nextPayDate;
    if (trend.isNotEmpty) {
      final latest = trend.last; // latest month
      totalPayroll = (latest['totalNet'] ?? 0).toDouble();
      latestGross = (latest['totalGross'] ?? 0).toDouble();
      latestDeductions = (latest['totalDeductions'] ?? 0).toDouble();
    }

    // Compute next pay date using payroll cycle settings
    final cycleProvider = Provider.of<PayrollCycleSettingsProvider>(context);
    final cycle = cycleProvider.settings;
    if (cycle != null) {
      final String freq = cycle['frequency'] ?? 'Monthly';
      if (freq == 'Monthly') {
        final int payDay = (cycle['payDay'] ?? 30) as int;
        DateTime now = DateTime.now();
        DateTime tentative = DateTime(now.year, now.month, payDay);
        if (now.isAfter(tentative)) {
          tentative = DateTime(now.year, now.month + 1, payDay);
        }
        final int offset = (cycle['payOffset'] ?? 0) as int;
        nextPayDate = tentative.add(Duration(days: offset));
      }
    }

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
          child: trend.isEmpty
              ? const Center(child: Text('No data'))
              : Builder(builder: (context) {
                  final maxY = trend
                      .map<double>((e) => (e['totalNet'] ?? 0).toDouble())
                      .fold<double>(0, (prev, v) => v > prev ? v : prev);
                  return BarChart(
                    BarChartData(
                      maxY: maxY * 1.2,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, _, rod, __) {
                            final month = trend[group.x.toInt()]['month'];
                            return BarTooltipItem(
                              '$month\n₹${rod.toY.toStringAsFixed(0)}',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= trend.length) {
                                return const SizedBox.shrink();
                              }
                              final mStr =
                                  (trend[idx]['month'] as String).substring(5);
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(mStr,
                                    style: const TextStyle(fontSize: 10)),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData:
                          FlGridData(show: true, horizontalInterval: maxY / 4),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        for (int i = 0; i < trend.length; i++)
                          BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                              toY: (trend[i]['totalNet'] ?? 0).toDouble(),
                              color: Theme.of(context).colorScheme.primary,
                              width: 18,
                              borderRadius: BorderRadius.circular(4),
                            )
                          ])
                      ],
                    ),
                  );
                }),
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
          child: breakdown.isEmpty
              ? const Center(child: Text('No breakdown data'))
              : PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: breakdown.entries.map((e) {
                      final idx = breakdown.keys.toList().indexOf(e.key);
                      final color =
                          Colors.primaries[idx % Colors.primaries.length];
                      final percent =
                          (e.value / breakdown.values.reduce((a, b) => a + b)) *
                              100;
                      return PieChartSectionData(
                        value: e.value,
                        title: '${percent.toStringAsFixed(0)}%',
                        color: color,
                        radius: 60,
                        titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        if (breakdown.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final entry in breakdown.entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.primaries[
                            breakdown.keys.toList().indexOf(entry.key) %
                                Colors.primaries.length],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('${entry.key}: ₹${entry.value.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
            ],
          ),
        const SizedBox(height: 24),
        Text('Payroll Summary', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildSummaryCard(
                context,
                'Latest Net Payroll',
                '₹${totalPayroll.toStringAsFixed(2)}',
                Icons.payments,
                Colors.blue),
            _buildSummaryCard(
                context,
                'Latest Gross Payroll',
                '₹${latestGross.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                Colors.green),
            _buildSummaryCard(
                context,
                'Latest Deductions',
                '₹${latestDeductions.toStringAsFixed(2)}',
                Icons.remove_circle,
                Colors.red),
            if (nextPayDate != null)
              _buildSummaryCard(
                  context,
                  'Next Pay Run',
                  DateFormat('d MMM').format(nextPayDate),
                  Icons.calendar_today,
                  Colors.purple),
          ],
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
