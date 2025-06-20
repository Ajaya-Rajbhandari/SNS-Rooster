import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:sns_rooster/config/api_config.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import '../../widgets/admin_side_navigation.dart'; // Added this import

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _stats = {
    'totalEmployees': 0,
    'presentToday': 0,
    'absentToday': 0,
    'onLeaveToday': 0,
    'pendingLeaveRequests': 0,
    'upcomingHolidays': 0,
    'departmentStats': {},
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      // Fetch all users for total count and department stats
      final usersResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      int totalEmployees = 0;
      Map<String, dynamic> departmentStats = {};

      if (usersResponse.statusCode == 200) {
        final usersData = jsonDecode(usersResponse.body);
        if (usersData['users'] is List) {
          final usersList = usersData['users'] as List;
          totalEmployees = usersList.length;
          // Calculate department stats (total per department)
          for (var user in usersList) {
            final department = user['department'] ?? 'Unknown';
            if (departmentStats.containsKey(department)) {
              departmentStats[department]['total'] =
                  (departmentStats[department]['total'] ?? 0) + 1;
              // TODO: Need attendance data to calculate 'present' per department
              departmentStats[department]['present'] =
                  departmentStats[department]['present'] ?? 0;
            } else {
              departmentStats[department] = {
                'total': 1,
                'present': 0
              }; // Present count needs real data
            }
          }
        }
      } else {
        print('Failed to load users: ${usersResponse.statusCode}');
        // Handle error or set default/error state for totalEmployees and departmentStats
      }

      // Fetch leave requests for pending count
      final leaveRequestsResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/leave-requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      int pendingLeaveRequests = 0;
      if (leaveRequestsResponse.statusCode == 200) {
        final leaveRequestsData = jsonDecode(leaveRequestsResponse.body);
        if (leaveRequestsData['leaveRequests'] is List) {
          pendingLeaveRequests = (leaveRequestsData['leaveRequests'] as List)
              .where((req) => req['status'] == 'pending')
              .length;
        }
      } else {
        print(
            'Failed to load leave requests: ${leaveRequestsResponse.statusCode}');
      }

      // TODO: Fetch actual data for these from dedicated API endpoints when available
      int presentToday =
          0; // Placeholder - API needed (e.g., from /api/attendance/today)
      int absentToday = 0; // Placeholder - API needed
      int onLeaveToday =
          0; // Placeholder - API needed (derive from approved leave requests for today)
      int upcomingHolidays =
          0; // Placeholder - API needed (e.g., from /api/holidays)

      if (!mounted) return;
      setState(() {
        _stats = {
          'totalEmployees': totalEmployees,
          'presentToday': presentToday, // TODO: Replace with real data
          'absentToday': absentToday, // TODO: Replace with real data
          'onLeaveToday': onLeaveToday, // TODO: Replace with real data
          'pendingLeaveRequests': pendingLeaveRequests,
          'upcomingHolidays': upcomingHolidays, // TODO: Replace with real data
          'departmentStats':
              departmentStats, // Partially real, 'present' count is placeholder
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load dashboard data';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Added Scaffold
      appBar: AppBar(
        // Added AppBar
        title: const Text('Overview'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      drawer: const AdminSideNavigation(
          currentRoute: '/admin_overview'), // Added Drawer
      body: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDashboardData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(context),
                  const SizedBox(height: 24),
                  _buildQuickStats(context),
                  const SizedBox(height: 24),
                  _buildAttendanceChart(context),
                  const SizedBox(height: 24),
                  _buildDepartmentStats(context),
                  const SizedBox(height: 24),
                  _buildUpcomingEvents(context),
                  const SizedBox(height: 24),
                  _buildRecentActivities(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, ${user?['name'] ?? 'Admin'}!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('EEEE, MMMM d, y').format(now),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildQuickStats(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2, // Adjusted for better fit
      children: [
        _buildStatCard(
          context,
          'Total Employees',
          _stats['totalEmployees'].toString(),
          Icons.people,
          theme.colorScheme.primary,
        ),
        _buildStatCard(
          context,
          'Present Today',
          _stats['presentToday'].toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'On Leave',
          _stats['onLeaveToday'].toString(),
          Icons.event_busy,
          theme.colorScheme.secondary,
        ),
        _buildStatCard(
          context,
          'Pending Requests',
          _stats['pendingLeaveRequests'].toString(),
          Icons.pending_actions,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith( // Changed from titleMedium to titleSmall
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis, // Added ellipsis for long text
                    maxLines: 2, // Allow up to 2 lines for the title
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceChart(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Attendance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: _stats['presentToday'].toDouble(),
                      title: 'Present',
                      color: Colors.green,
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: _stats['absentToday'].toDouble(),
                      title: 'Absent',
                      color: Colors.red,
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: _stats['onLeaveToday'].toDouble(),
                      title: 'On Leave',
                      color: Colors.orange,
                      radius: 80,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentStats(BuildContext context) {
    final deptStats = _stats['departmentStats'] as Map<String, dynamic>;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Department-wise Attendance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...deptStats.entries.map((dept) {
              final present = dept.value['present'] as int;
              final total = dept.value['total'] as int;
              final percentage = (present / total * 100).round();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dept.key,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            color: percentage >= 90
                                ? Colors.green
                                : percentage >= 70
                                    ? Colors.orange
                                    : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: present / total,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage >= 90
                            ? Colors.green
                            : percentage >= 70
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$present of $total present',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Events',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full calendar view
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                // TODO: Replace with actual event data
                final events = [
                  {
                    'title': 'Team Building Event',
                    'date': '2024-03-15',
                    'type': 'event',
                  },
                  {
                    'title': 'Public Holiday',
                    'date': '2024-03-20',
                    'type': 'holiday',
                  },
                  {
                    'title': 'Quarterly Review',
                    'date': '2024-03-25',
                    'type': 'meeting',
                  },
                ];

                final event = events[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: event['type'] == 'holiday'
                        ? Colors.red
                        : event['type'] == 'meeting'
                            ? Colors.blue
                            : Colors.green,
                    child: Icon(
                      event['type'] == 'holiday'
                          ? Icons.event
                          : event['type'] == 'meeting'
                              ? Icons.groups
                              : Icons.celebration,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(event['title']!),
                  subtitle: Text(
                    DateFormat('MMM d, y').format(
                      DateTime.parse(event['date']!),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to activity log
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                // TODO: Replace with actual activity data
                final activities = [
                  {
                    'icon': Icons.check_circle_outline,
                    'title': 'John Doe approved Jane Smith\'s leave request',
                    'time': '2 hours ago',
                    'color': Colors.green,
                  },
                  {
                    'icon': Icons.person_add_alt_1,
                    'title': 'New employee, Alice Johnson, added',
                    'time': 'Yesterday',
                    'color': Colors.blue,
                  },
                  {
                    'icon': Icons.warning_amber,
                    'title': 'System update scheduled for 2024-03-01',
                    'time': '3 days ago',
                    'color': Colors.orange,
                  },
                  {
                    'icon': Icons.event_busy,
                    'title': 'Public holiday declared for March 20',
                    'time': '4 days ago',
                    'color': Colors.red,
                  },
                  {
                    'icon': Icons.groups,
                    'title':
                        'Department meeting scheduled for Engineering team',
                    'time': '5 days ago',
                    'color': Colors.purple,
                  },
                ];

                final activity = activities[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: activity['color'] as Color,
                    child: Icon(
                      activity['icon'] as IconData,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(activity['title'] as String),
                  subtitle: Text(activity['time'] as String),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
