import 'dart:convert';
import 'package:sns_rooster/utils/logger.dart';
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
import '../../widgets/notification_bell.dart';
import '../../providers/notification_provider.dart';
import '../../services/employee_service.dart';
import '../../providers/payroll_analytics_provider.dart';
import '../../providers/payroll_cycle_settings_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          NotificationBell(iconColor: colorScheme.onPrimary),
        ],
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
                          const Text('No upcoming events.'),
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
                          const Text('No recent activities.'),
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
                            value: _dashboardData['quickStats']
                                    ['totalEmployees']
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
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: EmployeeService(
                              Provider.of<AuthProvider>(context, listen: false))
                          .getEmployees(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text(
                                  'Failed to load employees: \\${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                              child: Text('No employees found.'));
                        }
                        final employees = snapshot.data!;
                        return SizedBox(
                          height: 200,
                          child: ListView.separated(
                            itemCount: employees.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final emp = employees[i];
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(
                                  ((emp['firstName'] ?? '') +
                                              ' ' +
                                              (emp['lastName'] ?? ''))
                                          .trim()
                                          .isEmpty
                                      ? 'No Name'
                                      : ((emp['firstName'] ?? '') +
                                              ' ' +
                                              (emp['lastName'] ?? ''))
                                          .trim(),
                                ),
                                subtitle:
                                    Text(emp['department'] ?? 'No Department'),
                                trailing: Text(
                                    emp['isActive'] == true
                                        ? 'Active'
                                        : 'Inactive',
                                    style: TextStyle(
                                        color: emp['isActive'] == true
                                            ? Colors.green
                                            : Colors.red)),
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
            const SizedBox(height: 24),
            Text(
              'Payroll Insights',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // --- Payroll Insights Section ---
            const _PayrollInsightsSection(),
            const SizedBox(height: 24),
            // Placeholder sections removed (Help & Support, Security & Compliance, Integration)
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
    final theme = Theme.of(context);
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
              Icon(icon, size: 32, color: theme.colorScheme.onPrimary),
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
                      DataCell(Text(e.value.toString())),
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
    final PageController pageController = PageController();
    int currentPage = 0;

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
                controller: pageController,
                itemCount: totalPages,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
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
                    pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    setState(() {
                      currentPage = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == currentPage ? 12 : 8,
                    height: index == currentPage ? 12 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == currentPage ? Colors.blue : Colors.grey,
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
                              if (idx < 0 || idx >= trend.length)
                                return const SizedBox.shrink();
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
                  DateFormat('d MMM').format(nextPayDate!),
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
