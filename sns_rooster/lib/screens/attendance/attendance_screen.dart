import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sns_rooster/services/attendance_service.dart';
import 'package:sns_rooster/widgets/navigation_drawer.dart';
import 'attendance_detail_widgets.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, String>> attendanceData = [];
  String filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    // Replace with actual service call
    final data = await AttendanceService.getAttendance();
    setState(() {
      attendanceData = data;
    });
  }

  Future<void> exportToCSV() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/attendance_data.csv';

      final csvData = [
        ['Date', 'Status'],
        ...attendanceData.map((item) => [item['date'], item['status']]),
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

  Widget _buildInteractiveSummaryCard(String title, int count, Color color, String filter) {
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
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              offset: Offset(2, 2),
            ),
          ],
          border: isSelected ? Border.all(color: Colors.black, width: 2.0) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filter == 'Present' ? Icons.check_circle : filter == 'Absent' ? Icons.cancel : Icons.list,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildInteractiveSummaryCard('Total', attendanceData.length, Colors.blue, 'All'),
          _buildInteractiveSummaryCard('Present', attendanceData.where((item) => item['status'] == 'Present').length, Colors.green, 'Present'),
          _buildInteractiveSummaryCard('Absent', attendanceData.where((item) => item['status'] == 'Absent').length, Colors.red, 'Absent'),
          _buildInteractiveSummaryCard('Leave', attendanceData.where((item) => item['status'] == 'Leave').length, Colors.orange, 'Leave'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = filterStatus == 'All'
        ? attendanceData
        : attendanceData.where((item) => item['status'] == filterStatus).toList();

    // Calculate summary data
    final totalRecords = attendanceData.length;
    final presentCount = attendanceData.where((item) => item['status'] == 'Present').length;
    final absentCount = attendanceData.where((item) => item['status'] == 'Absent').length;
    final leaveCount = attendanceData.where((item) => item['status'] == 'Leave').length;

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
                // Implement PDF export functionality here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF export is not yet implemented.')),
                );
              } else if (value == 'Refresh') {
                await fetchAttendanceData();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Export CSV', child: Text('Export to CSV')),
              const PopupMenuItem(value: 'Export PDF', child: Text('Export to PDF')),
              const PopupMenuItem(value: 'Refresh', child: Text('Refresh List')),
            ],
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(),
      body: Column(
        children: [
          // Enhanced interactive attendance summary section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSummarySection(),
          ),
          // Attendance list
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
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: Icon(
                            item['status'] == 'Present'
                                ? Icons.check_circle_outline
                                : item['status'] == 'Absent'
                                    ? Icons.cancel_outlined
                                    : Icons.beach_access,
                            color: item['status'] == 'Present'
                                ? Colors.green
                                : item['status'] == 'Absent'
                                    ? Colors.red
                                    : Colors.orange,
                          ),
                          title: Text('Date: ${item['date']}'),
                          subtitle: Text('Status: ${item['status']}'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AttendanceDetailScreen(date: item['date']!),
                              ),
                            );
                          },
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
    final checkInTime = '9:00 AM';
    final checkOutTime = '5:00 PM';
    final totalHoursWorked = '8 hours';
    final breakDetails = '1 hour';

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
