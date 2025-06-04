import 'package:flutter/material.dart';
import 'package:sns_rooster/config/leave_config.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class LeaveRequest {
  final String leaveType;
  final String startDate;
  final String endDate;
  final String reason;
  String status;

  LeaveRequest({
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = 'Pending',
  });
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  String? _selectedLeaveType;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  final List<LeaveRequest> _leaveHistory = [];

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Request'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildLeaveSummarySection(context),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  _showLeaveRequestForm(context);
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
            // Display leave history from the _leaveHistory list
            ..._leaveHistory.map((leave) {
              IconData iconData;
              Color statusColor;
              switch (leave.leaveType) {
                case 'Annual Leave':
                  iconData = Icons.beach_access;
                  break;
                case 'Sick Leave':
                  iconData = Icons.medical_services;
                  break;
                case 'Casual Leave':
                  iconData = Icons.event;
                  break;
                case 'Maternity Leave':
                  iconData = Icons.pregnant_woman;
                  break;
                case 'Paternity Leave':
                  iconData = Icons.family_restroom;
                  break;
                default:
                  iconData = Icons.event;
              }

              switch (leave.status) {
                case 'Pending':
                  statusColor = Colors.orange;
                  break;
                case 'Approved':
                  statusColor = Colors.green;
                  break;
                case 'Rejected':
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.grey;
              }

              return _buildLeaveHistoryItem(
                icon: iconData,
                leaveType: leave.leaveType,
                dates: '${leave.startDate} - ${leave.endDate}',
                status: leave.status,
                statusColor: statusColor,
                showEdit: leave.status == 'Pending',
                showCancel: leave.status == 'Pending',
                showView: leave.status != 'Pending',
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

  void _showLeaveRequestForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submit a New Leave Request',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDropdownField(
                    'Leave Type',
                    _selectedLeaveType,
                    [
                      'Annual Leave',
                      'Sick Leave',
                      'Casual Leave',
                      'Maternity Leave',
                      'Paternity Leave',
                    ],
                    (String? newValue) {
                      setState(() {
                        _selectedLeaveType = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildDateField('Start Date', _startDateController, context),
                  const SizedBox(height: 15),
                  _buildDateField('End Date', _endDateController, context),
                  const SizedBox(height: 15),
                  _buildInputField('Reason', _reasonController, maxLines: 4),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedLeaveType != null &&
                            _startDateController.text.isNotEmpty &&
                            _endDateController.text.isNotEmpty &&
                            _reasonController.text.isNotEmpty) {
                          setState(() {
                            _leaveHistory.add(
                              LeaveRequest(
                                leaveType: _selectedLeaveType!,
                                startDate: _startDateController.text,
                                endDate: _endDateController.text,
                                reason: _reasonController.text,
                              ),
                            );
                          });
                          Navigator.pop(context); // Close the bottom sheet
                        } else {
                          // Show an error or a toast message if fields are not filled
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all fields'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Submit Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
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
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue[600]),
                onPressed: () {},
              ),
            if (showCancel)
              IconButton(
                icon: Icon(Icons.close, color: Colors.red[600]),
                onPressed: () {},
              ),
            if (showView)
              IconButton(
                icon: Icon(Icons.visibility, color: Colors.grey[600]),
                onPressed: () {},
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    TextEditingController controller,
    BuildContext context,
  ) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDate(context, controller),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[100],
        suffixIcon: const Icon(Icons.calendar_today),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      items: items.map<DropdownMenuItem<String>>((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
