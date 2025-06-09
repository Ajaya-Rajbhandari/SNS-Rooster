import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sns_rooster/providers/attendance_provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import 'package:sns_rooster/widgets/navigation_drawer.dart';
import 'attendance_detail_widgets.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
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

  Future<void> exportToCSV() async {
    try {
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/attendance_data.csv';

      final csvData = [
        ['Date', 'Status', 'Check In', 'Check Out', 'Notes'],
        ...attendanceProvider.attendanceRecords.map((item) => [
              item['createdAt']?.toString().split('T')[0] ?? '',
              item['status']?.toString() ?? '',
              item['checkIn']?.toString() ?? '',
              item['checkOut']?.toString() ?? '',
              item['notes']?.toString() ?? '',
            ]),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      final file = File(path);
      await file.writeAsString(csvString);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance data exported to $path')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export data: $e')),
      );
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
        height: 120,
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
              filter == 'present'
                  ? Icons.check_circle
                  : filter == 'absent'
                      ? Icons.cancel
                      : Icons.list,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 4),
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
              'Present',
              attendanceRecords
                  .where((item) => item['status'] == 'present')
                  .length,
              Colors.green,
              'present'),
          _buildInteractiveSummaryCard(
              'Absent',
              attendanceRecords
                  .where((item) => item['status'] == 'absent')
                  .length,
              Colors.red,
              'absent'),
          _buildInteractiveSummaryCard(
              'Late',
              attendanceRecords
                  .where((item) => item['status'] == 'late')
                  .length,
              Colors.orange,
              'late'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final attendanceRecords = attendanceProvider.attendanceRecords;

    final filteredData = filterStatus == 'All'
        ? attendanceRecords
        : attendanceRecords
            .where((item) => item['status'] == filterStatus)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'Export CSV') {
                await exportToCSV();
              } else if (value == 'Export PDF') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('PDF export is not yet implemented.')),
                );
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
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(),
      body: Column(
        children: [
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
                      final date = item['createdAt'] != null
                          ? DateTime.parse(item['createdAt']).toLocal()
                          : null;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: Icon(
                            item['status'] == 'present'
                                ? Icons.check_circle_outline
                                : item['status'] == 'absent'
                                    ? Icons.cancel_outlined
                                    : item['status'] == 'late'
                                        ? Icons.access_time
                                        : Icons.info_outline,
                            color: item['status'] == 'present'
                                ? Colors.green
                                : item['status'] == 'absent'
                                    ? Colors.red
                                    : item['status'] == 'late'
                                        ? Colors.orange
                                        : Colors.blueGrey,
                          ),
                          title: Text(date != null
                              ? 'Date: ${date.toString().split(' ')[0]}'
                              : 'Date: N/A'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: ${item['status']}'),
                              if (item['checkIn'] != null)
                                Text(
                                    'Check In: ${DateTime.parse(item['checkIn']).toLocal().toString().split(' ')[1]}'),
                              if (item['checkOut'] != null)
                                Text(
                                    'Check Out: ${DateTime.parse(item['checkOut']).toLocal().toString().split(' ')[1]}'),
                              if (item['notes'] != null &&
                                  item['notes'].toString().isNotEmpty)
                                Text('Notes: ${item['notes']}'),
                            ],
                          ),
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AttendanceDetailCard(
                      icon: Icons.access_time,
                      iconColor: Colors.blue,
                      label: 'Check-In Time',
                      value: checkInTime,
                    ),
                    const SizedBox(height: 16),
                    AttendanceDetailCard(
                      icon: Icons.exit_to_app,
                      iconColor: Colors.red,
                      label: 'Check-Out Time',
                      value: checkOutTime,
                    ),
                    const SizedBox(height: 16),
                    AttendanceDetailCard(
                      icon: Icons.timer,
                      iconColor: Colors.green,
                      label: 'Total Hours Worked',
                      value: totalHoursWorked,
                    ),
                    const SizedBox(height: 16),
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
