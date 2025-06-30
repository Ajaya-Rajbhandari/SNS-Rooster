import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:sns_rooster/widgets/app_drawer.dart';
import '../../providers/attendance_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({Key? key}) : super(key: key);

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen>
    with SingleTickerProviderStateMixin {
  // Set default range to current month
  DateTime get _firstDayOfMonth =>
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime get _lastDayOfMonth =>
      DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  late DateTimeRange _selectedDateRange;

  String _selectedFilter = 'All';
  String _selectedView = 'List'; // 'List' or 'Daily'
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final List<String> _filters = ['All', 'Approved', 'Pending', 'Rejected'];

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

    // Set default first
    _selectedDateRange = DateTimeRange(
      start: _firstDayOfMonth,
      end: _lastDayOfMonth,
    );

    // Then try to load saved state (which will override if present)
    _loadQuickActionState(); // Fetch attendance for current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      if (authProvider.user != null) {
        // Use _id field from MongoDB instead of id
        final userId = authProvider.user!['_id']?.toString() ??
            authProvider.user!['id']?.toString();
        if (userId != null) {
          attendanceProvider.fetchUserAttendance(userId);
        }
      }
    });
  }

  Future<void> _loadQuickActionState() async {
    final prefs = await SharedPreferences.getInstance();
    bool changed = false;
    final filter = prefs.getString('timesheet_selected_filter');
    final start = prefs.getString('timesheet_selected_range_start');
    final end = prefs.getString('timesheet_selected_range_end');
    if (filter != null &&
        _filters.contains(filter) &&
        filter != _selectedFilter) {
      _selectedFilter = filter;
      changed = true;
    }
    if (start != null && end != null) {
      final startDate = DateTime.tryParse(start);
      final endDate = DateTime.tryParse(end);
      if (startDate != null &&
          endDate != null &&
          (startDate != _selectedDateRange.start ||
              endDate != _selectedDateRange.end)) {
        _selectedDateRange = DateTimeRange(start: startDate, end: endDate);
        changed = true;
      }
    }
    if (changed) setState(() {});
  }

  Future<void> _saveQuickActionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timesheet_selected_filter', _selectedFilter);
    await prefs.setString('timesheet_selected_range_start',
        _selectedDateRange.start.toIso8601String());
    await prefs.setString('timesheet_selected_range_end',
        _selectedDateRange.end.toIso8601String());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<DateTimeRange?> showCustomDateRangePicker(
      BuildContext context, DateTimeRange? initialRange) {
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                textStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked =
        await showCustomDateRangePicker(context, _selectedDateRange);
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      await _saveQuickActionState();
    }
  }

  // Helper method to calculate total hours from attendance data
  double _calculateTotalHours(Map<String, dynamic> entry) {
    try {
      // Parse check-in time
      DateTime? checkInTime;
      final checkInField = entry['checkInTime'] ?? entry['checkIn'];
      if (checkInField != null) {
        checkInTime = DateTime.tryParse(checkInField.toString());
      }

      // Parse check-out time
      DateTime? checkOutTime;
      final checkOutField = entry['checkOutTime'] ?? entry['checkOut'];
      if (checkOutField != null && checkOutField.toString() != 'null') {
        checkOutTime = DateTime.tryParse(checkOutField.toString());
      }

      // If not clocked out yet, use current time
      if (checkInTime != null && checkOutTime == null) {
        checkOutTime = DateTime.now();
      }

      // Calculate base hours worked
      double totalHours = 0.0;
      if (checkInTime != null && checkOutTime != null) {
        final workDuration = checkOutTime.difference(checkInTime);
        totalHours = workDuration.inMinutes / 60.0;
      }

      // Subtract break time
      double totalBreakHours = 0.0;
      final breaks = entry['breaks'];
      if (breaks is List) {
        for (var breakItem in breaks) {
          if (breakItem is Map<String, dynamic>) {
            final breakDuration = breakItem['duration'];
            if (breakDuration is num) {
              // Duration is in milliseconds, convert to hours
              totalBreakHours += (breakDuration / (1000 * 60 * 60));
            }
          }
        }
      }
      final netWorkHours = totalHours - totalBreakHours;

      return netWorkHours > 0 ? netWorkHours : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  List<Map<String, dynamic>> get _filteredData {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final List<Map<String, dynamic>> records = attendanceProvider
        .attendanceRecords
        .cast<Map<String, dynamic>>()
        .toList();

    // Process records and add calculated totalHours
    final List<Map<String, dynamic>> processedRecords = records.map((entry) {
      final processedEntry = Map<String, dynamic>.from(entry);
      processedEntry['totalHours'] = _calculateTotalHours(entry);

      // Ensure status field exists (default to 'Approved' for existing records)
      if (processedEntry['status'] == null) {
        processedEntry['status'] = 'Approved';
      }

      return processedEntry;
    }).toList();

    // Group by date (yyyy-MM-dd) and only keep the latest open record per day
    final Map<String, Map<String, dynamic>> latestOpenPerDay = {};
    for (final entry in processedRecords) {
      DateTime? entryDate;
      try {
        entryDate = entry['date'] is DateTime
            ? entry['date']
            : DateTime.tryParse(entry['date']?.toString() ?? '');
        if (entryDate == null && entry['checkIn'] != null) {
          entryDate = DateTime.tryParse(entry['checkIn'].toString());
        }
        if (entryDate == null && entry['checkInTime'] != null) {
          entryDate = DateTime.tryParse(entry['checkInTime'].toString());
        }
      } catch (_) {}
      if (entryDate == null) continue;
      final dateKey = DateFormat('yyyy-MM-dd').format(entryDate);
      // Only keep the latest open record (no checkOut) per day
      if ((entry['checkOut'] == null ||
              entry['checkOut'].toString() == 'null' ||
              entry['checkOut'].toString().isEmpty) &&
          (entry['checkOutTime'] == null ||
              entry['checkOutTime'].toString() == 'null' ||
              entry['checkOutTime'].toString().isEmpty)) {
        DateTime? currentCheckIn =
            DateTime.tryParse(entry['checkIn']?.toString() ?? '') ??
                DateTime.tryParse(entry['checkInTime']?.toString() ?? '');
        DateTime? previousCheckIn = DateTime.tryParse(
                latestOpenPerDay[dateKey]?['checkIn']?.toString() ?? '') ??
            DateTime.tryParse(
                latestOpenPerDay[dateKey]?['checkInTime']?.toString() ?? '');
        if (!latestOpenPerDay.containsKey(dateKey) ||
            (currentCheckIn != null &&
                previousCheckIn != null &&
                previousCheckIn.isBefore(currentCheckIn))) {
          latestOpenPerDay[dateKey] = entry;
        }
      }
    }
    // Remove all but the latest open record for each day
    final List<Map<String, dynamic>> filteredRecords =
        processedRecords.where((entry) {
      DateTime? entryDate;
      try {
        entryDate = entry['date'] is DateTime
            ? entry['date']
            : DateTime.tryParse(entry['date']?.toString() ?? '');
        if (entryDate == null && entry['checkIn'] != null) {
          entryDate = DateTime.tryParse(entry['checkIn'].toString());
        }
        if (entryDate == null && entry['checkInTime'] != null) {
          entryDate = DateTime.tryParse(entry['checkInTime'].toString());
        }
      } catch (_) {}
      if (entryDate == null) return false;
      final dateKey = DateFormat('yyyy-MM-dd').format(entryDate);
      // If open, only keep the latest open record for the day
      if ((entry['checkOut'] == null ||
              entry['checkOut'].toString() == 'null' ||
              entry['checkOut'].toString().isEmpty) &&
          (entry['checkOutTime'] == null ||
              entry['checkOutTime'].toString() == 'null' ||
              entry['checkOutTime'].toString().isEmpty)) {
        return latestOpenPerDay[dateKey] == entry;
      }
      // Otherwise, keep all closed records
      return true;
    }).toList();
    final List<Map<String, dynamic>> dateFilteredData =
        filteredRecords.where((entry) {
      DateTime? entryDate;
      try {
        entryDate = entry['date'] is DateTime
            ? entry['date']
            : DateTime.tryParse(entry['date']?.toString() ?? '');
        if (entryDate == null && entry['checkIn'] != null) {
          entryDate = DateTime.tryParse(entry['checkIn'].toString());
        }
        if (entryDate == null && entry['checkInTime'] != null) {
          entryDate = DateTime.tryParse(entry['checkInTime'].toString());
        }
      } catch (_) {}
      if (entryDate == null) return false;
      return entryDate.isAfter(
              _selectedDateRange.start.subtract(const Duration(days: 1))) &&
          entryDate
              .isBefore(_selectedDateRange.end.add(const Duration(days: 1)));
    }).toList();
    if (_selectedFilter == 'All') return dateFilteredData;
    return dateFilteredData
        .where((entry) =>
            ((entry['status']?.toString().trim().toLowerCase() ?? 'approved') ==
                _selectedFilter.trim().toLowerCase()))
        .toList();
  }

  double get _totalHoursFiltered {
    return _filteredData.fold<double>(
      0,
      (sum, entry) =>
          sum +
          ((entry['totalHours'] is num)
              ? (entry['totalHours'] as num).toDouble()
              : 0.0),
    );
  }

  // Get weekly summary for the selected date range
  Map<String, double> get _weeklySummary {
    Map<String, double> weeklySummary = {};
    for (var entry in _filteredData) {
      DateTime? entryDate;
      try {
        entryDate = entry['date'] is DateTime
            ? entry['date']
            : DateTime.tryParse(entry['date']?.toString() ?? '');
        if (entryDate == null && entry['checkIn'] != null) {
          entryDate = DateTime.tryParse(entry['checkIn'].toString());
        }
        if (entryDate == null && entry['checkInTime'] != null) {
          entryDate = DateTime.tryParse(entry['checkInTime'].toString());
        }
      } catch (_) {}

      if (entryDate != null) {
        // Get the start of the week (Monday)
        final startOfWeek =
            entryDate.subtract(Duration(days: entryDate.weekday - 1));
        final weekKey = 'Week of ${DateFormat('MMM dd').format(startOfWeek)}';

        final hours = (entry['totalHours'] is num)
            ? (entry['totalHours'] as num).toDouble()
            : 0.0;
        weeklySummary[weekKey] = (weeklySummary[weekKey] ?? 0.0) + hours;
      }
    }

    return weeklySummary;
  }

  double get _totalOvertimeHours {
    double overtime = 0.0;
    Map<String, double> dailyTotals = {};
    // Group entries by date and calculate daily totals
    for (var entry in _filteredData) {
      DateTime? entryDate;
      try {
        entryDate = entry['date'] is DateTime
            ? entry['date']
            : DateTime.tryParse(entry['date']?.toString() ?? '');
        if (entryDate == null && entry['checkIn'] != null) {
          entryDate = DateTime.tryParse(entry['checkIn'].toString());
        }
        if (entryDate == null && entry['checkInTime'] != null) {
          entryDate = DateTime.tryParse(entry['checkInTime'].toString());
        }
      } catch (_) {}

      if (entryDate != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(entryDate);
        final hours = (entry['totalHours'] is num)
            ? (entry['totalHours'] as num).toDouble()
            : 0.0;
        dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0.0) + hours;
      }
    }

    // Calculate overtime (hours over 8 per day)
    for (var dailyHours in dailyTotals.values) {
      if (dailyHours > 8.0) {
        overtime += dailyHours - 8.0;
      }
    }

    return overtime;
  }

  // Helper to parse time string (e.g., "09:00 AM") into DateTime
  DateTime _parseTime(String timeString) {
    final now = DateTime.now();
    final format = DateFormat('HH:mm'); // Always 24-hour format
    final parsedTime = format.parseStrict(timeString);
    return DateTime(
      now.year,
      now.month,
      now.day,
      parsedTime.hour,
      parsedTime.minute,
    );
  }

  // Add helper for week range
  DateTimeRange get _thisWeekRange {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return DateTimeRange(start: startOfWeek, end: endOfWeek);
  }

  // Build list view (original implementation)
  Widget _buildListView(List<Map<String, dynamic>> data) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final entry = data[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TimesheetRow(entry: entry),
        );
      },
    );
  }

  // Build daily view with grouped entries
  Widget _buildDailyView(List<Map<String, dynamic>> data) {
    // Group entries by date
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var entry in data) {
      DateTime? entryDate;
      try {
        entryDate = entry['date'] is DateTime
            ? entry['date']
            : DateTime.tryParse(entry['date']?.toString() ?? '');
        if (entryDate == null && entry['checkIn'] != null) {
          entryDate = DateTime.tryParse(entry['checkIn'].toString());
        }
        if (entryDate == null && entry['checkInTime'] != null) {
          entryDate = DateTime.tryParse(entry['checkInTime'].toString());
        }
      } catch (_) {}

      if (entryDate != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(entryDate);
        groupedData[dateKey] = groupedData[dateKey] ?? [];
        groupedData[dateKey]!.add(entry);
      }
    }

    // Sort dates in descending order (most recent first)
    final sortedDates = groupedData.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final entriesForDay = groupedData[dateKey]!;
        final date = DateTime.parse(dateKey);

        // Calculate daily totals
        double dailyHours = 0.0;
        int dailyBreaks = 0;
        for (var entry in entriesForDay) {
          final hours = (entry['totalHours'] is num)
              ? (entry['totalHours'] as num).toDouble()
              : 0.0;
          dailyHours += hours;

          // Count breaks
          if (entry['breakDuration'] != null &&
              entry['breakDuration'].toString() != '--' &&
              entry['breakDuration'].toString().isNotEmpty) {
            dailyBreaks++;
          }
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header with daily summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(date),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        Text(
                          '${entriesForDay.length} entries • $dailyBreaks breaks',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: dailyHours > 8
                            ? Colors.orange.withOpacity(0.2)
                            : Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${dailyHours.toStringAsFixed(1)} hrs',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: dailyHours > 8
                              ? Colors.orange[700]
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Individual entries for the day
                ...entriesForDay.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TimesheetRow(entry: entry),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timesheet'),
        elevation: 0,
        backgroundColor: theme.primaryColor,
      ),
      drawer: const AppDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Date Range Picker Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: theme.primaryColor.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month,
                              color: theme.primaryColor, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date Range',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${dateFormat.format(_selectedDateRange.start)} – ${dateFormat.format(_selectedDateRange.end)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _selectDateRange(context),
                            icon: const Icon(Icons.date_range),
                            label: const Text('Change'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.primaryColor,
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Select a date range to view your timesheet entries.',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDateRange = DateTimeRange(
                                    start: _firstDayOfMonth,
                                    end: _lastDayOfMonth,
                                  );
                                });
                                _saveQuickActionState();
                              },
                              child: const Text('This Month'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDateRange = _thisWeekRange;
                                });
                                _saveQuickActionState();
                              },
                              child: const Text('This Week'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDateRange = DateTimeRange(
                                    start: DateTime(2020),
                                    end: DateTime.now(),
                                  );
                                });
                                _saveQuickActionState();
                              },
                              child: const Text('All Time'),
                            ),
                          ],
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
                  overtimeHours: _totalOvertimeHours, // Use calculated overtime
                ),
              ),
              const SizedBox(height: 16),

              // Weekly Summary Section
              if (_weeklySummary.isNotEmpty) ...[
                Text(
                  'Weekly Summary',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: _weeklySummary.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '${entry.value.toStringAsFixed(1)} hrs',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

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
                          _saveQuickActionState();
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

              // View Toggle Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'List',
                        label: Text('List View'),
                        icon: Icon(Icons.list),
                      ),
                      ButtonSegment(
                        value: 'Daily',
                        label: Text('Daily View'),
                        icon: Icon(Icons.calendar_view_day),
                      ),
                    ],
                    selected: {_selectedView},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        _selectedView = selection.first;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Timesheet Entries List
              Consumer<AttendanceProvider>(
                builder: (context, attendanceProvider, _) {
                  if (attendanceProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (attendanceProvider.error != null) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error: ${attendanceProvider.error}',
                          style: const TextStyle(color: Colors.red)),
                    );
                  }
                  if (_filteredData.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No timesheet entries for this range.'),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _selectedView == 'Daily'
                        ? _buildDailyView(_filteredData)
                        : _buildListView(_filteredData),
                  );
                },
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
      floatingActionButton: (authProvider.user != null &&
              authProvider.user!['role'] == 'admin')
          ? FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet<Map<String, dynamic>>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
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
                          bottom:
                              MediaQuery.of(context).viewInsets.bottom + 20.0,
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
                                          suffixIcon:
                                              const Icon(Icons.access_time),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 18, horizontal: 12),
                                        ),
                                        readOnly: true,
                                        onTap: () async {
                                          TimeOfDay initialTime =
                                              TimeOfDay.now();
                                          if (clockInController
                                              .text.isNotEmpty) {
                                            try {
                                              final format =
                                                  DateFormat('hh:mm a');
                                              final parsed = format.parse(
                                                  clockInController.text);
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
                                      icon: const Icon(Icons.calendar_month),
                                      tooltip: 'Set to now',
                                      onPressed: () {
                                        final now = TimeOfDay.now();
                                        clockInController.text =
                                            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
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
                                          suffixIcon:
                                              const Icon(Icons.schedule),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 18, horizontal: 12),
                                        ),
                                        readOnly: true,
                                        onTap: () async {
                                          TimeOfDay initialTime =
                                              TimeOfDay.now();
                                          if (clockOutController
                                              .text.isNotEmpty) {
                                            try {
                                              final format =
                                                  DateFormat('hh:mm a');
                                              final parsed = format.parse(
                                                  clockOutController.text);
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
                                      icon: const Icon(Icons.calendar_month),
                                      tooltip: 'Set to now',
                                      onPressed: () {
                                        final now = TimeOfDay.now();
                                        clockOutController.text =
                                            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
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
                                      selectedValue:
                                          breakDurationController.text,
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
                                      selectedValue:
                                          breakDurationController.text,
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
                                      selectedValue:
                                          breakDurationController.text,
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
                                      selectedValue:
                                          breakDurationController.text,
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
                                        borderRadius:
                                            BorderRadius.circular(12)),
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
                                  onPressed: () async {
                                    if (formKey.currentState!.validate()) {
                                      final checkInTime =
                                          _parseTime(clockInController.text);
                                      final checkOutTime =
                                          _parseTime(clockOutController.text);
                                      final Duration totalDuration =
                                          checkOutTime.difference(checkInTime);
                                      final double totalHours =
                                          totalDuration.inMinutes / 60.0;
                                      final entry = {
                                        'date': DateTime.now(),
                                        'checkIn': clockInController.text,
                                        'checkOut': clockOutController.text,
                                        'totalHours': totalHours,
                                        'status': 'Pending',
                                        'breakDuration':
                                            breakDurationController.text,
                                      };
                                      await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Success'),
                                          content: const Text(
                                              'Timesheet entry saved!'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                      Navigator.pop(context, entry);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity,
                                        54), // Slightly taller button
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor:
                                        theme.colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            12)), // Rounded corners
                                    elevation: 3, // Add slight elevation
                                  ),
                                  child: const Text('Save Entry',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight.bold)), // Bold text
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ).then((entry) {
                  if (entry != null) {
                    setState(() {
                      // Removed: _mockTimesheetData.add(entry);
                    });
                  }
                });
              },
              backgroundColor: theme.primaryColor,
              icon: const Icon(Icons.add, color: Colors.white), // White icon
              label: const Text('Add Entry',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)), // White and bold text
            )
          : null,
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
  const _SummaryTile({required String? label, required String? value})
      : label = label ?? '',
        value = value ?? '';
  @override
  Widget build(BuildContext context) {
    return Flexible(
      // Wrap Column with Flexible
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          Flexible(
            // Make text flexible
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
          Flexible(
            // Make text flexible
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

  String formatTime(String? iso) {
    if (iso == null || iso == '--' || iso.isEmpty) return '--';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '--';
    return DateFormat('hh:mm a').format(dt);
  }

  String formatBreak(dynamic breakVal) {
    if (breakVal == null) return '--';
    int breakInt = 0;
    if (breakVal is int) breakInt = breakVal;
    if (breakVal is String) breakInt = int.tryParse(breakVal) ?? 0;
    final hours = breakInt ~/ 60;
    final minutes = breakInt % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkInRaw = entry['checkIn']?.toString() ?? '--';
    final checkOutRaw = entry['checkOut']?.toString() ?? '--';
    final inTime = formatTime(checkInRaw);
    final outTime = formatTime(checkOutRaw);
    final breakDuration = entry['breakDuration']?.toString() ??
        entry['totalBreakDuration']?.toString() ??
        '--';
    final breakStr = formatBreak(breakDuration);
    final status = entry['status']?.toString() ?? 'Pending';
    final totalHours = entry['totalHours']?.toString() ??
        (() {
          if (entry['checkIn'] != null &&
              entry['checkOut'] != null &&
              entry['checkOut'] != 'null' &&
              entry['checkIn'] != 'null') {
            try {
              final inTime = DateTime.tryParse(entry['checkIn'].toString());
              final outTime = DateTime.tryParse(entry['checkOut'].toString());
              if (inTime != null && outTime != null) {
                return ((outTime.difference(inTime).inMinutes) / 60.0)
                    .toStringAsFixed(2);
              }
            } catch (_) {}
          }
          return '0.0';
        })();
    DateTime? date;
    try {
      if (entry['date'] is DateTime) {
        date = entry['date'];
      } else if (entry['date'] is String) {
        date = DateTime.tryParse(entry['date']);
      } else if (entry['checkIn'] is String) {
        date = DateTime.tryParse(entry['checkIn']);
      }
    } catch (_) {}
    final dateText = date != null ? '${date.day}/${date.month}' : '--';
    final weekdayText = date != null ? _weekday(date.weekday) : '--';
    final statusColor = _getStatusColor(status);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  weekdayText,
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
                      Flexible(
                        child: Text('In:',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(inTime,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.logout,
                          size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text('Out:',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(outTime,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.free_breakfast,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text('Break:',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(breakStr,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.timer, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text('Total:',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text('$totalHours hrs',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis),
                      ),
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
                Text(status,
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
    return days[(weekday - 1).clamp(0, 6)];
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
