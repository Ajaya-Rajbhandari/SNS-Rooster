import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_request_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/leave_request_modal.dart';
import 'package:sns_rooster/widgets/app_drawer.dart';
import 'package:table_calendar/table_calendar.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedLeaveType = 'Annual Leave';
  bool _isLoading = false;

  // Calendar state variables
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final List<String> _leaveTypes = [
    'Annual Leave',
    'Sick Leave',
    'Casual Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Unpaid Leave',
  ];

  @override
  void initState() {
    super.initState();
    _loadLeaveRequests();
    _loadLeaveBalances();
    _selectedDay = _focusedDay; // Initialize selectedDay
  }

  Future<void> _loadLeaveRequests() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final leaveProvider =
        Provider.of<LeaveRequestProvider>(context, listen: false);

    if (authProvider.user?['_id'] != null) {
      await leaveProvider.getUserLeaveRequests(authProvider.user!['_id']);
    }
  }

  Future<void> _loadLeaveBalances() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final leaveProvider =
        Provider.of<LeaveRequestProvider>(context, listen: false);

    if (authProvider.user?['_id'] != null) {
      await leaveProvider.fetchLeaveBalances(authProvider.user!['_id']);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end dates')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final leaveProvider =
          Provider.of<LeaveRequestProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      print('DEBUG: profileProvider.profile = ' + profileProvider.profile.toString());
      print('DEBUG: authProvider.user = ' + authProvider.user.toString());
      // Always fetch the Employee document for the current user
      final userId = authProvider.user?['_id'];
      String? employeeId;
      if (userId != null) {
        final fetchedEmployeeId = await leaveProvider.fetchEmployeeIdByUserId(userId);
        if (fetchedEmployeeId != null) {
          employeeId = fetchedEmployeeId;
        }
      }
      if (employeeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee record not found. Please contact admin.')),
        );
        setState(() => _isLoading = false);
        return;
      }
      final success = await leaveProvider.createLeaveRequest({
        'employee': employeeId, // Use Employee document _id
        'employeeName': authProvider.user?['name'] ?? 'Unknown',
        'leaveType': _selectedLeaveType,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'reason': _reasonController.text,
        'status': 'Pending',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'approverId': null,
        'comments': '',
      });

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request submitted successfully')),
        );
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  leaveProvider.error ?? 'Failed to submit leave request')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _reasonController.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedLeaveType = 'Annual Leave';
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leaveProvider = Provider.of<LeaveRequestProvider>(context);

    final annualLeave = leaveProvider.leaveBalances['annual'] ?? {};
    final sickLeave = leaveProvider.leaveBalances['sick'] ?? {};
    final casualLeave = leaveProvider.leaveBalances['casual'] ?? {};

    // Function to get events for a given day
    List<dynamic> getEventsForDay(DateTime day) {
      return leaveProvider.leaveRequests.where((request) {
        final startDate = DateTime.parse(request['startDate']);
        final endDate = DateTime.parse(request['endDate']);
        // Normalize dates to compare only year, month, and day
        final normalizedDay = DateTime(day.year, day.month, day.day);
        final normalizedStartDate =
            DateTime(startDate.year, startDate.month, startDate.day);
        final normalizedEndDate =
            DateTime(endDate.year, endDate.month, endDate.day);

        return (normalizedDay.isAfter(
                normalizedStartDate.subtract(const Duration(days: 1))) &&
            normalizedDay
                .isBefore(normalizedEndDate.add(const Duration(days: 1))));
      }).toList();
    }

    void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
      if (!isSameDay(_selectedDay, selectedDay)) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Request'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final reasonController = TextEditingController();
          showDialog(
            context: context,
            builder: (context) => LeaveRequestModal(
              reasonController: reasonController,
              onSubmit: (fromDate, toDate, leaveType, reason) {
                // Handle leave request submission
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Leave request submitted successfully!'),
                  ),
                );
                reasonController.dispose();
              },
            ),
          );
        },
        tooltip: 'New Leave Request',
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leave Balance Summary
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leave Balance',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLeaveBalanceItem(
                          'Annual Leave',
                          annualLeave['total']?.toString() ?? '-',
                          annualLeave['used']?.toString() ?? '-',
                          theme.colorScheme.primary,
                        ),
                        _buildLeaveBalanceItem(
                          'Sick Leave',
                          sickLeave['total']?.toString() ?? '-',
                          sickLeave['used']?.toString() ?? '-',
                          theme.colorScheme.secondary,
                        ),
                        _buildLeaveBalanceItem(
                          'Casual Leave',
                          casualLeave['total']?.toString() ?? '-',
                          casualLeave['used']?.toString() ?? '-',
                          theme.colorScheme.tertiary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Leave Calendar
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leave Calendar',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: onDaySelected,
                      eventLoader: getEventsForDay,
                      calendarFormat: CalendarFormat.month,
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // New Leave Request Form
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Leave Request',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedLeaveType,
                        decoration: InputDecoration(
                          labelText: 'Leave Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _leaveTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedLeaveType = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              controller: TextEditingController(
                                text: _startDate != null
                                    ? DateFormat('yyyy-MM-dd')
                                        .format(_startDate!)
                                    : '',
                              ),
                              onTap: () => _selectDate(context, true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'End Date',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              controller: TextEditingController(
                                text: _endDate != null
                                    ? DateFormat('yyyy-MM-dd').format(_endDate!)
                                    : '',
                              ),
                              onTap: () => _selectDate(context, false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reasonController,
                        decoration: InputDecoration(
                          labelText: 'Reason',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a reason';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitLeaveRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Submit Request'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Leave Requests
            Text(
              'Recent Leave Requests',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (leaveProvider.leaveRequests.isEmpty)
              Center(
                child: Text(
                  'No leave requests found',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leaveProvider.leaveRequests.length,
                itemBuilder: (context, index) {
                  final request = leaveProvider.leaveRequests[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(request['leaveType'] ?? 'N/A'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormat('yyyy-MM-dd').format(DateTime.parse(request['startDate']))} - ${DateFormat('yyyy-MM-dd').format(DateTime.parse(request['endDate']))}',
                          ),
                          Text(request['reason'] ?? 'No reason provided'),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          request['status'] ?? 'Pending',
                          style: TextStyle(
                            color: _getStatusColor(request['status']),
                          ),
                        ),
                        backgroundColor:
                            _getStatusColor(request['status']).withOpacity(0.1),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveBalanceItem(
    String type,
    String total,
    String remaining,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          type,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          remaining,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'of $total',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
