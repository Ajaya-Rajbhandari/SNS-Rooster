import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/attendance.dart';
import '../../widgets/admin_side_navigation.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({super.key});

  @override
  State<AttendanceManagementScreen> createState() =>
      _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState
    extends State<AttendanceManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch all attendance records when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceProvider>(context, listen: false)
          .fetchAllAttendance();
    });
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    final dateTime = DateTime.parse(dateTimeString).toLocal();
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      drawer: const AdminSideNavigation(currentRoute: '/attendance_management'),
      body: Consumer<AttendanceProvider>(
        builder: (context, attendanceProvider, child) {
          if (attendanceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (attendanceProvider.error != null) {
            return Center(
              child: Text(
                'Error: ${attendanceProvider.error}',
                style: TextStyle(color: colorScheme.error),
              ),
            );
          } else if (attendanceProvider.attendanceRecords.isEmpty) {
            return Center(
              child: Text(
                'No attendance records found.',
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
              ),
            );
          } else {
            return RefreshIndicator(
              onRefresh: () => attendanceProvider.fetchAllAttendance(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: attendanceProvider.attendanceRecords.length,
                itemBuilder: (context, index) {
                  final record = attendanceProvider.attendanceRecords[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Employee: ${record['user']['name'] ?? 'N/A'} (ID: ${record['user']['_id'] ?? 'N/A'})',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(record['date']))}',
                            style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.8)),
                          ),
                          Text(
                            'Check-in: ${_formatDateTime(record['checkInTime'])}',
                            style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.8)),
                          ),
                          Text(
                            'Check-out: ${_formatDateTime(record['checkOutTime'])}',
                            style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.8)),
                          ),
                          Text(
                            'Status: ${record['status'] ?? 'N/A'}',
                            style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.8)),
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
      ),
    );
  }
}
