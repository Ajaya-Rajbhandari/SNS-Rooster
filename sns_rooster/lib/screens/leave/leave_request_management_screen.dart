import 'package:flutter/material.dart';
import 'package:sns_rooster/models/leave_request.dart';

class LeaveRequestManagementScreen extends StatefulWidget {
  const LeaveRequestManagementScreen({super.key});

  @override
  State<LeaveRequestManagementScreen> createState() =>
      _LeaveRequestManagementScreenState();
}

class _LeaveRequestManagementScreenState
    extends State<LeaveRequestManagementScreen> {
  final List<LeaveRequest> _leaveRequests = [
    LeaveRequest(
      id: '1',
      employeeName: 'Alice Smith',
      leaveType: 'Annual Leave',
      startDate: '2024-07-01',
      endDate: '2024-07-05',
      reason: 'Family vacation',
      status: 'Pending',
    ),
    LeaveRequest(
      id: '2',
      employeeName: 'Bob Johnson',
      leaveType: 'Sick Leave',
      startDate: '2024-07-10',
      endDate: '2024-07-10',
      reason: 'Fever',
      status: 'Approved',
    ),
    LeaveRequest(
      id: '3',
      employeeName: 'Charlie Brown',
      leaveType: 'Casual Leave',
      startDate: '2024-07-15',
      endDate: '2024-07-16',
      reason: 'Personal errands',
      status: 'Rejected',
    ),
  ];

  void _updateLeaveRequestStatus(String id, String newStatus) {
    setState(() {
      final index = _leaveRequests.indexWhere((request) => request.id == id);
      if (index != -1) {
        _leaveRequests[index].status = newStatus;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Request Management'),
      ),
      body: ListView.builder(
        itemCount: _leaveRequests.length,
        itemBuilder: (context, index) {
          final request = _leaveRequests[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Employee: ${request.employeeName}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Type: ${request.leaveType}'),
                  Text('Dates: ${request.startDate} - ${request.endDate}'),
                  Text('Reason: ${request.reason}'),
                  Text('Status: ${request.status}',
                      style: TextStyle(color: _getStatusColor(request.status))),
                  if (request.status == 'Pending')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () =>
                              _updateLeaveRequestStatus(request.id, 'Approved'),
                          child: const Text('Approve'),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: () =>
                              _updateLeaveRequestStatus(request.id, 'Rejected'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }
}
