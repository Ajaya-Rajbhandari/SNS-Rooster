import 'package:flutter/material.dart';
import 'package:sns_rooster/screens/admin/edit_employee_dialog.dart';
import 'package:sns_rooster/services/attendance_service.dart';
import 'package:intl/intl.dart';
import 'package:sns_rooster/providers/employee_provider.dart';
import 'package:provider/provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> employee;
  final EmployeeProvider employeeProvider;

  const EmployeeDetailScreen({
    Key? key,
    required this.employeeProvider,
    required this.employee,
  }) : super(key: key);

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = widget.employee['userId'] ?? widget.employee['_id'];
      if (userId == null) {
        setState(() {
          _error = 'User ID not found for this employee.';
          _isLoading = false;
        });
        return;
      }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final attendanceService = AttendanceService(authProvider);
      final records = await attendanceService.getAttendanceHistory(userId);
      setState(() {
        _attendanceRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to fetch attendance: \${e.toString()}";
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    final dateTime = DateTime.tryParse(dateTimeString)?.toLocal();
    if (dateTime == null) return 'N/A';
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee['name'] ?? 'Employee Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "Name: ${widget.employee['name'] ?? 'N/A'}",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              "Designation: ${widget.employee['position'] ?? 'N/A'}",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              "Email: ${widget.employee['email'] ?? 'N/A'}",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final updatedEmployee = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return EditEmployeeDialog(
                      employee: widget.employee,
                      employeeProvider: widget.employeeProvider,
                    );
                  },
                );
                if (updatedEmployee != null) {
                  print(
                      "Updated Employee from detail screen: \${updatedEmployee['name']}, \${updatedEmployee['position']}");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            "Employee updated: \${updatedEmployee['name']} - \${updatedEmployee['position']}")),
                  );
                }
              },
              child: const Text('Edit Employee Details'),
            ),
            const SizedBox(height: 24),
            Text('Attendance & Break History', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Colors.red)),
            if (!_isLoading && _error == null && _attendanceRecords.isEmpty)
              const Text('No attendance records found.'),
            if (_attendanceRecords.isNotEmpty)
              ..._attendanceRecords.map((record) {
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
                          "Date: \${record['date'] != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(record['date'])) : 'N/A'}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text("Check-in: \${_formatDateTime(record['checkInTime'])}"),
                        Text("Check-out: \${_formatDateTime(record['checkOutTime'])}"),
                        Text("Status: \${record['status'] ?? 'N/A'}"),
                        if (record['breaks'] != null && (record['breaks'] as List).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Breaks:', style: TextStyle(fontWeight: FontWeight.w600)),
                          ...((record['breaks'] as List).map((breakRecord) {
                            final startTime = _formatDateTime(breakRecord['start']);
                            final endTime = breakRecord['end'] != null 
                                ? _formatDateTime(breakRecord['end'])
                                : 'Ongoing';
                            final duration = breakRecord['duration'] != null
                                ? "\${(breakRecord['duration'] / (1000 * 60)).round()} min"
                                : 'N/A';
                            return Padding(
                              padding: const EdgeInsets.only(left: 16.0, bottom: 2.0),
                              child: Text("• $startTime - $endTime ($duration)", style: const TextStyle(fontSize: 12)),
                            );
                          }).toList()),
                          if (record['totalBreakDuration'] != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                              child: Text("Total Break Time: \${(record['totalBreakDuration'] / (1000 * 60)).round()} minutes", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}
