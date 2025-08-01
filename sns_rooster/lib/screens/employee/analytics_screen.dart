import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart'; // Import provider
import '../../providers/analytics_provider.dart' hide EmployeeAnalyticsService;
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart'; // Import AppDrawer
import '../../services/employee_analytics_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../admin/analytics_reports_screen.dart';
import 'package:sns_rooster/services/api_service.dart';
import 'package:sns_rooster/config/api_config.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedRange = 'Last 7 days';
  final List<String> ranges = ['Last 7 days', 'Last 30 days', 'Custom'];
  int _customRange = 7;

  bool get isCustom => selectedRange == 'Custom';

  Map<String, dynamic>? lateCheckins;
  Map<String, dynamic>? avgCheckout;
  List<dynamic>? recentActivity;
  bool loadingExtra = true;
  String? extraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<AnalyticsProvider>(context, listen: false)
          .fetchAnalyticsData(range: 7);
      // Fetch extra analytics
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.user?['_id'] ?? authProvider.user?['id'];
        final apiService = ApiService(baseUrl: ApiConfig.baseUrl);
        final analyticsService = EmployeeAnalyticsService(apiService);
        final late = await analyticsService.fetchLateCheckins(userId);
        final avg = await analyticsService.fetchAvgCheckout(userId);
        final recent = await analyticsService.fetchRecentActivity(userId);
        setState(() {
          lateCheckins = late;
          avgCheckout = avg;
          recentActivity = recent;
          loadingExtra = false;
        });
      } catch (e) {
        setState(() {
          extraError = e.toString();
          loadingExtra = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      // Not logged in, show fallback or redirect
      return const Scaffold(
        body: Center(child: Text('Not logged in. Please log in.')),
      );
    }
    final isAdmin = user['role'] == 'admin';
    if (isAdmin) {
      // Directly show admin analytics screen for admins
      return const AdminAnalyticsScreen();
    }
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
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

            final int longestStreak = analyticsProvider.longestStreak;
            final String mostProductiveDay =
                analyticsProvider.mostProductiveDay;
            final String avgCheckIn = analyticsProvider.avgCheckIn;

            // Filter out negative work hours (should not happen, but for safety)
            final List<double> filteredWorkHours =
                workHours.map((h) => h < 0 ? 0.0 : h).toList();

            final double present = attendance['Present']?.toDouble() ?? 0;
            final double absent = attendance['Absent']?.toDouble() ?? 0;
            final double leave = attendance['Leave']?.toDouble() ?? 0;
            final double total = present + absent + leave;
            String percent(double value) => total > 0
                ? '${((value / total) * 100).toStringAsFixed(0)}%'
                : '0%';

            // Dynamically generate X-axis labels
            List<String> xLabels;
            if (workHours.isEmpty) {
              xLabels = [];
            } else if (workHours.length <= 31) {
              xLabels = List.generate(workHours.length, (i) => 'Day ${i + 1}');
            } else {
              xLabels = List.generate(workHours.length, (i) => 'Day ${i + 1}');
            }
            // Try to use actual dates if available in attendance data
            // (Assumes attendance data is sorted oldest to newest)
            // If you want to use actual dates, you need to pass them from the provider/backend
            // For now, fallback to Day 1...Day N
            String chartTitle = selectedRange == 'Custom'
                ? 'Work Hours Trend (Last $_customRange Days)'
                : selectedRange == 'Last 7 days'
                    ? 'Work Hours Trend (Last 7 Days)'
                    : selectedRange == 'Last 30 days'
                        ? 'Work Hours Trend (Last 30 Days)'
                        : 'Work Hours Trend';

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
                          onChanged: (val) async {
                            if (val == 'Custom') {
                              final now = DateTime.now();
                              final int? picked = await showDialog<int>(
                                context: context,
                                builder: (context) {
                                  int tempRange = _customRange;
                                  DateTime endDate = now;
                                  DateTime startDate = now
                                      .subtract(Duration(days: tempRange - 1));
                                  String formatDate(DateTime d) {
                                    return '${d.day.toString().padLeft(2, '0')} ${_monthName(d.month)} ${d.year}';
                                  }

                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      endDate = now;
                                      startDate = now.subtract(
                                          Duration(days: tempRange - 1));
                                      return AlertDialog(
                                        title: const Text(
                                            'Select Custom Range (days)'),
                                        content: SizedBox(
                                          height: 150,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Slider(
                                                value: tempRange.toDouble(),
                                                min: 1,
                                                max: 90,
                                                divisions: 89,
                                                label: 'Days: $tempRange',
                                                onChanged: (v) {
                                                  setState(() {
                                                    tempRange = v.round();
                                                  });
                                                },
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text('Days: $tempRange',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.copyWith(
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Divider(
                                                  height: 1,
                                                  thickness: 1,
                                                  color: Colors.grey.shade200),
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text('From:',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall),
                                                      Text(
                                                          formatDate(startDate),
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .bodyLarge
                                                              ?.copyWith(
                                                                  color: Colors
                                                                      .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                    ],
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Text('To:',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall),
                                                      Text(formatDate(endDate),
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .bodyLarge
                                                              ?.copyWith(
                                                                  color: Colors
                                                                      .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, null),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                                context, tempRange),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedRange = 'Custom';
                                  _customRange = picked;
                                });
                                Provider.of<AnalyticsProvider>(context,
                                        listen: false)
                                    .fetchAnalyticsData(range: picked);
                              }
                            } else {
                              setState(() {
                                selectedRange = val!;
                              });
                              int range = 7;
                              if (val == 'Last 30 days') range = 30;
                              Provider.of<AnalyticsProvider>(context,
                                      listen: false)
                                  .fetchAnalyticsData(range: range);
                            }
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
                              chartTitle,
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
                                          return idx >= 0 &&
                                                  idx < xLabels.length
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8.0),
                                                  child: Text(xLabels[idx],
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
                                  maxX:
                                      (filteredWorkHours.length - 1).toDouble(),
                                  minY: 0,
                                  maxY: 10,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: List.generate(
                                        filteredWorkHours.length,
                                        (i) => FlSpot(
                                            i.toDouble(), filteredWorkHours[i]),
                                      ),
                                      isCurved: true,
                                      color: theme.colorScheme.primary,
                                      barWidth: 4,
                                      dotData: const FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.15),
                                      ),
                                      showingIndicators: List.generate(
                                          filteredWorkHours.length, (i) => i),
                                    ),
                                  ],
                                  lineTouchData: LineTouchData(
                                    enabled: true,
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipColor: (spots) =>
                                          Colors.black87,
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((spot) {
                                          final idx = spot.x.toInt();
                                          return LineTooltipItem(
                                            '${xLabels[idx]}\n',
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: '${spot.y}',
                                                style: const TextStyle(
                                                  color: Colors.amber,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
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
                                      value: present,
                                      color: Colors.green,
                                      title: percent(present),
                                      radius: 50,
                                      titleStyle: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold),
                                    ),
                                    PieChartSectionData(
                                      value: absent,
                                      color: Colors.red,
                                      title: percent(absent),
                                      radius: 50,
                                      titleStyle: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold),
                                    ),
                                    PieChartSectionData(
                                      value: leave,
                                      color: Colors.amber,
                                      title: percent(leave),
                                      radius: 50,
                                      titleStyle: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                              color: Colors.black,
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
                    const Divider(thickness: 1, height: 32),
                    Text(
                      'Attendance Insights',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedOpacity(
                      opacity: loadingExtra ? 0.5 : 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (loadingExtra)
                            Center(
                              child: SpinKitThreeBounce(
                                color: theme.colorScheme.primary,
                                size: 32.0,
                              ),
                            ),
                          if (extraError != null)
                            Center(child: Text('Error: ${extraError!}')),
                          if (!loadingExtra && extraError == null) ...[
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          Colors.red.withValues(alpha: 0.1),
                                      child: const Icon(Icons.access_time,
                                          color: Colors.red),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Late Check-ins (last 30 days)',
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                          Text(
                                              '${lateCheckins?['lateCount'] ?? 0} times',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color: Colors.grey[700])),
                                        ],
                                      ),
                                    ),
                                    lateCheckins?['lateDates'] != null &&
                                            (lateCheckins!['lateDates'] as List)
                                                .isNotEmpty
                                        ? IconButton(
                                            icon: Icon(Icons.info_outline,
                                                color: Colors.grey[600]),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text(
                                                      'Late Check-in Dates'),
                                                  content: Text((lateCheckins![
                                                          'lateDates'] as List)
                                                      .join('\n')),
                                                ),
                                              );
                                            },
                                          )
                                        : const SizedBox.shrink(),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          Colors.blue.withValues(alpha: 0.1),
                                      child: const Icon(Icons.logout,
                                          color: Colors.blue),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Average Check-out Time',
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                          Text(
                                              avgCheckout?['avgCheckOut'] ??
                                                  '--:--',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color: Colors.grey[700])),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Recent Attendance Activity',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    if (recentActivity == null ||
                                        recentActivity!.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12.0),
                                        child: Text('No recent activity found.',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(color: Colors.grey)),
                                      )
                                    else
                                      ...recentActivity!.map((rec) => ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(
                                                'Date: ${rec['date']?.substring(0, 10) ?? ''}',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w500)),
                                            subtitle: Text(
                                                'Check-in: ${_formatTime(rec['checkInTime'])} | Check-out: ${_formatTime(rec['checkOutTime'])}'),
                                          )),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(thickness: 1, height: 32),
                    SizedBox(
                      height: 60,
                      child: Center(
                        child: Text(
                          'More charts and insights will appear here.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
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

  String _formatTime(dynamic timeField) {
    if (timeField == null) return '--:--';

    // If it's already a formatted string (from backend), return as is
    if (timeField is String &&
        timeField.contains(':') &&
        !timeField.contains('T')) {
      return timeField;
    }

    // If it's a DateTime object or ISO string, parse and format
    try {
      final time = DateTime.parse(timeField.toString());
      // Convert to local time
      final localTime = time.toLocal();
      return DateFormat('HH:mm').format(localTime);
    } catch (e) {
      return '--:--';
    }
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
              backgroundColor: color.withValues(alpha: 0.15),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
