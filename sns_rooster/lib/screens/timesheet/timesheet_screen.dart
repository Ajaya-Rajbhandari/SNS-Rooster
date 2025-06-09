import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../widgets/navigation_drawer.dart';
import 'package:flutter/services.dart';

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({Key? key}) : super(key: key);

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen>
    with SingleTickerProviderStateMixin {
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  DateTime _selectedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  String _selectedFilter = 'All';
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _filters = ['All', 'Approved', 'Pending', 'Rejected'];

  // Mock data for employee view (only one user's data)
  final List<Map<String, dynamic>> _mockTimesheetData = [
    {
      'date': DateTime.now().subtract(const Duration(days: 6)),
      'checkIn': '09:00 AM',
      'checkOut': '06:00 PM',
      'totalHours': 9.0,
      'status': 'Approved',
      'breakDuration': '01:00',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'checkIn': '09:15 AM',
      'checkOut': '06:15 PM',
      'totalHours': 9.0,
      'status': 'Pending',
      'breakDuration': '00:45',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 4)),
      'checkIn': '09:00 AM',
      'checkOut': '05:30 PM',
      'totalHours': 8.5,
      'status': 'Approved',
      'breakDuration': '01:00',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'checkIn': '08:45 AM',
      'checkOut': '05:45 PM',
      'totalHours': 9.0,
      'status': 'Approved',
      'breakDuration': '00:30',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'checkIn': '09:00 AM',
      'checkOut': '06:00 PM',
      'totalHours': 9.0,
      'status': 'Rejected',
      'breakDuration': '01:15',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'checkIn': '09:00 AM',
      'checkOut': '06:00 PM',
      'totalHours': 9.0,
      'status': 'Approved',
      'breakDuration': '01:00',
    },
    {
      'date': DateTime.now(),
      'checkIn': '09:00 AM',
      'checkOut': '--',
      'totalHours': 0.0,
      'status': 'Pending',
      'breakDuration': '00:00',
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
    final List<Map<String, dynamic>> dateFilteredData =
        _mockTimesheetData.where((entry) {
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

  // Helper to parse time string (e.g., "09:00 AM") into DateTime
  DateTime _parseTime(String timeString) {
    final now = DateTime.now();
    final format = DateFormat('hh:mm a'); // Assumes 12-hour format with AM/PM
    final parsedTime = format.parse(timeString);
    return DateTime(
      now.year,
      now.month,
      now.day,
      parsedTime.hour,
      parsedTime.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timesheet'),
        elevation: 0,
        backgroundColor: theme.primaryColor,
      ),
      drawer: const AppNavigationDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range Picker
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
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

              // Timesheet Summary
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
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
              const SizedBox(height: 16),
              Text(
                'Your Timesheet Entries',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Quick Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
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

              // Timesheet Entries List
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredData.length,
                        itemBuilder: (context, index) {
                          final entry = _filteredData[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TimesheetRow(entry: entry),
                          );
                        },
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
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.access_time,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
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
              final breakDurationFocusNode = FocusNode();

              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    top: 20.0,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
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
                          const SizedBox(height: 20),
                          // Clock In Time
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: clockInController,
                                  decoration: InputDecoration(
                                    labelText: 'Clock In Time',
                                    prefixIcon: const Icon(Icons.login),
                                    suffixIcon: const Icon(Icons.access_time),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 18, horizontal: 12),
                                  ),
                                  readOnly: true,
                                  onTap: () async {
                                    TimeOfDay initialTime = TimeOfDay.now();
                                    if (clockInController.text.isNotEmpty) {
                                      try {
                                        final format = DateFormat('hh:mm a');
                                        final parsed = format
                                            .parse(clockInController.text);
                                        initialTime = TimeOfDay(
                                            hour: parsed.hour,
                                            minute: parsed.minute);
                                      } catch (_) {}
                                    }
                                    final TimeOfDay? pickedTime =
                                        await showTimePicker(
                                      context: context,
                                      initialTime: initialTime,
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
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.schedule),
                                tooltip: 'Set to now',
                                onPressed: () {
                                  final now = TimeOfDay.now();
                                  clockInController.text = now.format(context);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Clock Out Time
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: clockOutController,
                                  decoration: InputDecoration(
                                    labelText: 'Clock Out Time',
                                    prefixIcon: const Icon(Icons.logout),
                                    suffixIcon: const Icon(Icons.access_time),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 18, horizontal: 12),
                                  ),
                                  readOnly: true,
                                  onTap: () async {
                                    TimeOfDay initialTime = TimeOfDay.now();
                                    if (clockOutController.text.isNotEmpty) {
                                      try {
                                        final format = DateFormat('hh:mm a');
                                        final parsed = format
                                            .parse(clockOutController.text);
                                        initialTime = TimeOfDay(
                                            hour: parsed.hour,
                                            minute: parsed.minute);
                                      } catch (_) {}
                                    }
                                    final TimeOfDay? pickedTime =
                                        await showTimePicker(
                                      context: context,
                                      initialTime: initialTime,
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
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.schedule),
                                tooltip: 'Set to now',
                                onPressed: () {
                                  final now = TimeOfDay.now();
                                  clockOutController.text = now.format(context);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Break Duration ChoiceChips
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'Break Duration',
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Row(
                            children: [
                              _BreakDurationChip(
                                label: '15 min',
                                value: '00:15',
                                selectedValue: breakDurationController.text,
                                onSelected: (val) {
                                  setState(() {
                                    breakDurationController.text = val;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _BreakDurationChip(
                                label: '30 min',
                                value: '00:30',
                                selectedValue: breakDurationController.text,
                                onSelected: (val) {
                                  setState(() {
                                    breakDurationController.text = val;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _BreakDurationChip(
                                label: '45 min',
                                value: '00:45',
                                selectedValue: breakDurationController.text,
                                onSelected: (val) {
                                  setState(() {
                                    breakDurationController.text = val;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _BreakDurationChip(
                                label: '1 hour',
                                value: '01:00',
                                selectedValue: breakDurationController.text,
                                onSelected: (val) {
                                  setState(() {
                                    breakDurationController.text = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Optionally, keep the TextFormField for custom input
                          TextFormField(
                            controller: breakDurationController,
                            focusNode: breakDurationFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Custom (HH:MM)',
                              prefixIcon: const Icon(Icons.edit),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 12),
                            ),
                            readOnly: false,
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
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                // Parse time strings into DateTime objects (mock parsing)
                                final checkInTime =
                                    _parseTime(clockInController.text);
                                final checkOutTime =
                                    _parseTime(clockOutController.text);

                                // Calculate total hours (mock calculation for simplicity)
                                final Duration totalDuration =
                                    checkOutTime.difference(checkInTime);
                                final double totalHours =
                                    totalDuration.inMinutes / 60.0;

                                setState(() {
                                  _mockTimesheetData.add({
                                    'date': DateTime.now(),
                                    'checkIn': clockInController.text,
                                    'checkOut': clockOutController.text,
                                    'totalHours': totalHours,
                                    'status':
                                        'Pending', // New entries are typically pending
                                    'breakDuration':
                                        breakDurationController.text,
                                  });
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Timesheet entry saved!')),
                                );
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity,
                                  54), // Slightly taller button
                              backgroundColor: theme.primaryColor,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      12)), // Rounded corners
                              elevation: 3, // Add slight elevation
                            ),
                            child: const Text('Save Entry',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)), // Bold text
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
        icon: const Icon(Icons.add, color: Colors.white), // White icon
        label: const Text('Add Entry',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)), // White and bold text
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
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[700])),
      ],
    );
  }
}

class TimesheetRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  const TimesheetRow({super.key, required this.entry});

  static Color _getStatusColor(String status) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = TimesheetRow._getStatusColor(entry['status']);

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
                          child: Text('In: ${entry['checkIn']}',
                              style: theme.textTheme.bodyMedium)),
                      const SizedBox(width: 12),
                      const Icon(Icons.logout,
                          size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text('Out: ${entry['checkOut']}',
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
                          child: Text('Break: ${entry['breakDuration']}',
                              style: theme.textTheme.bodySmall)),
                      const SizedBox(width: 12),
                      const Icon(Icons.timer, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text('Total: ${entry['totalHours']} hrs',
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

class _BreakDurationChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _BreakDurationChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedValue == value,
      onSelected: (_) => onSelected(value),
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: selectedValue == value ? Colors.white : Colors.black,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
