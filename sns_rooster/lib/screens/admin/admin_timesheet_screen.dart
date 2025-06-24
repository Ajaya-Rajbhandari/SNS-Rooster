import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../widgets/admin_side_navigation.dart';
// Import shared widgets/classes (TimesheetSummary, TimesheetRow)

class AdminTimesheetScreen extends StatefulWidget {
  const AdminTimesheetScreen({Key? key}) : super(key: key);

  @override
  State<AdminTimesheetScreen> createState() => _AdminTimesheetScreenState();
}

class _AdminTimesheetScreenState extends State<AdminTimesheetScreen>
    with SingleTickerProviderStateMixin {
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  final DateTime _selectedDate = DateTime.now();
  final CalendarFormat _calendarFormat = CalendarFormat.week;

  String _selectedFilter = 'All';
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _filters = ['All', 'Approved', 'Pending', 'Rejected'];

  String _selectedEmployeeId =
      'user1'; // Default selected employee for admin view

  // Mock data for admin view (includes multiple users)
  final List<Map<String, dynamic>> _mockTimesheetData = [
    {
      'userId': 'user1',
      'date': DateTime.now().subtract(const Duration(days: 6)),
      'checkIn': '09:00 AM',
      'checkOut': '06:00 PM',
      'totalHours': 9.0,
      'status': 'Approved',
    },
    {
      'userId': 'user1',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'checkIn': '09:15 AM',
      'checkOut': '06:15 PM',
      'totalHours': 9.0,
      'status': 'Pending',
    },
    {
      'userId': 'user1',
      'date': DateTime.now().subtract(const Duration(days: 4)),
      'checkIn': '09:00 AM',
      'checkOut': '05:30 PM',
      'totalHours': 8.5,
      'status': 'Approved',
    },
    {
      'userId': 'user2',
      'date': DateTime.now().subtract(const Duration(days: 6)),
      'checkIn': '08:30 AM',
      'checkOut': '05:30 PM',
      'totalHours': 9.0,
      'status': 'Approved',
    },
    {
      'userId': 'user2',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'checkIn': '09:00 AM',
      'checkOut': '05:00 PM',
      'totalHours': 8.0,
      'status': 'Approved',
    },
    {
      'userId': 'user3',
      'date': DateTime.now().subtract(const Duration(days: 4)),
      'checkIn': '09:00 AM',
      'checkOut': '06:00 PM',
      'totalHours': 9.0,
      'status': 'Pending',
    },
    {
      'userId': 'user1',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'checkIn': '08:45 AM',
      'checkOut': '05:45 PM',
      'totalHours': 9.0,
      'status': 'Approved',
    },
    {
      'userId': 'user1',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'checkIn': '09:00 AM',
      'checkOut': '06:00 PM',
      'totalHours': 9.0,
      'status': 'Rejected',
    },
    {
      'userId': 'user1',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'checkIn': '09:00 AM',
      'checkOut': '06:00 PM',
      'totalHours': 9.0,
      'status': 'Approved',
    },
    {
      'userId': 'user1',
      'date': DateTime.now(),
      'checkIn': '09:00 AM',
      'checkOut': '--',
      'totalHours': 0.0,
      'status': 'Pending',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2025),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
        _isLoading = true;
      });
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> get _filteredData {
    List<Map<String, dynamic>> dataToFilter = _mockTimesheetData
        .where((entry) => entry['userId'] == _selectedEmployeeId)
        .toList();

    final List<Map<String, dynamic>> dateFilteredData =
        dataToFilter.where((entry) {
      final entryDate = entry['date'] as DateTime;
      return entryDate.isAfter(
              _selectedDateRange.start.subtract(const Duration(days: 1))) &&
          entryDate
              .isBefore(_selectedDateRange.end.add(const Duration(days: 1)));
    }).toList();

    if (_selectedFilter == 'All') return dateFilteredData;
    return dateFilteredData
        .where((entry) => entry['status'] == _selectedFilter)
        .toList();
  }

  double get _totalHoursFiltered {
    return _filteredData.fold<double>(
      0,
      (sum, entry) => sum + (entry['totalHours'] as double),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      drawer: const AdminSideNavigation(currentRoute: '/admin_timesheet'),
      appBar: AppBar(
        title: const Text('Admin Timesheet'),
        elevation: 0,
        backgroundColor: theme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Export functionality coming soon!')),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin View: Select Employee',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedEmployeeId,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'user1', child: Text('User 1')),
                    DropdownMenuItem(value: 'user2', child: Text('User 2')),
                    DropdownMenuItem(value: 'user3', child: Text('User 3')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedEmployeeId = value;
                        _isLoading = true;
                      });
                      Future.delayed(const Duration(seconds: 1), () {
                        setState(() {
                          _isLoading = false;
                        });
                      });
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected user: $value')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Date Range Picker
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Date Range',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${dateFormat.format(_selectedDateRange.start)} - ${dateFormat.format(_selectedDateRange.end)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _selectDateRange(context),
                        icon: const Icon(Icons.edit),
                        label: const Text('Change'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Timesheet Summary (updated for admin view)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
                child: TimesheetSummary(
                  totalHours: _totalHoursFiltered,
                  presentCount: _filteredData
                      .where((e) =>
                          e['status'] == 'Approved' || e['status'] == 'Pending')
                      .length,
                  absentCount: _filteredData
                      .where((e) =>
                          e['status'] == 'Absent' || e['status'] == 'Rejected')
                      .length,
                  overtimeHours: 2.5, // Mock overtime
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Timesheet Entries for Selected Employee',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Quick Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: theme.primaryColor.withOpacity(0.2),
                        checkmarkColor: theme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? theme.primaryColor : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Timesheet Table
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            Colors.grey[50],
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Date',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Check In',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Check Out',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Total Hours',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Status',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: _filteredData.map((entry) {
                            return DataRow(
                              cells: [
                                DataCell(
                                    Text(dateFormat.format(entry['date']))),
                                DataCell(Text(entry['checkIn'])),
                                DataCell(Text(entry['checkOut'])),
                                DataCell(Text('${entry['totalHours']} hrs')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(entry['status'])
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getStatusColor(entry['status']),
                                      ),
                                    ),
                                    child: Text(
                                      entry['status'],
                                      style: TextStyle(
                                        color: _getStatusColor(entry['status']),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),

              // Total Hours Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.access_time,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Total Hours',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_totalHoursFiltered.toStringAsFixed(1)} hrs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              final formKey = GlobalKey<FormState>();
              final clockInController = TextEditingController();
              final clockOutController = TextEditingController();
              final breakDurationController = TextEditingController();

              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Timesheet Entry',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: clockInController,
                            decoration: InputDecoration(
                              labelText: 'Clock In Time',
                              prefixIcon: const Icon(Icons.login),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final TimeOfDay? pickedTime =
                                  await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (pickedTime != null) {
                                clockInController.text =
                                    pickedTime.format(context);
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter clock in time';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: clockOutController,
                            decoration: InputDecoration(
                              labelText: 'Clock Out Time',
                              prefixIcon: const Icon(Icons.logout),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final TimeOfDay? pickedTime =
                                  await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (pickedTime != null) {
                                clockOutController.text =
                                    pickedTime.format(context);
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter clock out time';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: breakDurationController,
                            decoration: InputDecoration(
                              labelText:
                                  'Break Duration (e.g., 01:00 for 1 hour)',
                              prefixIcon: const Icon(Icons.free_breakfast),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter break duration';
                              }
                              if (!RegExp(r'^([0-9]{2}):([0-9]{2})$')
                                  .hasMatch(value)) {
                                return 'Enter a valid duration (HH:MM)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Timesheet entry saved! (Mock)')),
                                );
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: theme.primaryColor,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Save Entry',
                                style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        backgroundColor: theme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }
}

class TimesheetSummary extends StatelessWidget {
  final double totalHours;
  final int presentCount;
  final int absentCount;
  final double overtimeHours;

  const TimesheetSummary({
    super.key,
    required this.totalHours,
    required this.presentCount,
    required this.absentCount,
    required this.overtimeHours,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryTile(
                label: 'Total Hours',
                value: '${totalHours.toStringAsFixed(1)} hrs'),
            _SummaryTile(label: 'Present', value: '$presentCount'),
            _SummaryTile(label: 'Absent', value: '$absentCount'),
            _SummaryTile(
                label: 'Overtime',
                value: '${overtimeHours.toStringAsFixed(1)} hrs'),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryTile({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Flexible( // Wrap Column with Flexible
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          Flexible( // Make text flexible
            child: Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2), // Allow wrapping to 2 lines
          ),
          const SizedBox(height: 4),
          Flexible( // Make text flexible
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[700]),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2), // Allow wrapping to 2 lines
          ),
        ],
      ),
    );
  }
}

class TimesheetRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  const TimesheetRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = entry['status'] == 'Present'
        ? Colors.green
        : entry['status'] == 'Late'
            ? Colors.orange
            : Colors.redAccent;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry['date'].day}/${entry['date'].month}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _weekday(entry['date'].weekday),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.login, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text('In: ${entry['clockIn']}',
                              style: theme.textTheme.bodyMedium)),
                      const SizedBox(width: 12),
                      const Icon(Icons.logout,
                          size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text('Out: ${entry['clockOut']}',
                              style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.free_breakfast,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text('Break: ${entry['break']}',
                              style: theme.textTheme.bodySmall)),
                      const SizedBox(width: 12),
                      const Icon(Icons.timer, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text('Total: ${entry['total']}',
                              style: theme.textTheme.bodySmall)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                Icon(Icons.circle, color: statusColor, size: 16),
                const SizedBox(height: 2),
                Text(entry['status'],
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _weekday(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
