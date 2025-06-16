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
import '../../widgets/admin_side_navigation.dart';

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

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String userName = authProvider.user?['name'] as String? ?? 'Admin';

      // Fetch total users (employees) count
      int totalEmployees = 0;
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/users'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${authProvider.token}',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['users'] is List) {
            totalEmployees = (data['users'] as List).length;
          }
        } else {
          print('Warning: Could not fetch total employees. Status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching total employees: $e. Using default 0.');
        // Potentially set a specific error message for this part
      }

      // TODO: Fetch actual data for these from dedicated API endpoints when available
      int presentToday = 0; // Placeholder - API needed
      int onLeave = 0; // Placeholder - API needed
      int pendingRequests = 0; // Placeholder - API needed

      _dashboardData = {
        'welcomeMessage': 'Welcome, $userName!',
        'overviewText': 'Here\'s an overview of your admin dashboard.',
        'quickStats': {
          'totalEmployees': totalEmployees,
          'presentToday': presentToday, // TODO: Replace with real data
          'onLeave': onLeave, // TODO: Replace with real data
          'pendingRequests': pendingRequests, // TODO: Replace with real data
        },
        // TODO: Fetch actual recent activities from an API endpoint (e.g., /api/admin/recent-activity)
        'recentActivities': [
          // Example structure, will be replaced by API data
          // {'id': '1', 'description': 'New leave request from Jane Doe.', 'timestamp': '2024-07-21T09:15:00Z'},
        ],
        // TODO: Fetch actual chart data from an API endpoint (e.g., /api/admin/dashboard-charts)
        'chartData': {
          'attendance': [], // Example: [70.0, 85.0, 90.0, 75.0, 95.0, 88.0, 92.0]
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
    print('ADMIN DASHBOARD: Building AdminDashboardScreen');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red))),
            ] else ...[
              Text(
                _dashboardData['welcomeMessage'] ?? 'Welcome, Admin!',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _dashboardData['overviewText'] ?? 'Here\'s an overview of your admin dashboard.',
                style: theme.textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Quick Actions & Shortcuts',
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
                      'Quick Actions',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildActionCard(
                          context,
                          icon: Icons.payments,
                          title: 'Payroll',
                          onTap: () {
                            print('ADMIN DASHBOARD: Navigating to PayrollManagementScreen');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PayrollManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.people,
                          title: 'Employee Management',
                          onTap: () {
                            print('ADMIN DASHBOARD: Navigating to EmployeeManagementScreen');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const EmployeeManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.beach_access,
                          title: 'Leave',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LeaveManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.notifications,
                          title: 'Notifications',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationAlertScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.settings,
                          title: 'Settings',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.help_outline,
                          title: 'Help',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpSupportScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Recent Activity',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    // TODO: Implement _buildRecentActivitySection with real data
                    // For now, showing a placeholder if no activities are fetched
                    _dashboardData['recentActivities'] != null && (_dashboardData['recentActivities'] as List).isNotEmpty
                        ? _buildRecentActivitySection(theme)
                        : const Text('No recent activities to display. (TODO: Connect to API)'),

                  ],
                ),
              ),
            ),
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
                    _dashboardData['chartData'] != null && (_dashboardData['chartData']['attendance'] as List).isNotEmpty
                        ? _buildChartsSection(theme)
                        : const Text('Chart data not available. (TODO: Connect to API)'),

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
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(title, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurface),
      title: Text(
        title,
        style: TextStyle(color: colorScheme.onSurface),
      ),
      onTap: onTap,
      selectedTileColor: colorScheme.primary.withOpacity(0.1),
    );
  }

  Widget _buildRecentActivitySection(ThemeData theme) {
    if (_isLoading || _dashboardData['recentActivities'] == null || (_dashboardData['recentActivities'] as List).isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('No recent activity or loading...'),
        ),
      );
    }

    List<dynamic> activities = _dashboardData['recentActivities'];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(activity['description'] ?? 'N/A'),
          subtitle: Text(activity['timestamp'] != null ? 'At: ${activity['timestamp']}' : 'No timestamp'),
        );
      },
    );
  }

  Widget _buildChartsSection(ThemeData theme) {
    // Placeholder for charts. In a real app, you'd use a charting library like fl_chart.
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
              child: Text(_dashboardData['chartData']['attendance']?.join(', ') ?? 'No chart data'),
            ),
          ),
        ],
      ),
    );
  }
}

// Keep _buildActionCard as it is, or refactor if needed for dynamic data
Widget _buildActionCard(BuildContext context, {
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
  );
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
