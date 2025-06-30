import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/admin_side_navigation.dart';
import '../../providers/admin_attendance_provider.dart';
import '../../providers/employee_provider.dart';
import '../../models/employee.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({super.key});

  @override
  State<AttendanceManagementScreen> createState() =>
      _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState
    extends State<AttendanceManagementScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedEmployeeId;
  bool _isFiltering = false;
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalPages = 1;
  int _totalRecords = 0;

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = null;
    // Fetch all attendance records when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchAttendancePage(1);
      Provider.of<EmployeeProvider>(context, listen: false).getEmployees();
    });
  }

  Future<void> _fetchAttendancePage(int page) async {
    setState(() => _isFiltering = true);
    final provider =
        Provider.of<AdminAttendanceProvider>(context, listen: false);
    await provider.fetchAttendance(
      start: _startDate != null ? _startDate!.toIso8601String() : null,
      end: _endDate != null ? _endDate!.toIso8601String() : null,
      userId: _selectedEmployeeId,
      page: page,
      limit: _pageSize,
    );
    // Try to get total and page info from provider (assume provider sets these fields)
    if (provider.total != null && provider.page != null) {
      setState(() {
        _totalRecords = provider.total!;
        _currentPage = provider.page!;
        _totalPages = (_totalRecords / _pageSize).ceil();
      });
    }
    setState(() => _isFiltering = false);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    final date = DateTime.tryParse(dateString)?.toLocal();
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    final dateTime = DateTime.tryParse(dateTimeString)?.toLocal();
    if (dateTime == null) return 'N/A';
    return DateFormat('hh:mm a').format(dateTime);
  }

  String _formatMinutesToHourMin(int? minutes) {
    if (minutes == null || minutes <= 0) return '0h 0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'present':
        color = Colors.green;
        break;
      case 'on break':
        color = Colors.orange;
        break;
      case 'clocked in':
        color = Colors.blue;
        break;
      case 'absent':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      drawer: const AdminSideNavigation(currentRoute: '/attendance_management'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    // Date Range Picker
                    SizedBox(
                      width: 200,
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDateRange:
                                _startDate != null && _endDate != null
                                    ? DateTimeRange(
                                        start: _startDate!, end: _endDate!)
                                    : null,
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked.start;
                              _endDate = picked.end;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: colorScheme.primary.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(10),
                            color: colorScheme.surfaceVariant.withOpacity(0.3),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.date_range, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _startDate != null && _endDate != null
                                    ? '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}'
                                    : 'Select Date Range',
                                style: TextStyle(
                                    fontSize: 14, color: colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Employee Dropdown
                    SizedBox(
                      width: 200,
                      child: employeeProvider.isLoading
                          ? const LinearProgressIndicator(minHeight: 2)
                          : DropdownButtonFormField<String>(
                              value: _selectedEmployeeId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Employee',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                    value: null, child: Text('All Employees')),
                                ...employeeProvider.employees
                                    .map<DropdownMenuItem<String>>((emp) {
                                  return DropdownMenuItem<String>(
                                    value: emp.userId,
                                    child: Text(emp.name),
                                  );
                                }).toList(),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedEmployeeId = val;
                                });
                              },
                            ),
                    ),
                    // Filter Button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.filter_alt),
                        label: const Text('Filter'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isFiltering
                            ? null
                            : () async {
                                await _fetchAttendancePage(1);
                              },
                      ),
                    ),
                    // Clear Button
                    SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: () async {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                            _selectedEmployeeId = null;
                          });
                          await _fetchAttendancePage(1);
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                    // Export Dropdown Button
                    SizedBox(
                      height: 48,
                      child: PopupMenuButton<String>(
                        onSelected: (value) async {
                          final provider = Provider.of<AdminAttendanceProvider>(
                              context,
                              listen: false);
                          final employeeProvider =
                              Provider.of<EmployeeProvider>(context,
                                  listen: false);
                          String? employeeName;
                          if (_selectedEmployeeId != null) {
                            final emp = employeeProvider.employees.firstWhere(
                              (e) => e.userId == _selectedEmployeeId,
                              orElse: () => Employee(
                                id: '',
                                userId: '',
                                firstName: '',
                                lastName: '',
                                email: '',
                                employeeId: '',
                                hireDate: DateTime.now(),
                              ),
                            );
                            if (emp.userId.isNotEmpty) employeeName = emp.name;
                          }
                          if (value == 'Export CSV') {
                            print('DEBUG EXPORT: employeeName=' +
                                employeeName.toString());
                            final filePath = await provider.exportAttendance(
                              start: _startDate?.toIso8601String(),
                              end: _endDate?.toIso8601String(),
                              userId: _selectedEmployeeId,
                              employeeName: employeeName,
                            );
                            if (filePath != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('CSV exported to: $filePath')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(provider.error ??
                                        'Failed to export CSV')),
                              );
                            }
                          } else if (value == 'Export PDF') {
                            final filePath = await provider.exportAttendancePdf(
                              start: _startDate?.toIso8601String(),
                              end: _endDate?.toIso8601String(),
                              userId: _selectedEmployeeId,
                              employeeName: employeeName,
                            );
                            if (filePath != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('PDF exported to: $filePath')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(provider.error ??
                                        'Failed to export PDF')),
                              );
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'Export CSV',
                              child: Text('Export to CSV')),
                          const PopupMenuItem(
                              value: 'Export PDF',
                              child: Text('Export to PDF')),
                        ],
                        child: IgnorePointer(
                          ignoring: true,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.download),
                            label: const Text('Export'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildPaginationControls(),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) => _isFiltering
                  ? const Center(child: CircularProgressIndicator())
                  : _buildAttendanceList(context, colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(BuildContext context, ColorScheme colorScheme) {
    return Consumer<AdminAttendanceProvider>(
      builder: (context, adminAttendanceProvider, child) {
        if (adminAttendanceProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (adminAttendanceProvider.error != null) {
          return Center(
            child: Text(
              'Error: ${adminAttendanceProvider.error}',
              style: TextStyle(color: colorScheme.error),
            ),
          );
        } else if (adminAttendanceProvider.attendanceRecords.isEmpty) {
          return Center(
            child: Text(
              'No attendance records found.',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          );
        } else {
          return RefreshIndicator(
            onRefresh: () async {
              await _fetchAttendancePage(_currentPage);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: adminAttendanceProvider.attendanceRecords.length,
              itemBuilder: (context, index) {
                final record = adminAttendanceProvider.attendanceRecords[index];
                final user = record.user;
                final employeeName = user != null
                    ? (user['name'] ?? user['firstName'] ?? '-')
                    : '-';
                final employeeEmail =
                    user != null ? (user['email'] ?? '-') : '-';
                final status = record.status ?? 'N/A';
                final breakStatus = record.breakStatus ?? '';
                final breaks = record.breaks ?? [];
                int? totalBreakMinutes = record.totalBreakDuration;
                if (totalBreakMinutes != null && totalBreakMinutes < 0)
                  totalBreakMinutes = 0;
                // If value is huge, treat as ms and convert to min
                if (totalBreakMinutes != null && totalBreakMinutes > 1440) {
                  totalBreakMinutes = (totalBreakMinutes / 60000).round();
                }
                final totalBreakStr =
                    _formatMinutesToHourMin(totalBreakMinutes);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                employeeName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (status != 'N/A')
                              _statusBadge(status.toString()),
                          ],
                        ),
                        if (employeeEmail != '-')
                          Padding(
                            padding: const EdgeInsets.only(left: 30, top: 2),
                            child: Text(
                              employeeEmail,
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Date: ${_formatDate(record.date.toIso8601String())}',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, left: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.login, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Check-in: ${_formatTime(record.checkInTime?.toIso8601String())}',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(width: 18),
                              const Icon(Icons.logout, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Check-out: ${_formatTime(record.checkOutTime?.toIso8601String())}',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.timer, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Total Break Time: $totalBreakStr',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (breakStatus == 'on_break')
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'On Break',
                                      style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (breaks.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0, left: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Breaks:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...breaks.map<Widget>((breakRecord) {
                                  final startTime =
                                      _formatTime(breakRecord['start']);
                                  final endTime = breakRecord['end'] != null
                                      ? _formatTime(breakRecord['end'])
                                      : 'Ongoing';
                                  int? breakDuration = breakRecord['duration']
                                          is int
                                      ? breakRecord['duration']
                                      : int.tryParse(
                                          breakRecord['duration'].toString());
                                  if (breakDuration != null &&
                                      breakDuration > 1440) {
                                    breakDuration =
                                        (breakDuration / 60000).round();
                                  }
                                  final duration = breakDuration != null
                                      ? _formatMinutesToHourMin(breakDuration)
                                      : 'N/A';
                                  final isOngoing = breakRecord['end'] == null;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        left: 12.0, bottom: 2.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isOngoing
                                              ? Icons.play_arrow
                                              : Icons.pause,
                                          size: 14,
                                          color: isOngoing
                                              ? Colors.orange
                                              : colorScheme.onSurface
                                                  .withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            '$startTime - $endTime',
                                            style: TextStyle(
                                              color: isOngoing
                                                  ? Colors.orange
                                                  : colorScheme.onSurface
                                                      .withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '($duration)',
                                          style: TextStyle(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.6),
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _currentPage > 1
              ? () => _fetchAttendancePage(_currentPage - 1)
              : null,
        ),
        ...List.generate(_totalPages, (i) {
          final page = i + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _currentPage == page ? Colors.blue : Colors.grey[200],
                foregroundColor:
                    _currentPage == page ? Colors.white : Colors.black,
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _currentPage == page
                  ? null
                  : () => _fetchAttendancePage(page),
              child: Text('$page'),
            ),
          );
        }),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < _totalPages
              ? () => _fetchAttendancePage(_currentPage + 1)
              : null,
        ),
        const SizedBox(width: 12),
        Text('Page $_currentPage of $_totalPages'),
      ],
    );
  }
}
