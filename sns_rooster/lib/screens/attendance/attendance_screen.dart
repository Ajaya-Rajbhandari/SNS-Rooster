import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sns_rooster/providers/attendance_provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import 'package:sns_rooster/widgets/app_drawer.dart';
import 'package:sns_rooster/widgets/admin_side_navigation.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String filterStatus = 'All';

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
    }
  }

  String _calculateStatus(Map<String, dynamic> attendance) {
    if (attendance['checkOutTime'] != null) {
      return 'completed';
    } else if (attendance['checkInTime'] != null) {
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

  String _formatDate(dynamic dateField) {
    if (dateField == null) return 'N/A';
    try {
      final date = DateTime.parse(dateField.toString());
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTime(dynamic timeField) {
    if (timeField == null) return 'N/A';
    if (timeField is String &&
        timeField.contains(':') &&
        !timeField.contains('T')) {
      return timeField;
    }
    try {
      final time = DateTime.parse(timeField.toString());
      final localTime = time.toLocal();
      return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildSummaryCard(
      String title, int count, Color color, String statusKey, IconData icon) {
    final isSelected = filterStatus == statusKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          filterStatus = statusKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        height: 110,
        margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.9)
              : color.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 8.0,
              offset: const Offset(2, 4),
            ),
          ],
          border:
              isSelected ? Border.all(color: Colors.black, width: 2.0) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        break;
      case 'on_break':
        color = Colors.orange;
        label = 'On Break';
        break;
      case 'clocked_in':
        color = Colors.blue;
        label = 'Clocked In';
        break;
      default:
        color = Colors.red;
        label = 'Not Clocked In';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in. Please log in.')),
      );
    }
    final isAdmin = user['role'] == 'admin';
    if (isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Attendance'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
        ),
        body: const Center(child: Text('Access denied')),
        drawer: const AdminSideNavigation(currentRoute: '/attendance'),
      );
    }
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final attendanceRecords = attendanceProvider.attendanceRecords;

    // Filtered data
    List<dynamic> filteredData = attendanceRecords;
    if (filterStatus != 'All') {
      filteredData = attendanceRecords
          .where((item) => _calculateStatus(item) == filterStatus)
          .toList();
    }

    // Stats
    final total = attendanceRecords.length;
    final completed = attendanceRecords
        .where((item) => _calculateStatus(item) == 'completed')
        .length;
    final onBreak = attendanceRecords
        .where((item) => _calculateStatus(item) == 'on_break')
        .length;
    final notClockedIn = attendanceRecords
        .where((item) => _calculateStatus(item) == 'not_clocked_in')
        .length;
    final clockedIn = attendanceRecords
        .where((item) => _calculateStatus(item) == 'clocked_in')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                children: [
                  _buildSummaryCard(
                      'Total', total, Colors.blue, 'All', Icons.all_inclusive),
                  _buildSummaryCard('Completed', completed, Colors.green,
                      'completed', Icons.check_circle),
                  _buildSummaryCard('On Break', onBreak, Colors.orange,
                      'on_break', Icons.coffee),
                  _buildSummaryCard('Clocked In', clockedIn, Colors.blue,
                      'clocked_in', Icons.access_time),
                  _buildSummaryCard('Not Clocked In', notClockedIn, Colors.red,
                      'not_clocked_in', Icons.cancel),
                ],
              ),
            ),
            // Date Range Picker
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
                    ),
                  ),
                ],
              ),
            ),
            // Export Button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Exported as CSV (simulated).')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // View Timesheet Button
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
            filteredData.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No attendance records available.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your attendance records will appear here.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
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
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Date: $date',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  _buildStatusBadge(status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.login,
                                      size: 18, color: Colors.blueGrey),
                                  const SizedBox(width: 4),
                                  Text('Check In: $checkIn'),
                                  if (checkOut != 'N/A') ...[
                                    const SizedBox(width: 16),
                                    const Icon(Icons.logout,
                                        size: 18, color: Colors.blueGrey),
                                    const SizedBox(width: 4),
                                    Text('Check Out: $checkOut'),
                                  ],
                                ],
                              ),
                              if (breakDurationMin != '0.0')
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.timer,
                                          size: 18, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text('Break: $breakDurationMin min'),
                                    ],
                                  ),
                                ),
                              if (totalHoursWorked.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          size: 18, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text('Worked: $totalHoursWorked'),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
