import 'package:flutter/material.dart';
import 'package:sns_rooster/utils/logger.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_request_provider.dart';
import '../../providers/profile_provider.dart';
import 'package:sns_rooster/widgets/app_drawer.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/global_notification_service.dart';
import '../../widgets/modern_card_widget.dart';

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
  bool _isHalfDay = false; // Add half-day option

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

  String? _employeeId;

  // Add for PageView
  final PageController _balancePageController = PageController();
  int _currentBalancePage = 0;

  final Map<String, Color> leaveTypeColors = {
    'Annual Leave': Colors.blue,
    'Sick Leave': Colors.red,
    'Casual Leave': Colors.orange,
    'Maternity Leave': Colors.pinkAccent,
    'Paternity Leave': Colors.blueAccent,
    'Unpaid Leave': Colors.grey,
  };

  bool _notificationCleared = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEmployeeAndLeaveRequests();
    });
    _selectedDay = _focusedDay; // Initialize selectedDay
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_notificationCleared) {
      final notificationService =
          Provider.of<GlobalNotificationService>(context, listen: false);
      notificationService.hide();
      _notificationCleared = true;
    }
  }

  Future<void> _loadEmployeeAndLeaveRequests() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final leaveProvider =
        Provider.of<LeaveRequestProvider>(context, listen: false);
    if (authProvider.user?['_id'] != null) {
      final employeeId = await leaveProvider
          .fetchEmployeeIdByUserId(authProvider.user!['_id']);
      setState(() {
        _employeeId = employeeId;
      });
      if (employeeId != null) {
        await leaveProvider.getUserLeaveRequests(employeeId);
        await leaveProvider.fetchLeaveBalances(
            employeeId); // Fetch balances after employeeId is set
      }
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
        if (_isHalfDay) {
          // For half-day leaves, set both start and end date to the same date
          _startDate = picked;
          _endDate = picked;
        } else {
          // For full-day leaves, handle start and end dates separately
          if (isStartDate) {
            _startDate = picked;
            if (_endDate != null && _endDate!.isBefore(_startDate!)) {
              _endDate = _startDate;
            }
          } else {
            _endDate = picked;
          }
        }
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    print('DEBUG: _submitLeaveRequest called');
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Form not valid');
      return;
    }
    // For half-day leaves, only start date is required
    if (_isHalfDay) {
      if (_startDate == null) {
        print('DEBUG: Start date is null for half-day leave');
        final notificationService =
            Provider.of<GlobalNotificationService>(context, listen: false);
        notificationService
            .showWarning('Please select a date for half-day leave');
        return;
      }
      // For half-day, set end date same as start date
      _endDate = _startDate;
    } else {
      // For full-day leaves, both dates are required
      if (_startDate == null || _endDate == null) {
        print('DEBUG: Start or end date is null for full-day leave');
        final notificationService =
            Provider.of<GlobalNotificationService>(context, listen: false);
        notificationService
            .showWarning('Please select both start and end dates');
        return;
      }
    }

    setState(() => _isLoading = true);
    print('DEBUG: Set _isLoading true');

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final leaveProvider =
          Provider.of<LeaveRequestProvider>(context, listen: false);
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      log('DEBUG: profileProvider.profile = \\${profileProvider.profile}');
      log('DEBUG: authProvider.user = \\${authProvider.user}');
      final userId = authProvider.user?['_id'];
      final userRole = authProvider.user?['role'];
      String? employeeId;

      if (userRole == 'admin') {
        // For admins, we don't need an employee ID - we'll use the user ID directly
        employeeId = null;
      } else {
        // For employees, fetch the Employee document
        if (userId != null) {
          final fetchedEmployeeId =
              await leaveProvider.fetchEmployeeIdByUserId(userId);
          print('DEBUG: fetchedEmployeeId = $fetchedEmployeeId');
          if (fetchedEmployeeId != null) {
            employeeId = fetchedEmployeeId;
          }
        }
        if (employeeId == null) {
          print('DEBUG: employeeId is null');
          final notificationService =
              Provider.of<GlobalNotificationService>(context, listen: false);
          notificationService
              .showError('Employee record not found. Please contact admin.');
          setState(() => _isLoading = false);
          return;
        }
      }
      print('DEBUG: Submitting leave request');
      final requestData = {
        'leaveType': _selectedLeaveType,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'reason': _reasonController.text,
        'isHalfDay': _isHalfDay, // Add half-day flag
        'status': 'Pending',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'approverId': null,
        'comments': '',
      };

      // Add employeeId only for employees, not for admins
      if (employeeId != null) {
        requestData['employeeId'] = employeeId;
      }

      final success = await leaveProvider.createLeaveRequest(requestData);
      print('DEBUG: Leave request success = $success');

      if (!mounted) {
        print('DEBUG: Widget not mounted');
        return;
      }

      if (success) {
        print('DEBUG: Leave request was successful');
        final notificationService =
            Provider.of<GlobalNotificationService>(context, listen: false);
        notificationService.showSuccess('Leave request submitted successfully');
        _resetForm();

        // Reload leave requests and balances
        if (_employeeId != null) {
          print('DEBUG: Reloading leave requests and balances');
          await leaveProvider.getUserLeaveRequests(_employeeId!);
          await leaveProvider.fetchLeaveBalances(_employeeId!);
          setState(() {}); // Force UI update
        }
      } else {
        print('DEBUG: Leave request failed');
        print('DEBUG: leaveProvider.error = \\${leaveProvider.error}');
        final notificationService =
            Provider.of<GlobalNotificationService>(context, listen: false);
        notificationService
            .showError(leaveProvider.error ?? 'Failed to submit leave request');
      }
    } catch (e) {
      print('DEBUG: Exception caught: $e');
      if (!mounted) return;
      final notificationService =
          Provider.of<GlobalNotificationService>(context, listen: false);
      notificationService.showError('Error: $e');
    } finally {
      if (mounted) {
        print('DEBUG: Set _isLoading false');
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
      _isHalfDay = false; // Reset half-day option
    });
  }

  // Show cancel confirmation dialog
  void _showCancelDialog(String requestId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Leave Request'),
          content: const Text(
            'Are you sure you want to cancel this leave request? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _cancelLeaveRequest(requestId);
              },
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Cancel leave request
  Future<void> _cancelLeaveRequest(String requestId) async {
    final leaveProvider =
        Provider.of<LeaveRequestProvider>(context, listen: false);
    final notificationService =
        Provider.of<GlobalNotificationService>(context, listen: false);

    try {
      final success = await leaveProvider.cancelLeaveRequest(requestId);
      if (success) {
        notificationService.showSuccess('Leave request cancelled successfully');
        // Refresh the leave requests list
        if (_employeeId != null) {
          await leaveProvider.getUserLeaveRequests(_employeeId!);
        }
      } else {
        notificationService
            .showError(leaveProvider.error ?? 'Failed to cancel leave request');
      }
    } catch (e) {
      notificationService.showError('Error cancelling leave request: $e');
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      // Not logged in, show fallback or redirect
      return const Scaffold(
        body: Center(child: Text('Not logged in. Please log in.')),
      );
    }
    // Remove the admin access restriction - admins can now apply for leave
    final theme = Theme.of(context);
    final leaveProvider = Provider.of<LeaveRequestProvider>(context);

    final leaveBalances = leaveProvider.leaveBalances ?? {};
    final annualLeave = leaveBalances['annual'] ?? {};
    final sickLeave = leaveBalances['sick'] ?? {};
    final casualLeave = leaveBalances['casual'] ?? {};
    final maternityLeave = leaveBalances['maternity'] ?? {};
    final paternityLeave = leaveBalances['paternity'] ?? {};
    final unpaidLeave = leaveBalances['unpaid'] ?? {};

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leave Balance Summary
            ModernCard(
              accentColor: theme.colorScheme.primary,
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
                  SizedBox(
                    height: 70,
                    child: PageView(
                      controller: _balancePageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentBalancePage = index;
                        });
                      },
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLeaveBalanceItem(
                              'Annual Leave',
                              annualLeave['used']?.toString() ?? '-',
                              annualLeave['total']?.toString() ?? '-',
                            ),
                            _buildLeaveBalanceItem(
                              'Sick Leave',
                              sickLeave['used']?.toString() ?? '-',
                              sickLeave['total']?.toString() ?? '-',
                            ),
                            _buildLeaveBalanceItem(
                              'Casual Leave',
                              casualLeave['used']?.toString() ?? '-',
                              casualLeave['total']?.toString() ?? '-',
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLeaveBalanceItem(
                              'Maternity Leave',
                              maternityLeave['used']?.toString() ?? '-',
                              maternityLeave['total']?.toString() ?? '-',
                            ),
                            _buildLeaveBalanceItem(
                              'Paternity Leave',
                              paternityLeave['used']?.toString() ?? '-',
                              paternityLeave['total']?.toString() ?? '-',
                            ),
                            _buildLeaveBalanceItem(
                              'Unpaid Leave',
                              unpaidLeave['used']?.toString() ?? '-',
                              unpaidLeave['total']?.toString() ?? '-',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        2,
                        (index) => Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentBalancePage == index
                                    ? theme.colorScheme.primary
                                    : Colors.grey[400],
                              ),
                            )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Leave Calendar
            ModernCard(
              accentColor: theme.colorScheme.secondary,
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
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
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
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return const SizedBox();
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: events.take(3).map<Widget>((event) {
                            final leaveType = (event is Map<String, dynamic>
                                    ? event['leaveType']
                                    : '') ??
                                '';
                            final color =
                                leaveTypeColors[leaveType] ?? Colors.black;
                            return Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 1.0),
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // New Leave Request Form
            ModernCard(
              accentColor: theme.colorScheme.tertiary,
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
                    // Half-day toggle
                    SwitchListTile(
                      title: const Text('Half Day Leave'),
                      subtitle: const Text(
                          'Request half-day leave instead of full day'),
                      value: _isHalfDay,
                      onChanged: (value) {
                        setState(() {
                          _isHalfDay = value;
                          // Clear end date when switching to half-day
                          if (value) {
                            _endDate = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Date selection - show different UI for half-day vs full-day
                    _isHalfDay
                        ? TextFormField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                            controller: TextEditingController(
                              text: _startDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_startDate!)
                                  : '',
                            ),
                            onTap: () => _selectDate(context, true),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Start Date',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon:
                                        const Icon(Icons.calendar_today),
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
                                    suffixIcon:
                                        const Icon(Icons.calendar_today),
                                  ),
                                  controller: TextEditingController(
                                    text: _endDate != null
                                        ? DateFormat('yyyy-MM-dd')
                                            .format(_endDate!)
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
            const SizedBox(height: 24),

            // Recent Leave Requests
            Text(
              'Recent Leave Requests',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Status legend
            const Row(
              children: [
                _StatusLegend(color: Colors.green, label: 'Approved'),
                SizedBox(width: 8),
                _StatusLegend(color: Colors.orange, label: 'Pending'),
                SizedBox(width: 8),
                _StatusLegend(color: Colors.red, label: 'Rejected'),
                SizedBox(width: 8),
                _StatusLegend(color: Colors.grey, label: 'Other'),
              ],
            ),
            const SizedBox(height: 8),
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
                  final isPending =
                      (request['status'] ?? 'Pending') == 'Pending';

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
                          // Add cancel button for pending requests
                          if (isPending) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () =>
                                    _showCancelDialog(request['_id']),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.red,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(
                                        color: Colors.red, width: 1),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel Request',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          (request['status'] ?? 'Pending').toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(request['status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: _getStatusColor(request['status'])
                            .withValues(alpha: 0.1),
                        side: BorderSide(
                          color: _getStatusColor(request['status']),
                        ),
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
    String used,
    String total,
  ) {
    return Column(
      children: [
        Text(
          type,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: leaveTypeColors[type] ?? Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          used,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: leaveTypeColors[type] ?? Colors.black,
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

class _StatusLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
