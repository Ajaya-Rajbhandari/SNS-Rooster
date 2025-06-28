import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_attendance_provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/admin_side_navigation.dart';
import '../../providers/employee_provider.dart';
import 'edit_attendance_dialog.dart';

class AdminTimesheetScreen extends StatefulWidget {
  const AdminTimesheetScreen({Key? key}) : super(key: key);

  @override
  State<AdminTimesheetScreen> createState() => _AdminTimesheetScreenState();
}

class _AdminTimesheetScreenState extends State<AdminTimesheetScreen> {
  DateTimeRange? _dateRange;
  String? _selectedEmployeeId;
  List<Map<String, dynamic>> _employeeList = [];

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
        _employeeList = employeeProvider.employees.cast<Map<String, dynamic>>();
      });
      Provider.of<AdminAttendanceProvider>(context, listen: false)
          .fetchAttendance(
        start: DateFormat('yyyy-MM-dd').format(_dateRange!.start),
        end: DateFormat('yyyy-MM-dd').format(_dateRange!.end),
        employeeId: _selectedEmployeeId,
      );
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      Provider.of<AdminAttendanceProvider>(context, listen: false)
          .fetchAttendance(
        start: DateFormat('yyyy-MM-dd').format(picked.start),
        end: DateFormat('yyyy-MM-dd').format(picked.end),
        employeeId: _selectedEmployeeId,
      );
    }
  }

  void _onEmployeeChanged(String? employeeId) {
    setState(() => _selectedEmployeeId = employeeId);
    Provider.of<AdminAttendanceProvider>(context, listen: false)
        .fetchAttendance(
      start: DateFormat('yyyy-MM-dd').format(_dateRange!.start),
      end: DateFormat('yyyy-MM-dd').format(_dateRange!.end),
      employeeId: employeeId,
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

  String _formatBreak(int? ms) {
    if (ms == null || ms == 0) return '-';
    final d = Duration(milliseconds: ms);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m}m';
  }

  String _formatTotalHours(String? inIso, String? outIso, int? breakMs) {
    if (inIso == null || outIso == null) return '-';
    final inDt = DateTime.tryParse(inIso);
    final outDt = DateTime.tryParse(outIso);
    if (inDt == null || outDt == null) return '-';
    final total = outDt.difference(inDt) - Duration(milliseconds: breakMs ?? 0);
    final h = total.inHours;
    final m = total.inMinutes % 60;
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
    if (breaks == null || breaks.isEmpty) return '-';
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
                            value: emp['userId'] as String?,
                            child:
                                Text('${emp['firstName']} ${emp['lastName']}'),
                          )),
                    ],
                    onChanged: _onEmployeeChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final provider = Provider.of<AdminAttendanceProvider>(context,
                    listen: false);
                final success = await provider.exportAttendance(
                  start: DateFormat('yyyy-MM-dd').format(_dateRange!.start),
                  end: DateFormat('yyyy-MM-dd').format(_dateRange!.end),
                  employeeId: _selectedEmployeeId,
                );
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(provider.error ?? 'Failed to export CSV')),
                  );
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Export CSV'),
            ),
            const SizedBox(height: 8),
            Row(
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
                      columns: const [
                        DataColumn(label: Text('Employee')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Check In')),
                        DataColumn(label: Text('Check Out')),
                        DataColumn(label: Text('Total Hours')),
                        DataColumn(label: Text('Break')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: provider.attendanceRecords.map((rec) {
                        final user = rec['user'];
                        final status = rec['status']?.toString() ?? 'present';
                        return DataRow(cells: [
                          DataCell(Text(user != null
                              ? (user['name'] ?? user['firstName'] ?? '-')
                              : '-')),
                          DataCell(Text(_formatDate(rec['date']?.toString()))),
                          DataCell(Text(
                              _formatTime(rec['checkInTime']?.toString()))),
                          DataCell(Text(
                              _formatTime(rec['checkOutTime']?.toString()))),
                          DataCell(Text(_formatTotalHours(
                              rec['checkInTime']?.toString(),
                              rec['checkOutTime']?.toString(),
                              rec['totalBreakDuration']))),
                          DataCell(Row(
                            children: [
                              Text(_formatBreaks(rec['breaks'] as List?)),
                              if ((rec['breaks'] as List?) != null &&
                                  (rec['breaks'] as List).isNotEmpty)
                                IconButton(
                                  icon:
                                      const Icon(Icons.info_outline, size: 18),
                                  tooltip: 'View break details',
                                  onPressed: () => _showBreakDetailsDialog(
                                      context, rec['breaks'] as List?),
                                ),
                            ],
                          )),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(status,
                                style: TextStyle(
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.bold)),
                          )),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final updated =
                                      await showDialog<Map<String, dynamic>>(
                                    context: context,
                                    builder: (context) => EditAttendanceDialog(
                                      initialData: rec,
                                      onSave:
                                          (_) {}, // No-op, handled by dialog pop
                                    ),
                                  );
                                  if (updated != null) {
                                    final provider =
                                        Provider.of<AdminAttendanceProvider>(
                                            context,
                                            listen: false);
                                    final success = await provider
                                        .editAttendance(rec['_id'], updated);
                                    if (success) {
                                      await provider.fetchAttendance(
                                        start: DateFormat('yyyy-MM-dd')
                                            .format(_dateRange!.start),
                                        end: DateFormat('yyyy-MM-dd')
                                            .format(_dateRange!.end),
                                        employeeId: _selectedEmployeeId,
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
                        ]);
                      }).toList(),
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
    final theme = Theme.of(context);
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
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
