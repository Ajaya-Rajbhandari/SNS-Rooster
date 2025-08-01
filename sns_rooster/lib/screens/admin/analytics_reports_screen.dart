import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/admin_side_navigation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_analytics_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

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
      provider.fetchLeaveApprovalStatus();
      provider.fetchMonthlyHoursTrend();
    } else {
      final start = _fmt(_selectedRange!.start);
      final end = _fmt(_selectedRange!.end);
      provider.fetchSummary(start: start, end: end);
      provider.fetchOverview(start: start, end: end);
      provider.fetchLeaveBreakdown(start: start, end: end);
      provider.fetchLeaveApprovalStatus(start: start, end: end);
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

  Future<void> _generateReport() async {
    try {
      // Show report type selection dialog
      final reportType = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Generate Report'),
          content:
              const Text('Select the type of report you want to generate:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('analytics'),
              child: const Text('Analytics Report (PDF)'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('leave'),
              child: const Text('Leave Data Export'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (reportType == null) return; // User cancelled

      final provider = context.read<AdminAnalyticsProvider>();

      String? start, end;
      if (_selectedRange != null) {
        start = _fmt(_selectedRange!.start);
        end = _fmt(_selectedRange!.end);
      }

      if (reportType == 'analytics') {
        // Generate analytics report (existing functionality)
        final reportData = await provider.generateReport(
            start: start, end: end, format: 'pdf');

        if (reportData != null && reportData is Uint8List) {
          // Generate filename with timestamp
          final now = DateTime.now();
          final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
          final periodText = _selectedRange != null
              ? '${_fmt(_selectedRange!.start)}_to_${_fmt(_selectedRange!.end)}'
              : 'last_30_days';
          final filename = 'analytics_report_${periodText}_$timestamp.pdf';

          // Get the appropriate directory based on platform
          Directory? directory;
          if (Platform.isAndroid) {
            // For Android, save to external storage directory (no permissions needed)
            directory = await getExternalStorageDirectory();
            // Create a Reports folder in the app's external storage
            final reportsDir = Directory('${directory?.path}/Reports');
            if (!await reportsDir.exists()) {
              await reportsDir.create(recursive: true);
            }
            directory = reportsDir;
          } else if (Platform.isIOS) {
            // For iOS, save to Documents directory
            directory = await getApplicationDocumentsDirectory();
          } else {
            // For other platforms, use Documents directory
            directory = await getApplicationDocumentsDirectory();
          }

          final file = File('${directory.path}/$filename');
          await file.writeAsBytes(reportData);

          if (mounted) {
            final friendlyPath = Platform.isAndroid
                ? 'Android/data/com.example.sns_rooster/files/Reports/'
                : 'Documents/';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Report generated successfully!'),
                    Text('Saved to: $friendlyPath$filename',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 8),
                action: SnackBarAction(
                  label: 'Open',
                  textColor: Colors.white,
                  onPressed: () async {
                    try {
                      await OpenFile.open(file.path);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not open file: $e'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            );
          }

          // Also try to open the file automatically
          try {
            await OpenFile.open(file.path);
          } catch (e) {
            // If auto-open fails, that's okay - user can still open manually
            print('Auto-open failed: $e');
          }
        } else {
          throw Exception('No report data received or invalid format');
        }
      } else if (reportType == 'leave') {
        // Generate leave export
        // Show format selection dialog
        final format = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Leave Data'),
            content: const Text('Select export format:'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('csv'),
                child: const Text('CSV'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('excel'),
                child: const Text('Excel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('json'),
                child: const Text('JSON'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );

        if (format == null) return; // User cancelled

        final exportData = await provider.exportLeaveData(
          start: start,
          end: end,
          format: format,
        );

        if (exportData != null) {
          // Generate filename with timestamp
          final now = DateTime.now();
          final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
          final periodText = _selectedRange != null
              ? '${_fmt(_selectedRange!.start)}_to_${_fmt(_selectedRange!.end)}'
              : 'all_time';
          final filename = 'leave_export_${periodText}_$timestamp.$format';

          // Get the appropriate directory based on platform
          Directory? directory;
          if (Platform.isAndroid) {
            // For Android, save to external storage directory (no permissions needed)
            directory = await getExternalStorageDirectory();
            // Create a Reports folder in the app's external storage
            final reportsDir = Directory('${directory?.path}/Reports');
            if (!await reportsDir.exists()) {
              await reportsDir.create(recursive: true);
            }
            directory = reportsDir;
          } else if (Platform.isIOS) {
            // For iOS, save to Documents directory
            directory = await getApplicationDocumentsDirectory();
          } else {
            // For other platforms, use Documents directory
            directory = await getApplicationDocumentsDirectory();
          }

          final file = File('${directory.path}/$filename');

          if (format == 'json') {
            // For JSON, write the string data
            await file.writeAsString(json.encode(exportData));
          } else {
            // For CSV/Excel, write the bytes
            await file.writeAsBytes(exportData);
          }

          if (mounted) {
            final friendlyPath = Platform.isAndroid
                ? 'Android/data/com.example.sns_rooster/files/Reports/'
                : 'Documents/';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Leave data exported successfully!'),
                    Text('Saved to: $friendlyPath$filename',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 8),
                action: SnackBarAction(
                  label: 'Open',
                  textColor: Colors.white,
                  onPressed: () async {
                    try {
                      await OpenFile.open(file.path);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not open file: $e'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            );
          }

          // Also try to open the file automatically
          try {
            await OpenFile.open(file.path);
          } catch (e) {
            // If auto-open fails, that's okay - user can still open manually
            print('Auto-open failed: $e');
          }
        } else {
          throw Exception('No leave data received or invalid format');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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
        onPressed: analytics.isLoading ? null : () => _generateReport(),
        icon: analytics.isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download),
        label: Text(analytics.isLoading ? 'Generating...' : 'Generate Report'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Using fixed 2x3 layout for all screen sizes

          final kpis = _buildKpis(analytics.summary);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // KPI Cards Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Key Performance Indicators',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        // First row: 2 cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildKpiCard(theme, kpis[0]),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildKpiCard(theme, kpis[1]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Second row: 2 cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildKpiCard(theme, kpis[2]),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildKpiCard(theme, kpis[3]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Third row: 2 cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildKpiCard(theme, kpis[4]),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildKpiCard(theme, kpis[5]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Charts Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.show_chart,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Analytics & Reports',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Monthly Hours Worked
                    Text(
                      'Monthly Hours Worked',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildChartCard(
                      theme,
                      child: AspectRatio(
                        aspectRatio: 1.8,
                        child: _buildMonthlyHoursChart(
                            theme, analytics.monthlyHoursTrend),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Leave Analytics Section
                    Text(
                      'Leave Analytics',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Leave Charts Row - Responsive Layout
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          // Mobile layout - stacked
                          return Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Leave Type Distribution',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildChartCard(
                                    theme,
                                    child: AspectRatio(
                                      aspectRatio: 1.3,
                                      child: _buildPieChart(
                                          theme, analytics.leaveBreakdown),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Leave Approval Status',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildChartCard(
                                    theme,
                                    child: AspectRatio(
                                      aspectRatio: 1.3,
                                      child: _buildLeaveApprovalChart(
                                          theme, analytics.leaveApprovalStatus),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        } else {
                          // Desktop layout - side by side
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Leave Type Distribution',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildChartCard(
                                      theme,
                                      child: AspectRatio(
                                        aspectRatio: 1.3,
                                        child: _buildPieChart(
                                            theme, analytics.leaveBreakdown),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Leave Approval Status',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildChartCard(
                                      theme,
                                      child: AspectRatio(
                                        aspectRatio: 1.3,
                                        child: _buildLeaveApprovalChart(theme,
                                            analytics.leaveApprovalStatus),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
              if (analytics.isLoading)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiCard(ThemeData theme, Map<String, dynamic> kpi) {
    final accent = kpi['color'] as Color? ?? theme.colorScheme.primary;
    final value = kpi['value'] as String;
    final hasData = value != '—' && value.isNotEmpty;

    return Card(
      elevation: 6,
      shadowColor: accent.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.05),
              accent.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12), // Even more compact padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon and title row
                  Row(
                    children: [
                      Container(
                        width: 28, // Even smaller icon container
                        height: 28,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          kpi['icon'] as IconData,
                          size: 14, // Even smaller icon
                          color: accent,
                        ),
                      ),
                      const Spacer(),
                      if (!hasData)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'No Data',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8), // Even more compact spacing
                  // Value
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasData
                          ? theme.colorScheme.onSurface
                          : Colors.grey[400],
                      fontSize: hasData ? 18 : 16, // Even smaller font size
                    ),
                  ),
                  const SizedBox(height: 4), // Minimal spacing
                  // Title
                  Text(
                    kpi['title'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: 11, // Smaller title text
                    ),
                  ),
                ],
              ),
            ),
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
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
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
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
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

  Widget _buildChartCard(ThemeData theme, {required Widget child}) {
    return Card(
      elevation: 4,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }

  Widget _buildLeaveApprovalChart(
      ThemeData theme, Map<String, dynamic>? approvalData) {
    if (approvalData == null || approvalData.isEmpty) {
      return const Center(child: Text('No approval data available'));
    }

    // Default approval data if not provided
    final data = approvalData.isEmpty
        ? {
            'Approved': 15,
            'Pending': 8,
            'Rejected': 3,
          }
        : approvalData;

    final colors = [Colors.green, Colors.orange, Colors.red];

    final entries = data.entries.toList();
    final total = data.values.fold<int>(0, (prev, v) => prev + (v as int));

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
    String fmtDays(num? d) => d == null ? '—' : '${d}d';

    String fmtTime(String? iso) {
      if (iso == null) return '—';
      final dt = DateTime.tryParse(iso);
      if (dt == null) return '—';
      return DateFormat('hh:mm a').format(dt.toLocal());
    }

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.teal
    ];
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
      // New Leave-specific KPIs
      {
        'title': 'Total Leave Days',
        'value': fmtDays(summary?['totalLeaveDays']),
        'icon': Icons.beach_access,
        'color': colors[4],
      },
      {
        'title': 'Leave Approval Rate',
        'value': fmtPercent(summary?['leaveApprovalRate']),
        'icon': Icons.check_circle,
        'color': colors[5],
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
