import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sns_rooster/providers/attendance_provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import 'package:sns_rooster/widgets/app_drawer.dart';
import 'package:sns_rooster/widgets/admin_side_navigation.dart';
import 'attendance_detail_widgets.dart';
import '../../services/global_notification_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String filterStatus = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);

    if (authProvider.user != null) {
      await attendanceProvider.fetchUserAttendance(authProvider.user!['_id']);

      // Debug: Print the attendance records to see what we're getting
      print(
          'DEBUG: Attendance records fetched: ${attendanceProvider.attendanceRecords.length}');
      if (attendanceProvider.attendanceRecords.isNotEmpty) {
        print(
            'DEBUG: First attendance record: ${attendanceProvider.attendanceRecords.first}');
      }
    }
  }

  // Helper method to calculate attendance status from backend data
  String _calculateStatus(Map<String, dynamic> attendance) {
    if (attendance['checkOutTime'] != null) {
      return 'completed';
    } else if (attendance['checkInTime'] != null) {
      // Check if currently on break
      final breaks = attendance['breaks'] as List<dynamic>?;
      if (breaks != null && breaks.isNotEmpty) {
        final lastBreak = breaks.last;
        if (lastBreak['end'] == null) {
          return 'on_break';
        }
      }
      return 'clocked_in';
    }
    return 'not_clocked_in';
  }

  // Helper method to format date from backend
  String _formatDate(dynamic dateField) {
    if (dateField == null) return 'N/A';
    try {
      final date = DateTime.parse(dateField.toString());
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  // Helper method to format time from backend
  String _formatTime(dynamic timeField) {
    if (timeField == null) return 'N/A';
    try {
      final time = DateTime.parse(timeField.toString());
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> exportToCSV() async {
    try {
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/attendance_data.csv';

      final csvData = [
        ['Date', 'Status', 'Check In', 'Check Out', 'Total Break Duration'],
        ...attendanceProvider.attendanceRecords.map((item) => [
              _formatDate(item['date']),
              _calculateStatus(item),
              _formatTime(item['checkInTime']),
              _formatTime(item['checkOutTime']),
              '${((item['totalBreakDuration'] ?? 0) / 60000).toStringAsFixed(1)} min',
            ]),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      final file = File(path);
      await file.writeAsString(csvString);

      final notificationService =
          Provider.of<GlobalNotificationService>(context, listen: false);
      notificationService.showSuccess('Attendance data exported to $path');
    } catch (e) {
      final notificationService =
          Provider.of<GlobalNotificationService>(context, listen: false);
      notificationService.showError('Failed to export data: $e');
    }
  }

  Widget _buildInteractiveSummaryCard(
      String title, int count, Color color, String filter) {
    final isSelected = filterStatus == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          filterStatus = filter;
        });
      },
      child: Container(
        width: 100,
        height: 130,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.9) : color.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              offset: Offset(2, 2),
            ),
          ],
          border:
              isSelected ? Border.all(color: Colors.black, width: 2.0) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filter == 'completed'
                  ? Icons.check_circle
                  : filter == 'not_clocked_in'
                      ? Icons.cancel
                      : filter == 'on_break'
                          ? Icons.coffee
                          : Icons.access_time,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              count.toString(),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final attendanceRecords = attendanceProvider.attendanceRecords;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildInteractiveSummaryCard(
              'Total', attendanceRecords.length, Colors.blue, 'All'),
          _buildInteractiveSummaryCard(
              'Completed',
              attendanceRecords
                  .where((item) => _calculateStatus(item) == 'completed')
                  .length,
              Colors.green,
              'completed'),
          _buildInteractiveSummaryCard(
              'Not Clocked In',
              attendanceRecords
                  .where((item) => _calculateStatus(item) == 'not_clocked_in')
                  .length,
              Colors.red,
              'not_clocked_in'),
          _buildInteractiveSummaryCard(
              'On Break',
              attendanceRecords
                  .where((item) => _calculateStatus(item) == 'on_break')
                  .length,
              Colors.orange,
              'on_break'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      // Not logged in, show fallback or redirect
      return Scaffold(
        body: Center(child: Text('Not logged in. Please log in.')),
      );
    }
    final isAdmin = user['role'] == 'admin';
    if (isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance')),
        body: const Center(child: Text('Access denied')),
        drawer: const AdminSideNavigation(currentRoute: '/attendance'),
      );
    }
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final attendanceRecords = attendanceProvider.attendanceRecords;

    // Step 1: Date range filter
    List<dynamic> dateFilteredRecords = attendanceRecords;
    if (_startDate != null && _endDate != null) {
      dateFilteredRecords = attendanceRecords.where((item) {
        if (item['date'] == null) return false;
        final DateTime itemDate;
        try {
          itemDate = DateTime.parse(item['date'].toString());
        } catch (_) {
          return false;
        }
        // Normalize dates to ignore time components for comparison
        final onlyDate = DateTime(itemDate.year, itemDate.month, itemDate.day);
        final startOnly =
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final endOnly =
            DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        return (onlyDate.isAtSameMomentAs(startOnly) ||
                onlyDate.isAfter(startOnly)) &&
            (onlyDate.isAtSameMomentAs(endOnly) || onlyDate.isBefore(endOnly));
      }).toList();
    }

    // Step 2: Status filter
    final filteredData = filterStatus == 'All'
        ? dateFilteredRecords
        : dateFilteredRecords
            .where((item) => _calculateStatus(item) == filterStatus)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // First row: Date Range Picker
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(_startDate != null && _endDate != null
                        ? '${_formatDate(_startDate)} - ${_formatDate(_endDate)}'
                        : 'Select Date Range'),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDateRange: _startDate != null && _endDate != null
                            ? DateTimeRange(start: _startDate!, end: _endDate!)
                            : null,
                      );
                      if (picked != null) {
                        setState(() {
                          _startDate = picked.start;
                          _endDate = picked.end;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Second row: Employee Dropdown, Export
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                // Export Dropdown Button (full-width)
                Expanded(
                  child: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'Export CSV') {
                        await exportToCSV();
                      } else if (value == 'Export PDF') {
                        final notificationService =
                            Provider.of<GlobalNotificationService>(context,
                                listen: false);
                        notificationService
                            .showInfo('PDF export is not yet implemented.');
                      } else if (value == 'Refresh') {
                        await fetchAttendanceData();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'Export CSV', child: Text('Export to CSV')),
                      const PopupMenuItem(
                          value: 'Export PDF', child: Text('Export to PDF')),
                      const PopupMenuItem(
                          value: 'Refresh', child: Text('Refresh List')),
                    ],
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                            () {}, // Non-null so button appears enabled; PopupMenuButton handles tap
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSummarySection(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.view_list),
                label: const Text('View Timesheet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/timesheet');
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredData.isEmpty
                ? const Center(
                    child: Text(
                      'No attendance records available.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredData.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = filteredData[index];
                      final status = _calculateStatus(item);
                      final date = _formatDate(item['date']);
                      final checkIn = _formatTime(item['checkInTime']);
                      final checkOut = _formatTime(item['checkOutTime']);
                      final breakDurationMin =
                          ((item['totalBreakDuration'] ?? 0) / 60000)
                              .toStringAsFixed(1);
                      // Calculate total hours worked
                      String totalHoursWorked = '';
                      if (item['checkInTime'] != null &&
                          item['checkOutTime'] != null) {
                        final checkInDt = DateTime.parse(item['checkInTime']);
                        final checkOutDt = DateTime.parse(item['checkOutTime']);
                        final breakMs = item['totalBreakDuration'] ?? 0;
                        final workMs =
                            checkOutDt.difference(checkInDt).inMilliseconds -
                                breakMs;
                        final workH = workMs ~/ (1000 * 60 * 60);
                        final workM =
                            ((workMs % (1000 * 60 * 60)) / (1000 * 60)).round();
                        totalHoursWorked = '${workH}h ${workM}m';
                      }
                      // Prepare break details
                      final breaks = (item['breaks'] as List<dynamic>? ?? []);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ExpansionTile(
                          leading: Icon(
                            status == 'completed'
                                ? Icons.check_circle_outline
                                : status == 'not_clocked_in'
                                    ? Icons.cancel_outlined
                                    : status == 'on_break'
                                        ? Icons.coffee
                                        : Icons.access_time,
                            color: status == 'completed'
                                ? Colors.green
                                : status == 'not_clocked_in'
                                    ? Colors.red
                                    : status == 'on_break'
                                        ? Colors.orange
                                        : Colors.blue,
                          ),
                          title: Text('Date: $date'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Status: '),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: status == 'completed'
                                          ? Colors.green
                                          : status == 'not_clocked_in'
                                              ? Colors.red
                                              : status == 'on_break'
                                                  ? Colors.orange
                                                  : Colors.blue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status.replaceAll('_', ' ').toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text('Check In: $checkIn'),
                              if (breakDurationMin != '0.0')
                                Text('Break Duration: $breakDurationMin min'),
                            ],
                          ),
                          children: [
                            if (item['checkOutTime'] != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16.0, bottom: 4.0, right: 16.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Check Out: $checkOut'),
                                ),
                              ),
                            if (totalHoursWorked.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16.0, bottom: 4.0, right: 16.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                      'Total Hours Worked: $totalHoursWorked'),
                                ),
                              ),
                            if (breaks.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16.0, bottom: 8.0, right: 16.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Breaks:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      ...breaks.map((b) {
                                        final breakType = b['type'] is Map
                                            ? (b['type']['displayName'] ??
                                                'Break')
                                            : 'Break';
                                        final start = _formatTime(b['start']);
                                        final end = b['end'] != null
                                            ? _formatTime(b['end'])
                                            : 'Ongoing';
                                        final durationMin =
                                            b['duration'] != null
                                                ? (b['duration'] / 60000)
                                                    .toStringAsFixed(1)
                                                : '';
                                        final isLive = b['end'] == null;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              top: 2.0, bottom: 2.0),
                                          child: Row(
                                            children: [
                                              Text(
                                                '- $breakType: $start - $end (${durationMin.isNotEmpty ? '$durationMin min' : 'In progress'})',
                                              ),
                                              if (isLive)
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                      left: 8.0),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.circle,
                                                        color: Colors.red,
                                                        size: 10,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'LIVE',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AttendanceDetailScreen extends StatelessWidget {
  final String date;

  const AttendanceDetailScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    // Mock data for demonstration
    const checkInTime = '9:00 AM';
    const checkOutTime = '5:00 PM';
    const totalHoursWorked = '8 hours';
    const breakDetails = '1 hour';

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Details - $date'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AttendanceDetailCard(
                      icon: Icons.access_time,
                      iconColor: Colors.blue,
                      label: 'Check-In Time',
                      value: checkInTime,
                    ),
                    SizedBox(height: 16),
                    AttendanceDetailCard(
                      icon: Icons.exit_to_app,
                      iconColor: Colors.red,
                      label: 'Check-Out Time',
                      value: checkOutTime,
                    ),
                    SizedBox(height: 16),
                    AttendanceDetailCard(
                      icon: Icons.timer,
                      iconColor: Colors.green,
                      label: 'Total Hours Worked',
                      value: totalHoursWorked,
                    ),
                    SizedBox(height: 16),
                    AttendanceDetailCard(
                      icon: Icons.coffee,
                      iconColor: Colors.orange,
                      label: 'Break Details',
                      value: breakDetails,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
