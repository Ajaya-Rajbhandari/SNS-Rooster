import 'package:flutter/material.dart';
import '../../widgets/admin_side_navigation.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  final List<Map<String, dynamic>> _mockEmployees = [
    {'id': '1', 'name': 'John Doe'},
    {'id': '2', 'name': 'Jane Smith'},
    {'id': '3', 'name': 'Bob Johnson'},
  ];
  String? _selectedEmployeeId;

  final List<Map<String, dynamic>> _mockLeaveRequests = [
    {
      'id': 'l1',
      'employeeId': '1',
      'employeeName': 'John Doe',
      'type': 'Sick Leave',
      'from': '2024-06-10',
      'to': '2024-06-12',
      'status': 'Pending',
      'reason': 'Fever and cold',
    },
    {
      'id': 'l2',
      'employeeId': '2',
      'employeeName': 'Jane Smith',
      'type': 'Annual Leave',
      'from': '2024-06-15',
      'to': '2024-06-20',
      'status': 'Pending',
      'reason': 'Family vacation',
    },
    {
      'id': 'l3',
      'employeeId': '3',
      'employeeName': 'Bob Johnson',
      'type': 'Casual Leave',
      'from': '2024-06-18',
      'to': '2024-06-18',
      'status': 'Approved',
      'reason': 'Personal work',
    },
  ];

  void _updateLeaveStatus(String leaveId, String newStatus) {
    setState(() {
      final idx = _mockLeaveRequests.indexWhere((l) => l['id'] == leaveId);
      if (idx != -1) {
        _mockLeaveRequests[idx]['status'] = newStatus;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredRequests = _selectedEmployeeId == null
        ? _mockLeaveRequests
        : _mockLeaveRequests
            .where((l) => l['employeeId'] == _selectedEmployeeId)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      drawer: const AdminSideNavigation(currentRoute: '/leave_management'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Filter by Employee:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedEmployeeId,
                  hint: const Text('All'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ..._mockEmployees.map((emp) => DropdownMenuItem(
                          value: emp['id'],
                          child: Text(emp['name']!),
                        )),
                  ],
                  onChanged: (val) => setState(() => _selectedEmployeeId = val),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredRequests.isEmpty
                  ? Center(
                      child: Text('No leave requests found.',
                          style: theme.textTheme.bodyLarge),
                    )
                  : ListView.builder(
                      itemCount: filteredRequests.length,
                      itemBuilder: (context, idx) {
                        final req = filteredRequests[idx];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person,
                                        color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(req['employeeName'],
                                        style: theme.textTheme.titleMedium),
                                    const Spacer(),
                                    Chip(
                                      label: Text(req['status'],
                                          style: const TextStyle(
                                              color: Colors.white)),
                                      backgroundColor:
                                          req['status'] == 'Pending'
                                              ? Colors.orange
                                              : req['status'] == 'Approved'
                                                  ? Colors.green
                                                  : Colors.red,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    '${req['type']} | ${req['from']} to ${req['to']}',
                                    style: theme.textTheme.bodyMedium),
                                const SizedBox(height: 8),
                                Text('Reason: ${req['reason']}',
                                    style: theme.textTheme.bodySmall),
                                const SizedBox(height: 12),
                                if (req['status'] == 'Pending')
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _updateLeaveStatus(
                                            req['id'], 'Approved'),
                                        icon: const Icon(Icons.check),
                                        label: const Text('Approve'),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        onPressed: () => _updateLeaveStatus(
                                            req['id'], 'Rejected'),
                                        icon: const Icon(Icons.close),
                                        label: const Text('Reject'),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
