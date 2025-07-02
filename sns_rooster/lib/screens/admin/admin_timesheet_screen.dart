import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_attendance_provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/admin_side_navigation.dart';
import '../../providers/employee_provider.dart';
import 'edit_attendance_dialog.dart';
import 'package:flutter/scheduler.dart';
import '../../models/employee.dart';

class AdminTimesheetScreen extends StatefulWidget {
  const AdminTimesheetScreen({Key? key}) : super(key: key);

  @override
  State<AdminTimesheetScreen> createState() => _AdminTimesheetScreenState();
}

class _AdminTimesheetScreenState extends State<AdminTimesheetScreen> {
  DateTimeRange? _dateRange;
  String? _selectedEmployeeId;
  List<Employee> _employeeList = [];
  bool isExporting = false;

  @override
  void initState() {
    super.initState();
    _dateRange = DateTimeRange(
      start: DateTime(DateTime.now().year, DateTime.now().month, 1),
      end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Fetch employees for dropdown
      final employeeProvider =
          Provider.of<EmployeeProvider>(context, listen: false);
      await employeeProvider.getEmployees();
      setState(() {
        _employeeList = List<Employee>.from(employeeProvider.employees);
      });
      Provider.of<AdminAttendanceProvider>(context, listen: false)
          .fetchAttendanceLegacy(
        start: DateFormat('yyyy-MM-dd').format(_dateRange!.start),
        end: DateFormat('yyyy-MM-dd').format(_dateRange!.end),
        userId: _selectedEmployeeId,
      );
    });
  }

  Future<DateTimeRange?> _showCustomDateRangePicker(
      BuildContext context, DateTimeRange? initialRange) {
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: initialRange,
      builder: (context, child) {
        final baseScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final pickerScheme = (isDark
                ? ColorScheme.dark(
                    primary: baseScheme.primary,
                    onPrimary: baseScheme.onPrimary,
                    surface: baseScheme.surface,
                    onSurface: baseScheme.onSurface,
                  )
                : ColorScheme.light(
                    primary: baseScheme.primary,
                    onPrimary: baseScheme.onPrimary,
                    surface: baseScheme.surface,
                    onSurface: baseScheme.onSurface,
                  ))
            .copyWith(
          secondary: baseScheme.secondary,
        );

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: pickerScheme,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: baseScheme.primary,
                textStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            dialogTheme: DialogThemeData(backgroundColor: baseScheme.surface),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await _showCustomDateRangePicker(context, _dateRange);
    if (picked != null) {
      setState(() => _dateRange = picked);
      Provider.of<AdminAttendanceProvider>(context, listen: false)
          .fetchAttendanceLegacy(
        start: DateFormat('yyyy-MM-dd').format(picked.start),
        end: DateFormat('yyyy-MM-dd').format(picked.end),
        userId: _selectedEmployeeId,
      );
    }
  }

  void _onEmployeeChanged(String? employeeId) {
    setState(() => _selectedEmployeeId = employeeId);
    Provider.of<AdminAttendanceProvider>(context, listen: false)
        .fetchAttendanceLegacy(
      start: DateFormat('yyyy-MM-dd').format(_dateRange!.start),
      end: DateFormat('yyyy-MM-dd').format(_dateRange!.end),
      userId: employeeId,
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    return DateFormat('HH:mm').format(dt.toLocal());
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  String _formatTotalHours(String? inIso, String? outIso, int? breakMs) {
    if (inIso == null || outIso == null) return '0h 0m';
    final inDt = DateTime.tryParse(inIso);
    final outDt = DateTime.tryParse(outIso);
    if (inDt == null || outDt == null) return '0h 0m';
    int total = outDt.difference(inDt).inMilliseconds - (breakMs ?? 0);
    if (total < 0) total = 0;
    final h = total ~/ (1000 * 60 * 60);
    final m = ((total % (1000 * 60 * 60)) / (1000 * 60)).round();
    return '${h}h ${m}m';
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'leave':
        return Colors.orange;
      case 'late':
        return Colors.amber;
      case 'halfDay':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatBreaks(List<dynamic>? breaks) {
    if (breaks == null || breaks.isEmpty) return '0h 0m';
    int totalMs = 0;
    for (final b in breaks) {
      if (b['start'] != null && b['end'] != null) {
        final start = DateTime.tryParse(b['start'].toString());
        final end = DateTime.tryParse(b['end'].toString());
        if (start != null && end != null) {
          totalMs += end.difference(start).inMilliseconds;
        }
      }
    }
    if (totalMs < 0) totalMs = 0;
    final d = Duration(milliseconds: totalMs);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m}m';
  }

  void _showBreakDetailsDialog(BuildContext context, List<dynamic>? breaks) {
    showDialog(
      context: context,
      builder: (context) {
        if (breaks == null || breaks.isEmpty) {
          return AlertDialog(
            title: const Text('Break Details'),
            content: const Text('No breaks recorded.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'))
            ],
          );
        }
        return AlertDialog(
          title: const Text('Break Details'),
          content: SizedBox(
            width: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: breaks.length,
              itemBuilder: (context, idx) {
                final b = breaks[idx];
                final start = b['start'] != null
                    ? DateTime.tryParse(b['start'].toString())
                    : null;
                final end = b['end'] != null
                    ? DateTime.tryParse(b['end'].toString())
                    : null;
                final type =
                    (b['type'] is Map && b['type']['displayName'] != null)
                        ? b['type']['displayName']
                        : b['type']?.toString() ?? '-';
                final reason = b['reason']?.toString() ?? '';
                String duration = '-';
                if (start != null && end != null) {
                  final d = end.difference(start);
                  duration = '${d.inHours}h ${d.inMinutes % 60}m';
                }
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Break ${idx + 1}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Type: $type'),
                        Text(
                            'Start: ${start != null ? DateFormat('HH:mm').format(start.toLocal()) : '-'}'),
                        Text(
                            'End: ${end != null ? DateFormat('HH:mm').format(end.toLocal()) : '-'}'),
                        Text('Duration: $duration'),
                        if (reason.isNotEmpty) Text('Reason: $reason'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'))
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Timesheet')),
      drawer: const AdminSideNavigation(currentRoute: '/admin_timesheet'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.date_range),
                    label: Text(_dateRange == null
                        ? 'Select Date Range'
                        : '${DateFormat('MMM d, yyyy').format(_dateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_dateRange!.end)}'),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _selectedEmployeeId,
                    hint: const Text('All Employees'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Employees'),
                      ),
                      ..._employeeList.map((emp) => DropdownMenuItem<String>(
                            value: emp.userId,
                            child: Text('${emp.firstName} ${emp.lastName}'),
                          )),
                    ],
                    onChanged: _onEmployeeChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Colors.black26,
              ),
              onPressed: isExporting
                  ? null
                  : () async {
                      setState(() => isExporting = true);
                      final provider = Provider.of<AdminAttendanceProvider>(
                          context,
                          listen: false);
                      final filePath = await provider.exportAttendance(
                        start:
                            DateFormat('yyyy-MM-dd').format(_dateRange!.start),
                        end: DateFormat('yyyy-MM-dd').format(_dateRange!.end),
                        userId: _selectedEmployeeId,
                      );
                      setState(() => isExporting = false);
                      if (filePath != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('CSV exported to: $filePath')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  provider.error ?? 'Failed to export CSV')),
                        );
                      }
                    },
              icon: isExporting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: colorScheme.onPrimary))
                  : Icon(Icons.download,
                      size: 22, color: colorScheme.onPrimary),
              label: const Text('Export CSV',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.swipe, size: 18, color: Colors.grey),
                SizedBox(width: 4),
                Text('Swipe left/right to see more',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<AdminAttendanceProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (provider.error != null) {
                    return Center(child: Text('Error: ${provider.error}'));
                  } else if (provider.attendanceRecords.isEmpty) {
                    return const Center(
                        child: Text('No attendance records found.'));
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                          colorScheme.surfaceContainerHighest.withOpacity(0.5)),
                      columns: const [
                        DataColumn(
                            label: Text('Employee',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Date',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Check In',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Check Out',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Total Hours',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Break',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Status',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Actions',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: List<DataRow>.generate(
                        provider.attendanceRecords.length,
                        (index) {
                          final rec = provider.attendanceRecords[index];
                          final user = rec.user;
                          final status = rec.status.toString() ?? 'present';
                          return DataRow(
                            color: WidgetStateProperty.resolveWith<Color?>(
                                (Set<WidgetState> states) {
                              return index % 2 == 0
                                  ? colorScheme.surface
                                  : colorScheme.surfaceContainerHighest
                                      .withOpacity(0.2);
                            }),
                            cells: [
                              DataCell(Text(
                                  user != null
                                      ? (user['name'] ??
                                          user['firstName'] ??
                                          '—')
                                      : '—',
                                  style: const TextStyle(fontSize: 15))),
                              DataCell(Text(_formatDate(rec.date.toString()),
                                  style: const TextStyle(fontSize: 15))),
                              DataCell(Text(
                                  _formatTime(rec.checkInTime?.toString()),
                                  style: const TextStyle(fontSize: 15))),
                              DataCell(Text(
                                  _formatTime(rec.checkOutTime?.toString()),
                                  style: const TextStyle(fontSize: 15))),
                              DataCell(Text(
                                  _formatTotalHours(
                                      rec.checkInTime?.toString(),
                                      rec.checkOutTime?.toString(),
                                      rec.totalBreakDuration),
                                  style: const TextStyle(fontSize: 15))),
                              DataCell(Row(
                                children: [
                                  Text(_formatBreaks(rec.breaks),
                                      style: const TextStyle(fontSize: 15)),
                                  const SizedBox(width: 8),
                                  _buildBreakBadge(rec.toJson()),
                                  if (rec.breaks != null &&
                                      (rec.breaks as List).isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.info_outline,
                                          size: 18),
                                      tooltip: 'View break details',
                                      onPressed: () => _showBreakDetailsDialog(
                                          context, rec.breaks),
                                    ),
                                ],
                              )),
                              DataCell(
                                Builder(
                                  builder: (context) {
                                    if (status == 'on_break') {
                                      // Find the last break with no end time
                                      final breaks = rec.breaks;
                                      Map<String, dynamic>? lastBreak;
                                      if (breaks != null && breaks.isNotEmpty) {
                                        final b = breaks.lastWhere(
                                          (b) =>
                                              b['start'] != null &&
                                              b['end'] == null,
                                          orElse: () => null,
                                        );
                                        if (b != null) {
                                          lastBreak =
                                              Map<String, dynamic>.from(b);
                                        }
                                      }
                                      String breakType = lastBreak != null
                                          ? (lastBreak['type'] is Map &&
                                                  lastBreak['type']
                                                          ['displayName'] !=
                                                      null
                                              ? lastBreak['type']['displayName']
                                              : lastBreak['type']?.toString() ??
                                                  '-')
                                          : '-';
                                      DateTime? breakStart =
                                          lastBreak != null &&
                                                  lastBreak['start'] != null
                                              ? DateTime.tryParse(
                                                  lastBreak['start'].toString())
                                              : null;
                                      return Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                    Icons.pause_circle_filled,
                                                    color: Colors.orange,
                                                    size: 18),
                                                const SizedBox(width: 4),
                                                const Text('on break',
                                                    style: TextStyle(
                                                        color: Colors.orange,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                if (breakType != '-') ...[
                                                  const SizedBox(width: 6),
                                                  Text('($breakType)',
                                                      style: TextStyle(
                                                          color: Colors
                                                              .orange[700],
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                ],
                                                if (breakStart != null) ...[
                                                  const SizedBox(width: 8),
                                                  _LiveBreakTimer(
                                                      start: breakStart),
                                                ]
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status)
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(status,
                                            style: TextStyle(
                                                color: _statusColor(status),
                                                fontWeight: FontWeight.bold)),
                                      );
                                    }
                                  },
                                ),
                              ),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () async {
                                      final updated = await showDialog<
                                          Map<String, dynamic>>(
                                        context: context,
                                        builder: (context) =>
                                            EditAttendanceDialog(
                                          initialData: rec.toJson(),
                                          onSave:
                                              (_) {}, // No-op, handled by dialog pop
                                        ),
                                      );
                                      if (updated != null) {
                                        final provider = Provider.of<
                                                AdminAttendanceProvider>(
                                            context,
                                            listen: false);
                                        final success =
                                            await provider.editAttendance(
                                                rec.id ?? '', updated);
                                        if (success) {
                                          await provider.fetchAttendanceLegacy(
                                            start: DateFormat('yyyy-MM-dd')
                                                .format(_dateRange!.start),
                                            end: DateFormat('yyyy-MM-dd')
                                                .format(_dateRange!.end),
                                            userId: _selectedEmployeeId,
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Attendance updated successfully.')),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(provider.error ??
                                                    'Failed to update attendance.')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              )),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimesheetSummary extends StatelessWidget {
  final double totalHours;
  final int presentCount;
  final int absentCount;
  final double overtimeHours;

  const TimesheetSummary({
    super.key,
    required this.totalHours,
    required this.presentCount,
    required this.absentCount,
    required this.overtimeHours,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(context, 'Total Hours',
                '${totalHours.toStringAsFixed(1)}h', Icons.timer, Colors.blue),
            _buildStatItem(context, 'Present', '$presentCount',
                Icons.check_circle, Colors.green),
            _buildStatItem(
                context, 'Absent', '$absentCount', Icons.cancel, Colors.red),
            _buildStatItem(
                context,
                'Overtime',
                '${overtimeHours.toStringAsFixed(1)}h',
                Icons.alarm_add,
                Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _LiveBreakTimer extends StatefulWidget {
  final DateTime start;
  const _LiveBreakTimer({required this.start});

  @override
  State<_LiveBreakTimer> createState() => _LiveBreakTimerState();
}

class _LiveBreakTimerState extends State<_LiveBreakTimer> {
  late Duration _elapsed;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.start);
    _ticker = Ticker(_onTick)..start();
  }

  void _onTick(Duration _) {
    setState(() {
      _elapsed = DateTime.now().difference(widget.start);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes % 60;
    final s = _elapsed.inSeconds % 60;
    return Text(
      h > 0 ? '${h}h ${m}m ${s}s' : '${m}m ${s}s',
      style: TextStyle(
          color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 12),
    );
  }
}

Widget _buildBreakBadge(Map<String, dynamic> rec) {
  final breaks = rec['breaks'] as List?;
  if (breaks != null && breaks.isNotEmpty) {
    final ongoing = breaks.any((b) => b['end'] == null);
    if (ongoing) {
      return const Row(
        children: [
          Icon(Icons.pause_circle_filled, color: Colors.orange, size: 18),
          SizedBox(width: 4),
          Text('On Break',
              style:
                  TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          SizedBox(width: 4),
          Icon(Icons.circle, color: Colors.red, size: 10),
          SizedBox(width: 2),
          Text('LIVE',
              style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      );
    } else {
      return const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.blue, size: 18),
          SizedBox(width: 4),
          Text('Break Ended',
              style:
                  TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ],
      );
    }
  } else {
    return const Row(
      children: [
        Icon(Icons.remove_circle_outline, color: Colors.grey, size: 18),
        SizedBox(width: 4),
        Text('No Break',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
