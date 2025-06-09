import 'package:flutter/material.dart';
import 'package:sns_rooster/config/leave_config.dart';
import '../../widgets/navigation_drawer.dart';
import 'package:provider/provider.dart';
import '../../providers/leave_request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/leave_request.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  String? _selectedLeaveType;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveProvider = Provider.of<LeaveRequestProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Request'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      drawer: const AppNavigationDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildLeaveSummarySection(context),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  if (authProvider.user != null &&
                      authProvider.user!['_id'] != null) {
                    _showLeaveRequestForm(
                        context,
                        leaveProvider,
                        authProvider,
                        authProvider.user!['_id']
                            .toString()); // Ensure '_id' is a String
                  } else {
                    // Handle the case where user or user ID is null (e.g., show a message)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'User not authenticated or user ID is missing.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'New Leave Request',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Your Leave History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 15),
            if (leaveProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (leaveProvider.error != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${leaveProvider.error}',
                    style: TextStyle(color: Colors.red)),
              )
            else if (leaveProvider.leaveRequests.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No leave requests found.'),
              )
            else
              ...leaveProvider.leaveRequests.map((leave) {
                IconData iconData;
                Color statusColor;
                switch (leave['leaveType']?.toString().toLowerCase()) {
                  case 'annual leave':
                    iconData = Icons.beach_access;
                    break;
                  case 'sick leave':
                    iconData = Icons.medical_services;
                    break;
                  case 'casual leave':
                    iconData = Icons.event;
                    break;
                  case 'maternity leave':
                    iconData = Icons.pregnant_woman;
                    break;
                  case 'paternity leave':
                    iconData = Icons.family_restroom;
                    break;
                  default:
                    iconData = Icons.event;
                }

                switch (leave['status']?.toString().toLowerCase()) {
                  case 'pending':
                    statusColor = Colors.orange;
                    break;
                  case 'approved':
                    statusColor = Colors.green;
                    break;
                  case 'rejected':
                    statusColor = Colors.red;
                    break;
                  default:
                    statusColor = Colors.grey;
                }

                final createdAtStr = leave['createdAt'] != null
                    ? DateTime.tryParse(leave['createdAt'])
                        ?.toLocal()
                        .toString()
                        .split('.')[0]
                    : 'N/A';
                final approver = leave['approverId'] ?? 'N/A';
                final comments = leave['comments'] ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeaveHistoryItem(
                      icon: iconData,
                      leaveType:
                          leave['leaveType']?.toString() ?? 'Unspecified',
                      dates:
                          '${leave['startDate']?.toString() ?? ''} - ${leave['endDate']?.toString() ?? ''}',
                      status: leave['status']?.toString() ?? 'Unknown',
                      statusColor: statusColor,
                      showEdit: (leave['status']?.toString().toLowerCase() ??
                              'pending') ==
                          'pending',
                      showCancel: (leave['status']?.toString().toLowerCase() ??
                              'pending') ==
                          'pending',
                      showView: (leave['status']?.toString().toLowerCase() ??
                              'pending') !=
                          'pending',
                      onEdit: () async {
                        final leaveId = leave['_id']?.toString() ?? 'N/A';
                        final newReason = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            final controller =
                                TextEditingController(text: leave['reason']);
                            return AlertDialog(
                              title: Text('Edit Leave Reason'),
                              content: TextField(
                                controller: controller,
                                decoration:
                                    InputDecoration(labelText: 'Reason'),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, controller.text),
                                  child: Text('Save'),
                                ),
                              ],
                            );
                          },
                        );
                        if (newReason != null && newReason != leave['reason']) {
                          await leaveProvider.updateLeaveRequest(
                              leaveId, {'reason': newReason});
                          await leaveProvider
                              .getUserLeaveRequests(authProvider.user!['_id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Leave request updated!')),
                          );
                        }
                      },
                      onCancel: () async {
                        final leaveId = leave['_id']?.toString() ?? 'N/A';
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Cancel Leave Request'),
                            content: Text(
                                'Are you sure you want to cancel this leave request?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text('No')),
                              ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Yes')),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await leaveProvider.deleteLeaveRequest(leaveId);
                          await leaveProvider
                              .getUserLeaveRequests(authProvider.user!['_id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Leave request deleted!')),
                          );
                        }
                      },
                      onView: () {
                        final leaveId = leave['_id']?.toString() ?? 'N/A';
                        print('View leave request: $leaveId');
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4.0),
                      child: Text('Created At: $createdAtStr'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4.0),
                      child: Text('Approver ID: $approver'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4.0),
                      child: Text('Comments: $comments'),
                    ),
                    const Divider(),
                  ],
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveSummarySection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submit and track your Leave Applications.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildLeaveSummaryCard(
                context,
                'Annual',
                LeaveConfig.totalLeaveDays['Annual']!,
                LeaveConfig.usedLeaveDays['Annual']!,
                Icons.beach_access,
                Colors.blue[700]!,
              ),
              const SizedBox(width: 10),
              _buildLeaveSummaryCard(
                context,
                'Sick',
                LeaveConfig.totalLeaveDays['Sick']!,
                LeaveConfig.usedLeaveDays['Sick']!,
                Icons.medical_services,
                Colors.blue[700]!,
              ),
              const SizedBox(width: 10),
              _buildLeaveSummaryCard(
                context,
                'Casual',
                LeaveConfig.totalLeaveDays['Casual']!,
                LeaveConfig.usedLeaveDays['Casual']!,
                Icons.event,
                Colors.blue[800]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveSummaryCard(
    BuildContext context,
    String title,
    int totalDays,
    int usedDays,
    IconData icon,
    Color color,
  ) {
    int remainingDays = totalDays - usedDays;
    double progress = usedDays / totalDays;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _showLeaveDetailsDialog(
            context,
            title,
            totalDays,
            usedDays,
            remainingDays,
          );
        },
        child: Card(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.amber, size: 30),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$totalDays Days',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.5),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
                const SizedBox(height: 5),
                Text(
                  '${(remainingDays / totalDays * 100).toStringAsFixed(0)}% remaining',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLeaveDetailsDialog(
    BuildContext context,
    String title,
    int totalDays,
    int usedDays,
    int remainingDays,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$title Leave Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Days: $totalDays'),
              Text('Used Days: $usedDays'),
              Text('Remaining Days: $remainingDays'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLeaveRequestForm(
      BuildContext context,
      LeaveRequestProvider leaveProvider,
      AuthProvider authProvider, // Add AuthProvider here
      String userId) {
    _selectedLeaveType = null;
    _startDateController.clear();
    _endDateController.clear();
    _reasonController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Leave Request',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedLeaveType,
                      decoration: InputDecoration(
                        labelText: 'Leave Type',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      items: LeaveConfig.leaveTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        _selectedLeaveType = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a leave type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _startDateController,
                      readOnly: true,
                      onTap: () => _selectDate(context, _startDateController),
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a start date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _endDateController,
                      readOnly: true,
                      onTap: () => _selectDate(context, _endDateController),
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an end date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Reason',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.edit_note),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a reason';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: leaveProvider.isLoading
                            ? null
                            : () async {
                                print('Form validation started');
                                if (_formKey.currentState!.validate()) {
                                  print(
                                      'Form is valid, preparing request data');
                                  final nowIso =
                                      DateTime.now().toIso8601String();
                                  final newRequest = {
                                    'userId':
                                        userId.toString(), // Ensure string type
                                    'employeeName':
                                        authProvider.user?['name'] ??
                                            'Unknown', // Use authProvider here
                                    'leaveType': _selectedLeaveType!,
                                    'startDate': _startDateController.text,
                                    'endDate': _endDateController.text,
                                    'reason': _reasonController.text,
                                    'status': 'Pending',
                                    'createdAt': nowIso,
                                    'updatedAt': nowIso,
                                    'approverId': null,
                                    'comments': '',
                                  };
                                  print(
                                      'Submitting leave request with data: $newRequest');

                                  final success = await leaveProvider
                                      .createLeaveRequest(newRequest);
                                  print(
                                      'Leave request submission result: $success');

                                  if (success) {
                                    print(
                                        'Leave request submitted successfully');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Leave request submitted successfully!')),
                                    );
                                    Navigator.pop(context);
                                    print('Refreshing leave requests list');
                                    await leaveProvider
                                        .getUserLeaveRequests(userId);
                                  } else {
                                    print(
                                        'Failed to submit leave request: ${leaveProvider.error}');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Failed to submit leave request: ${leaveProvider.error}')),
                                    );
                                  }
                                } else {
                                  print('Form validation failed');
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: leaveProvider.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Submit Request',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaveHistoryItem({
    required IconData icon,
    required String leaveType,
    required String dates,
    required String status,
    required Color statusColor,
    bool showEdit = false,
    bool showCancel = false,
    bool showView = false,
    VoidCallback? onEdit,
    VoidCallback? onCancel,
    VoidCallback? onView,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leaveType,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dates,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            if (showEdit)
              Tooltip(
                message: showEdit ? 'Edit' : 'Can only edit pending requests',
                child: IconButton(
                  icon: Icon(Icons.edit,
                      color: showEdit ? Colors.blue[600] : Colors.grey),
                  onPressed: showEdit ? onEdit : null,
                ),
              ),
            if (showCancel)
              Tooltip(
                message:
                    showCancel ? 'Cancel' : 'Can only cancel pending requests',
                child: IconButton(
                  icon: Icon(Icons.close,
                      color: showCancel ? Colors.red[600] : Colors.grey),
                  onPressed: showCancel ? onCancel : null,
                ),
              ),
            if (showView)
              IconButton(
                icon: Icon(Icons.visibility, color: Colors.grey[600]),
                onPressed: onView,
              ),
          ],
        ),
      ),
    );
  }
}
