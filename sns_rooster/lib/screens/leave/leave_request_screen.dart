// Placeholder for leave request screen
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sns_rooster/models/leave_request.dart';
import 'package:sns_rooster/widgets/navigation_drawer.dart';
import 'package:sns_rooster/widgets/leave_request_modal.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  DateTime? fromDate;
  DateTime? toDate;
  String? leaveType;
  final TextEditingController reasonController = TextEditingController();

  bool isFromDateError = false;
  bool isToDateError = false;
  bool isLeaveTypeError = false;
  bool isReasonError = false;

  String selectedFilter = 'Total';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mock data for leave requests
    final leaveRequests = [
      LeaveRequest(
        fromDate: DateTime(2025, 6, 10),
        toDate: DateTime(2025, 6, 12),
        leaveType: 'Annual',
        reason: 'Vacation',
        status: 'Approved',
      ),
      LeaveRequest(
        fromDate: DateTime(2025, 6, 15),
        toDate: DateTime(2025, 6, 16),
        leaveType: 'Sick',
        reason: 'Medical checkup',
        status: 'Pending',
      ),
      LeaveRequest(
        fromDate: DateTime(2025, 6, 20),
        toDate: DateTime(2025, 6, 21),
        leaveType: 'Casual',
        reason: 'Family event',
        status: 'Rejected',
      ),
    ];

    final approvedCount = leaveRequests.where((req) => req.status == 'Approved').length;
    final pendingCount = leaveRequests.where((req) => req.status == 'Pending').length;
    final rejectedCount = leaveRequests.where((req) => req.status == 'Rejected').length;

    final filteredRequests = selectedFilter == 'Total'
        ? leaveRequests
        : leaveRequests.where((req) => req.status == selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Requests'),
        backgroundColor: theme.primaryColor,
      ),
      drawer: const AppNavigationDrawer(),
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    spacing: 16.0,
                    runSpacing: 16.0,
                    alignment: WrapAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => selectedFilter = 'Total'),
                        child: _buildSummaryTile('Total', '${leaveRequests.length}', Colors.blue),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => selectedFilter = 'Approved'),
                        child: _buildSummaryTile('Approved', '$approvedCount', Colors.green),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => selectedFilter = 'Pending'),
                        child: _buildSummaryTile('Pending', '$pendingCount', Colors.orange),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => selectedFilter = 'Rejected'),
                        child: _buildSummaryTile('Rejected', '$rejectedCount', Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) {
                final request = filteredRequests[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: request.status == 'Approved'
                          ? Colors.green
                          : request.status == 'Pending'
                              ? Colors.orange
                              : Colors.red,
                      child: Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      'Leave Date: ${DateFormat('yyyy-MM-dd').format(request.fromDate)} - ${DateFormat('yyyy-MM-dd').format(request.toDate)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Status: ${request.status}',
                      style: TextStyle(
                        color: request.status == 'Approved'
                            ? Colors.green
                            : request.status == 'Pending'
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    onTap: () {
                      // Navigate to detailed leave request view
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return LeaveRequestModal(
                reasonController: reasonController,
                onSubmit: (fromDate, toDate, leaveType, reason) {
                  // Add logic to save the leave request
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Leave request submitted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                disablePastDates: true, // Added to disable past dates in the modal
              );
            },
          );
        },
        backgroundColor: theme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  Widget _buildSummaryTile(String label, String value, Color color) {
    return Flexible(
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 25,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
