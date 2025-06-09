import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedRange = 'Last 7 days';
  final List<String> ranges = ['Last 7 days', 'Last 30 days', 'Custom'];

  // Mock data sets
  final List<String> days7 = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<double> workHours7 = [8, 7.5, 9, 8, 6, 0, 0];
  final Map<String, int> attendance7 = {'Present': 5, 'Absent': 1, 'Leave': 1};
  final int longestStreak7 = 5;
  final String mostProductiveDay7 = 'Wed';
  final String avgCheckIn7 = '09:05 AM';

  final List<String> days30 = [
    'W1',
    'W2',
    'W3',
    'W4',
    'W5',
    'W6',
    'W7',
    'W8',
    'W9',
    'W10',
    'W11',
    'W12',
    'W13',
    'W14',
    'W15',
    'W16',
    'W17',
    'W18',
    'W19',
    'W20',
    'W21',
    'W22',
    'W23',
    'W24',
    'W25',
    'W26',
    'W27',
    'W28',
    'W29',
    'W30'
  ];
  final List<double> workHours30 = [
    8,
    7,
    8,
    8,
    7,
    0,
    0,
    8,
    8,
    9,
    8,
    7,
    8,
    8,
    8,
    7,
    8,
    8,
    7,
    8,
    8,
    8,
    7,
    8,
    8,
    7,
    8,
    8,
    7,
    8
  ];
  final Map<String, int> attendance30 = {
    'Present': 22,
    'Absent': 4,
    'Leave': 4
  };
  final int longestStreak30 = 10;
  final String mostProductiveDay30 = 'W10';
  final String avgCheckIn30 = '08:55 AM';

  // For custom, just show a placeholder
  bool get isCustom => selectedRange == 'Custom';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Select data based on filter
    final List<String> days = selectedRange == 'Last 30 days' ? days30 : days7;
    final List<double> workHours =
        selectedRange == 'Last 30 days' ? workHours30 : workHours7;
    final Map<String, int> attendance =
        selectedRange == 'Last 30 days' ? attendance30 : attendance7;
    final int longestStreak =
        selectedRange == 'Last 30 days' ? longestStreak30 : longestStreak7;
    final String mostProductiveDay = selectedRange == 'Last 30 days'
        ? mostProductiveDay30
        : mostProductiveDay7;
    final String avgCheckIn =
        selectedRange == 'Last 30 days' ? avgCheckIn30 : avgCheckIn7;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Insights'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range Filter
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
                      if (val != null) {
                        setState(() {
                          selectedRange = val;
                          // TODO: Filter data based on selectedRange
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stat Cards
              if (!isCustom)
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
                      _buildStatCard(theme, 'Most Productive',
                          mostProductiveDay, Icons.trending_up, Colors.green),
                      const SizedBox(width: 12),
                      _buildStatCard(theme, 'Avg. Check-in', avgCheckIn,
                          Icons.access_time, Colors.amber),
                    ],
                  ),
                ),
              if (isCustom)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text('Custom date range picker coming soon!',
                        style: theme.textTheme.titleMedium),
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
                        'Work Hours Trend (${selectedRange == 'Last 30 days' ? 'Last 30 Days' : 'Last 7 Days'})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!isCustom)
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
                                              padding: const EdgeInsets.only(
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
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: (days.length - 1).toDouble(),
                              minY: 0,
                              maxY: 10,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    workHours.length,
                                    (i) => FlSpot(i.toDouble(), workHours[i]),
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
                      if (isCustom)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(
                            child: Text('Custom chart coming soon!',
                                style: theme.textTheme.bodyMedium),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Attendance Breakdown Pie Chart
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
                        'Attendance Breakdown (${selectedRange == 'Last 30 days' ? 'Last 30 Days' : 'Last 7 Days'})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!isCustom)
                        SizedBox(
                          height: 140,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: attendance['Present']!.toDouble(),
                                  color: Colors.green,
                                  title: 'Present',
                                  radius: 50,
                                  titleStyle: theme.textTheme.bodySmall
                                      ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                ),
                                PieChartSectionData(
                                  value: attendance['Absent']!.toDouble(),
                                  color: Colors.red,
                                  title: 'Absent',
                                  radius: 50,
                                  titleStyle: theme.textTheme.bodySmall
                                      ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                ),
                                PieChartSectionData(
                                  value: attendance['Leave']!.toDouble(),
                                  color: Colors.amber,
                                  title: 'Leave',
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
                      if (isCustom)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(
                            child: Text('Custom pie chart coming soon!',
                                style: theme.textTheme.bodyMedium),
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
                      const SizedBox(height: 16), // Extra padding below legend
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Placeholder for more charts
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
