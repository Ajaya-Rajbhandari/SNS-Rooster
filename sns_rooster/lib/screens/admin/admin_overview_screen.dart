import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

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
      // TODO: Replace with actual API call
      // Simulated data for now
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      setState(() {
        _stats = {
          'totalEmployees': 150,
          'presentToday': 140,
          'absentToday': 7,
          'onLeaveToday': 3,
          'pendingLeaveRequests': 5,
          'upcomingHolidays': 2,
          'departmentStats': {
            'Engineering': {'total': 50, 'present': 48},
            'HR': {'total': 20, 'present': 19},
            'Sales': {'total': 30, 'present': 28},
            'Marketing': {'total': 25, 'present': 24},
            'Finance': {'total': 25, 'present': 23},
          },
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
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, ${user?['name'] ?? 'Admin'}!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('EEEE, MMMM d, y').format(now),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'Total Employees',
          _stats['totalEmployees'].toString(),
          Icons.people,
          Colors.blue,
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
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'Pending Requests',
          _stats['pendingLeaveRequests'].toString(),
          Icons.pending_actions,
          Colors.purple,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
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
