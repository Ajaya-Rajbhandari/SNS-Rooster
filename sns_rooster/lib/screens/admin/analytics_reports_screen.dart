import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/admin_side_navigation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_analytics_provider.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  void _loadData() {
    final provider = context.read<AdminAnalyticsProvider>();
    if (_selectedRange == null) {
      provider.fetchSummary();
      provider.fetchOverview();
      provider.fetchLeaveBreakdown();
      provider.fetchMonthlyHoursTrend();
    } else {
      final start = _fmt(_selectedRange!.start);
      final end = _fmt(_selectedRange!.end);
      provider.fetchSummary(start: start, end: end);
      provider.fetchOverview(start: start, end: end);
      provider.fetchLeaveBreakdown(start: start, end: end);
      provider.fetchMonthlyHoursTrend(start: start, end: end);
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial = _selectedRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 29)), end: now);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: initial,
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
      _loadData();
    }
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (preset) {
      case '7':
        start = now.subtract(const Duration(days: 6));
        break;
      case '30':
        start = now.subtract(const Duration(days: 29));
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'quarter':
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        start = DateTime(now.year, quarterStartMonth, 1);
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        break;
      case 'clear':
        setState(() {
          _selectedRange = null;
        });
        _loadData();
        return;
      default:
        return;
    }

    setState(() {
      _selectedRange = DateTimeRange(start: start, end: end);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analytics = Provider.of<AdminAnalyticsProvider>(context);

    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          TextButton.icon(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range, color: Colors.white),
            label: Text(
              _selectedRange == null
                  ? 'Last 30d'
                  : '${DateFormat('MMM d').format(_selectedRange!.start)} - ${DateFormat('MMM d').format(_selectedRange!.end)}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              _applyPreset(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7', child: Text('Last 7 days')),
              const PopupMenuItem(value: '30', child: Text('Last 30 days')),
              const PopupMenuItem(value: 'month', child: Text('This month')),
              const PopupMenuItem(
                  value: 'quarter', child: Text('This quarter')),
              const PopupMenuItem(value: 'year', child: Text('This year')),
              const PopupMenuItem(value: 'clear', child: Text('Clear filter')),
            ],
          )
        ],
      ),
      drawer: const AdminSideNavigation(currentRoute: '/analytics'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Report generation feature is under development.')),
          );
        },
        icon: const Icon(Icons.download),
        label: const Text('Generate Report'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          int columns;
          if (width >= 900) {
            columns = 4;
          } else if (width >= 600) {
            columns = 3;
          } else if (width >= 400) {
            columns = 2;
          } else {
            columns = 1;
          }

          final cardWidth = (width - (columns - 1) * 12 - 32) /
              columns; // 32 padding horizontal

          final kpis = _buildKpis(analytics.summary);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: kpis
                    .map((kpi) =>
                        _buildKpiCard(theme, kpi, fixedWidth: cardWidth))
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text('Monthly Hours Worked',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: AspectRatio(
                    aspectRatio: 1.8,
                    child: _buildMonthlyHoursChart(
                        theme, analytics.monthlyHoursTrend),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Leave Type Distribution',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: AspectRatio(
                    aspectRatio: 1.3,
                    child: _buildPieChart(theme, analytics.leaveBreakdown),
                  ),
                ),
              ),
              const SizedBox(height: 80),
              if (analytics.isLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiCard(ThemeData theme, Map<String, dynamic> kpi,
      {double? fixedWidth}) {
    final accent = kpi['color'] as Color? ?? theme.colorScheme.primary;
    return SizedBox(
      width: fixedWidth ?? 180,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Accent bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kpi['value'],
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : theme.colorScheme.onSurface)),
                      const SizedBox(height: 6),
                      Text(kpi['title'],
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7))),
                    ],
                  ),
                ),
              ],
            ),
            // Icon badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(kpi['icon'] as IconData, size: 18, color: accent),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyHoursChart(ThemeData theme, List<dynamic> trend) {
    // Prepare data map
    final Map<String, double> map = {};
    for (var e in trend) {
      if (e is Map && e['month'] != null && e['hours'] != null) {
        map[e['month']] = (e['hours'] as num).toDouble();
      }
    }

    final now = DateTime.now();
    final List<DateTime> monthsList =
        List.generate(12, (i) => DateTime(now.year, now.month - 11 + i, 1));
    final monthLabels =
        monthsList.map((dt) => DateFormat('MMM').format(dt)).toList();
    final hours = monthsList.map<double>((dt) {
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      final val = map[key] ?? 0.0;
      return val < 0 ? 0 : val;
    }).toList();

    final maxY = hours.reduce((a, b) => a > b ? a : b);
    final interval = _calculateYInterval(hours);

    final spots =
        List.generate(hours.length, (i) => FlSpot(i.toDouble(), hours[i]));

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 5 : maxY * 1.2,
        gridData: FlGridData(
          show: true,
          verticalInterval: 1,
          horizontalInterval: interval,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outline.withOpacity(0.15),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}h',
                    style: theme.textTheme.bodySmall);
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= monthLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child:
                      Text(monthLabels[idx], style: theme.textTheme.bodySmall),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: theme.colorScheme.primary,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withOpacity(0.15),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots
                .map((s) => LineTooltipItem(
                      '${monthLabels[s.x.toInt()]}\n${s.y.toStringAsFixed(1)}h',
                      TextStyle(color: theme.colorScheme.onPrimary),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(ThemeData theme, Map<String, dynamic>? attendance) {
    if (attendance == null || attendance.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final colors = [Colors.blue, Colors.orange, Colors.red, Colors.green];

    final entries = attendance.entries.toList();
    final total =
        attendance.values.fold<int>(0, (prev, v) => prev + (v as int));

    final sections = List.generate(entries.length, (idx) {
      final e = entries[idx];
      final value = (e.value as num).toDouble();
      final pct = total > 0 ? ((value / total) * 100).toStringAsFixed(1) : '0';
      return {
        'value': value,
        'label': e.key,
        'pct': pct,
        'color': colors[idx % colors.length],
      };
    });

    return PieChart(
      PieChartData(
        sections: sections
            .map((s) => PieChartSectionData(
                  value: s['value'] as double,
                  color: s['color'] as Color,
                  title: '${s['pct']}%',
                  titleStyle: TextStyle(
                      color: theme.colorScheme.onPrimary, fontSize: 12),
                ))
            .toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  List<Map<String, dynamic>> _buildKpis(Map<String, dynamic>? summary) {
    String fmtHours(num? h) => h == null ? '—' : '${h}h';
    String fmtPercent(num? p) => p == null ? '—' : '$p%';

    String fmtTime(String? iso) {
      if (iso == null) return '—';
      final dt = DateTime.tryParse(iso);
      if (dt == null) return '—';
      return DateFormat('hh:mm a').format(dt.toLocal());
    }

    final colors = [Colors.blue, Colors.orange, Colors.red, Colors.green];
    return [
      {
        'title': 'Total Hours',
        'value': fmtHours(summary?['totalHours']),
        'icon': Icons.timer,
        'color': colors[0],
      },
      {
        'title': 'Overtime',
        'value': fmtHours(summary?['overtimeHours']),
        'icon': Icons.alarm_add,
        'color': colors[1],
      },
      {
        'title': 'Absence Rate',
        'value': fmtPercent(summary?['absenceRate']),
        'icon': Icons.person_off,
        'color': colors[2],
      },
      {
        'title': 'Avg Check-In',
        'value': fmtTime(summary?['avgCheckIn']),
        'icon': Icons.login,
        'color': colors[3],
      },
    ];
  }

  double _calculateYInterval(List<double> list) {
    final maxVal = list.isEmpty ? 0 : list.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 10) return 2;
    if (maxVal <= 50) return 10;
    if (maxVal <= 100) return 20;
    return (maxVal / 5).ceilToDouble();
  }
}
