import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_attendance_provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/admin_side_navigation.dart';
import '../../providers/employee_provider.dart';
import 'edit_attendance_dialog.dart';
import 'package:flutter/scheduler.dart';
import '../../models/employee.dart';
import '../../models/attendance.dart';
import '../../widgets/role_filter_chip.dart';

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
  String? _selectedRole; // Add this

  // Helper for today
  DateTimeRange get _todayRange {
    final now = DateTime.now();
    return DateTimeRange(
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day));
  }

  // Helper for yesterday
  DateTimeRange get _yesterdayRange {
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));
    return DateTimeRange(
        start: DateTime(yesterday.year, yesterday.month, yesterday.day),
        end: DateTime(yesterday.year, yesterday.month, yesterday.day));
  }

  // Helper for this week (Mon-Sun)
  DateTimeRange get _thisWeekRange {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(Duration(days: 6));
    return DateTimeRange(
        start: DateTime(start.year, start.month, start.day),
        end: DateTime(end.year, end.month, end.day));
  }

  // Helper for this month
  DateTimeRange get _thisMonthRange {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return DateTimeRange(start: start, end: end);
  }

  @override
  void initState() {
    super.initState();
    _dateRange = _todayRange;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
        role: _selectedRole == 'employee' ? 'employee' : 'all',
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
        role: _selectedRole == 'employee' ? 'employee' : 'all',
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
      role: _selectedRole == 'employee' ? 'employee' : 'all',
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

  void _handleEditAttendance(
      BuildContext context, Map<String, dynamic> rec) async {
    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditAttendanceDialog(
        initialData: rec,
        onSave: (data) => Navigator.of(context).pop(data),
      ),
    );
    if (updated != null) {
      final provider =
          Provider.of<AdminAttendanceProvider>(context, listen: false);
      final success = await provider.editAttendance(
          rec['id'] ?? rec['attendanceId'] ?? rec['_id'] ?? '', updated);
      if (success) {
        if (!mounted) return;
        // Automatically reset filters to show all records after edit
        setState(() {
          _selectedEmployeeId = null;
          _selectedRole = null;
          _dateRange = _todayRange;
        });
        _fetchAttendanceData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance updated successfully.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(provider.error ?? 'Failed to update attendance.')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _filteredRecords(List records) {
    return records.where((rec) {
      final user =
          rec is Map<String, dynamic> ? rec['user'] : (rec as dynamic).user;
      if (user == null ||
          (user is Map &&
              (user['firstName'] == null || user['lastName'] == null))) {
        return false;
      }
      if (_selectedEmployeeId != null && _selectedEmployeeId!.isNotEmpty) {
        // Use _id for matching
        final userId = user is Map ? user['_id']?.toString() : user.toString();
        print('Comparing userId: $userId with selected: $_selectedEmployeeId');
        if (userId != _selectedEmployeeId) return false;
      }
      return true;
    }).map<Map<String, dynamic>>((rec) {
      return rec is Map<String, dynamic> ? rec : (rec as dynamic).toJson();
    }).toList();
  }

  void _setQuickRange(DateTimeRange range) {
    setState(() => _dateRange = range);
    Provider.of<AdminAttendanceProvider>(context, listen: false)
        .fetchAttendanceLegacy(
      start: DateFormat('yyyy-MM-dd').format(range.start),
      end: DateFormat('yyyy-MM-dd').format(range.end),
      userId: _selectedEmployeeId,
      role: _selectedRole == 'employee' ? 'employee' : 'all',
    );
  }

  void _refreshData() {
    Provider.of<AdminAttendanceProvider>(context, listen: false)
        .fetchAttendanceLegacy(
      start: DateFormat('yyyy-MM-dd').format(_dateRange!.start),
      end: DateFormat('yyyy-MM-dd').format(_dateRange!.end),
      userId: _selectedEmployeeId,
      role: _selectedRole == 'employee' ? 'employee' : 'all',
    );
  }

  void _selectDateRange() async {
    final picked = await _showCustomDateRangePicker(context, _dateRange);
    if (picked != null) {
      setState(() => _dateRange = picked);
      _fetchAttendanceData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Timesheet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      drawer: const AdminSideNavigation(currentRoute: '/timesheet'),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Range Filter
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          '${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd').format(_dateRange!.end)}',
                        ),
                        onPressed: _selectDateRange,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearFilters,
                      tooltip: 'Clear Filters',
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Quick Date Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickFilterBtn(
                        label: 'Today',
                        selected: _dateRange != null &&
                            _dateRange!.start == _todayRange.start &&
                            _dateRange!.end == _todayRange.end,
                        onTap: () => _setQuickRange(_todayRange),
                      ),
                      const SizedBox(width: 8),
                      _QuickFilterBtn(
                        label: 'Yesterday',
                        selected: _dateRange != null &&
                            _dateRange!.start == _yesterdayRange.start &&
                            _dateRange!.end == _yesterdayRange.end,
                        onTap: () => _setQuickRange(_yesterdayRange),
                      ),
                      const SizedBox(width: 8),
                      _QuickFilterBtn(
                        label: 'This Week',
                        selected: _dateRange != null &&
                            _dateRange!.start == _thisWeekRange.start &&
                            _dateRange!.end == _thisWeekRange.end,
                        onTap: () => _setQuickRange(_thisWeekRange),
                      ),
                      const SizedBox(width: 8),
                      _QuickFilterBtn(
                        label: 'This Month',
                        selected: _dateRange != null &&
                            _dateRange!.start == _thisMonthRange.start &&
                            _dateRange!.end == _thisMonthRange.end,
                        onTap: () => _setQuickRange(_thisMonthRange),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Employee Filter
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedEmployeeId,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Employee',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Employees'),
                          ),
                          ..._employeeList.map((emp) => DropdownMenuItem(
                                value: emp.userId,
                                child: Text('${emp.firstName} ${emp.lastName}'),
                              )),
                        ],
                        onChanged: _onEmployeeChanged,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Role Filter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter by Role:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    RoleFilterChip(
                      selectedRole: _selectedRole,
                      onRoleChanged: _onRoleChanged,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Table Section ---
          Expanded(
            child: Consumer<AdminAttendanceProvider>(
              builder: (context, provider, child) {
                try {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (provider.error != null) {
                    debugPrint(
                        'AdminTimesheetScreen: Provider error: ${provider.error}');
                    return Center(child: Text('Error: ${provider.error}'));
                  }
                  final filtered = _filteredRecords(provider.attendanceRecords);
                  debugPrint(
                      'AdminTimesheetScreen: Filtered records count: ${filtered.length}');
                  if (filtered.isEmpty) {
                    debugPrint(
                        'AdminTimesheetScreen: Provider state: isLoading=${provider.isLoading}, error=${provider.error}, attendanceRecords=${provider.attendanceRecords.length}');
                    return const Center(
                        child: Text('No attendance records found.',
                            style:
                                TextStyle(fontSize: 16, color: Colors.grey)));
                  }
                  // Responsive: Use ListView on mobile, DataTable on wide screens
                  final isWide = MediaQuery.of(context).size.width > 700;
                  if (!isWide) {
                    // Mobile: Card list
                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final rec = filtered[index];
                        final user = rec is Map<String, dynamic>
                            ? rec['user']
                            : (rec as dynamic).user;
                        final name = user != null &&
                                user['firstName'] != null &&
                                user['lastName'] != null
                            ? '${user['firstName']} ${user['lastName']}'
                            : user != null && user['email'] != null
                                ? user['email']
                                : '(Deleted)';
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            title: Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Date: ${_formatDate(rec['date']?.toString())}'),
                                Text(
                                    'Check In: ${_formatTime(rec['checkInTime']?.toString())}'),
                                Text(
                                    'Check Out: ${_formatTime(rec['checkOutTime']?.toString())}'),
                                Text(
                                    'Total Hours: ${_formatTotalHours(rec['checkInTime']?.toString(), rec['checkOutTime']?.toString(), rec['totalBreakDuration'])}'),
                                Text('Status: ${rec['status'] ?? 'present'}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _handleEditAttendance(context, rec),
                            ),
                          ),
                        );
                      },
                    );
                  }
                  // Desktop/tablet: DataTable
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
                            label: Text('Status',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Actions',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: List<DataRow>.generate(
                        filtered.length,
                        (index) {
                          final rec = filtered[index];
                          final user = rec is Map<String, dynamic>
                              ? rec['user']
                              : (rec as dynamic).user;
                          final name = user != null &&
                                  user['firstName'] != null &&
                                  user['lastName'] != null
                              ? '${user['firstName']} ${user['lastName']}'
                              : user != null && user['email'] != null
                                  ? user['email']
                                  : '(Deleted)';
                          return DataRow(
                            color: WidgetStateProperty.resolveWith<Color?>(
                                (Set<WidgetState> states) {
                              return index % 2 == 0
                                  ? colorScheme.surface
                                  : colorScheme.surfaceContainerHighest
                                      .withOpacity(0.2);
                            }),
                            cells: [
                              DataCell(Text(name,
                                  style: const TextStyle(fontSize: 15))),
                              DataCell(Text(
                                  _formatDate(rec['date']?.toString()),
                                  style: const TextStyle(fontSize: 15))),
                              DataCell(Text(
                                  _formatTime(rec['checkInTime']?.toString()),
                                  style: const TextStyle(fontSize: 15))),
                              DataCell(Text(
                                  _formatTime(rec['checkOutTime']?.toString()),
                                  style: const TextStyle(fontSize: 15))),
                              DataCell(Text(
                                  _formatTotalHours(
                                      rec['checkInTime']?.toString(),
                                      rec['checkOutTime']?.toString(),
                                      rec['totalBreakDuration']),
                                  style: const TextStyle(fontSize: 15))),
                              DataCell(Text(
                                  rec['status']?.toString() ?? 'present',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: _statusColor(
                                          rec['status']?.toString())))),
                              DataCell(IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _handleEditAttendance(context, rec),
                              )),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                } catch (e, st) {
                  debugPrint(
                      'AdminTimesheetScreen: Exception in build: ${e.toString()}\n${st.toString()}');
                  return Center(
                      child: Text(
                          'An unexpected error occurred. Please try again.'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onRoleChanged(String? role) {
    setState(() {
      _selectedRole = role;
    });
    _fetchAttendanceData();
  }

  void _fetchAttendanceData() {
    final provider =
        Provider.of<AdminAttendanceProvider>(context, listen: false);
    String role = 'all';
    if (_selectedRole == 'employee') {
      role = 'employee';
    } else if (_selectedRole == 'admin') {
      role = 'admin';
    }
    debugPrint(
        'AdminTimesheetScreen: Fetching attendance with params: start=${DateFormat('yyyy-MM-dd').format(_dateRange!.start)}, end=${DateFormat('yyyy-MM-dd').format(_dateRange!.end)}, userId=$_selectedEmployeeId, role=$role');
    provider.fetchAttendanceLegacy(
      start: DateFormat('yyyy-MM-dd').format(_dateRange!.start),
      end: DateFormat('yyyy-MM-dd').format(_dateRange!.end),
      userId: _selectedEmployeeId,
      role: role,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedEmployeeId = null;
      _selectedRole = null;
      _dateRange = _todayRange;
    });
    _fetchAttendanceData();
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

class _QuickFilterBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _QuickFilterBtn(
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : null,
        side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300),
      ),
      onPressed: onTap,
      child: Text(label,
          style: TextStyle(
              color: selected ? Theme.of(context).colorScheme.primary : null)),
    );
  }
}
