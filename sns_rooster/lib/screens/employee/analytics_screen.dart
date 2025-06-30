import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart'; // Import provider
import '../../providers/analytics_provider.dart'; // Import AnalyticsProvider
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart'; // Import AppDrawer
import '../../widgets/admin_side_navigation.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedRange = 'Last 7 days';
  final List<String> ranges = ['Last 7 days', 'Last 30 days', 'Custom'];

  bool get isCustom => selectedRange == 'Custom';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnalyticsProvider>(context, listen: false)
          .fetchAnalyticsData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.user?['role'] == 'admin';
    if (isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics & Reports')),
        body: const Center(child: Text('Access denied')),
        drawer: const AdminSideNavigation(currentRoute: '/analytics'),
      );
    }
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu), // Hamburger icon
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: const AppDrawer(),
      body: Consumer<AnalyticsProvider>(
        builder: (context, analyticsProvider, child) {
          if (analyticsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (analyticsProvider.error != null) {
            return Center(
              child: Text('Error: ${analyticsProvider.error}'),
            );
          } else if (analyticsProvider.attendanceData.isEmpty ||
              analyticsProvider.workHoursData.isEmpty) {
            return const Center(
              child: Text('No analytics data available.'),
            );
          } else {
            final Map<String, int> attendance =
                analyticsProvider.attendanceData;
            final List<double> workHours = analyticsProvider.workHoursData;
            final List<String> days = [
              'Day 1',
              'Day 2',
              'Day 3',
              'Day 4',
              'Day 5',
              'Day 6',
              'Day 7'
            ];

            final int totalPresent = attendance['Present'] ?? 0;
            final int totalAbsent = attendance['Absent'] ?? 0;
            final int totalLeave = attendance['Leave'] ?? 0;
            final int totalWorkDays = totalPresent + totalAbsent + totalLeave;

            final int longestStreak = totalPresent;
            const String mostProductiveDay = 'N/A';
            const String avgCheckIn = 'N/A';

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Work Analytics',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        DropdownButton<String>(
                          value: selectedRange,
                          items: ranges
                              .map((r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedRange = val!;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatCard(
                              theme,
                              'Longest Streak',
                              '$longestStreak days',
                              Icons.emoji_events,
                              Colors.blue),
                          const SizedBox(width: 12),
                          _buildStatCard(
                              theme,
                              'Most Productive',
                              mostProductiveDay,
                              Icons.trending_up,
                              Colors.green),
                          const SizedBox(width: 12),
                          _buildStatCard(theme, 'Avg. Check-in', avgCheckIn,
                              Icons.access_time, Colors.amber),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Work Hours Trend (Last 7 Days)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  gridData: const FlGridData(
                                      show: true, drawVerticalLine: false),
                                  titlesData: FlTitlesData(
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(
                                          showTitles: true, reservedSize: 32),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          return idx >= 0 && idx < days.length
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8.0),
                                                  child: Text(days[idx],
                                                      style: theme
                                                          .textTheme.bodySmall),
                                                )
                                              : const SizedBox.shrink();
                                        },
                                        interval: 1,
                                      ),
                                    ),
                                    rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  minX: 0,
                                  maxX: (workHours.length - 1).toDouble(),
                                  minY: 0,
                                  maxY: 10,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: List.generate(
                                        workHours.length,
                                        (i) =>
                                            FlSpot(i.toDouble(), workHours[i]),
                                      ),
                                      isCurved: true,
                                      color: theme.colorScheme.primary,
                                      barWidth: 4,
                                      dotData: const FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.15),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance Breakdown',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 140,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value:
                                          attendance['Present']?.toDouble() ??
                                              0,
                                      color: Colors.green,
                                      title:
                                          '${(attendance['Present'] ?? 0)} Present',
                                      radius: 50,
                                      titleStyle: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                    ),
                                    PieChartSectionData(
                                      value:
                                          attendance['Absent']?.toDouble() ?? 0,
                                      color: Colors.red,
                                      title:
                                          '${(attendance['Absent'] ?? 0)} Absent',
                                      radius: 50,
                                      titleStyle: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                    ),
                                    PieChartSectionData(
                                      value:
                                          attendance['Leave']?.toDouble() ?? 0,
                                      color: Colors.amber,
                                      title:
                                          '${(attendance['Leave'] ?? 0)} Leave',
                                      radius: 50,
                                      titleStyle: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLegendDot(Colors.green),
                                const SizedBox(width: 4),
                                const Text('Present'),
                                const SizedBox(width: 16),
                                _buildLegendDot(Colors.red),
                                const SizedBox(width: 4),
                                const Text('Absent'),
                                const SizedBox(width: 16),
                                _buildLegendDot(Colors.amber),
                                const SizedBox(width: 4),
                                const Text('Leave'),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 60,
                      child: Center(
                        child: Text(
                          'More charts and insights coming soon!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStatCard(
      ThemeData theme, String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              radius: 22,
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}
