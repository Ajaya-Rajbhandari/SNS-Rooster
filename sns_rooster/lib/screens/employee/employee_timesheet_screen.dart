import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/app_drawer.dart';

class EmployeeTimesheetScreen extends StatefulWidget {
  const EmployeeTimesheetScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeTimesheetScreen> createState() =>
      _EmployeeTimesheetScreenState();
}

class _EmployeeTimesheetScreenState extends State<EmployeeTimesheetScreen> {
  // Real state with provider integration
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 14)),
    end: DateTime.now(),
  );
  String _filter = 'All';
  String _view = 'List';

  @override
  void initState() {
    super.initState();
    // Fetch attendance data for current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      if (authProvider.user != null) {
        final userId = authProvider.user!['_id']?.toString() ??
            authProvider.user!['id']?.toString();
        if (userId != null) {
          attendanceProvider.fetchUserAttendance(userId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timesheet'),
      ),
      drawer: const AppDrawer(),
      body: Consumer<AttendanceProvider>(
        builder: (context, attendanceProvider, _) {
          if (attendanceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (attendanceProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading timesheet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    attendanceProvider.error!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      final userId = authProvider.user!['_id']?.toString() ??
                          authProvider.user!['id']?.toString();
                      if (userId != null) {
                        attendanceProvider.fetchUserAttendance(userId);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final attendanceData = attendanceProvider.attendanceRecords;
          final filteredData = _getFilteredData(attendanceData);

          return SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DateRangeSelector(
                    dateRange: _dateRange,
                    onChange: (range) => setState(() => _dateRange = range),
                  ),
                  const SizedBox(height: 18),
                  _SummaryCard(data: filteredData),
                  const SizedBox(height: 18),
                  _WeeklySummaryCard(data: filteredData),
                  const SizedBox(height: 18),
                  _FilterAndViewToggle(
                    filter: _filter,
                    view: _view,
                    onFilterChanged: (f) => setState(() => _filter = f),
                    onViewChanged: (v) => setState(() => _view = v),
                  ),
                  const SizedBox(height: 18),
                  _TimesheetEntriesList(
                    view: _view,
                    filter: _filter,
                    data: filteredData,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredData(List<Map<String, dynamic>> data) {
    // Filter by date range
    final filteredByDate = data.where((entry) {
      final entryDate = DateTime.tryParse(entry['date']?.toString() ?? '');
      if (entryDate == null) return false;
      return entryDate
              .isAfter(_dateRange.start.subtract(const Duration(days: 1))) &&
          entryDate.isBefore(_dateRange.end.add(const Duration(days: 1)));
    }).toList();

    // Filter by status
    if (_filter != 'All') {
      return filteredByDate.where((entry) {
        final status = entry['status']?.toString() ?? '';
        return status.toLowerCase() == _filter.toLowerCase();
      }).toList();
    }

    return filteredByDate;
  }
}

class _DateRangeSelector extends StatelessWidget {
  final DateTimeRange dateRange;
  final ValueChanged<DateTimeRange> onChange;
  const _DateRangeSelector({required this.dateRange, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue, size: 22),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('MMM dd, yyyy').format(dateRange.start)} - ${DateFormat('MMM dd, yyyy').format(dateRange.end)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.edit_calendar, size: 18),
                  label: const Text('Change'),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: dateRange,
                    );
                    if (picked != null) onChange(picked);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Select a date range to view your timesheet entries.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: [
                _QuickFilterButton(label: 'This Month', onTap: () {/*...*/}),
                _QuickFilterButton(label: 'This Week', onTap: () {/*...*/}),
                _QuickFilterButton(label: 'All Time', onTap: () {/*...*/}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickFilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickFilterButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        side: const BorderSide(color: Colors.blueAccent),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // Calculate summary from real data
    double totalHours = 0;
    int presentCount = 0;
    int absentCount = 0;
    double overtimeHours = 0;

    for (final entry in data) {
      final checkInTime = entry['checkInTime'];
      final checkOutTime = entry['checkOutTime'];

      if (checkInTime != null && checkOutTime != null) {
        final checkIn = DateTime.tryParse(checkInTime.toString());
        final checkOut = DateTime.tryParse(checkOutTime.toString());

        if (checkIn != null && checkOut != null) {
          final hours = checkOut.difference(checkIn).inMinutes / 60.0;
          totalHours += hours;

          if (hours > 0) {
            presentCount++;
            if (hours > 8) {
              // Assuming 8 hours is standard work day
              overtimeHours += (hours - 8);
            }
          }
        }
      } else if (checkInTime != null) {
        presentCount++;
      } else {
        absentCount++;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SummaryItem(
                label: 'Total Hours',
                value: '${totalHours.toStringAsFixed(1)} hrs'),
            _SummaryItem(label: 'Present', value: presentCount.toString()),
            _SummaryItem(label: 'Absent', value: absentCount.toString()),
            _SummaryItem(
                label: 'Overtime',
                value: '${overtimeHours.toStringAsFixed(1)} hrs'),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});
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
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _WeeklySummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // Calculate weekly hours from real data
    double weeklyHours = 0;

    for (final entry in data) {
      final checkInTime = entry['checkInTime'];
      final checkOutTime = entry['checkOutTime'];

      if (checkInTime != null && checkOutTime != null) {
        final checkIn = DateTime.tryParse(checkInTime.toString());
        final checkOut = DateTime.tryParse(checkOutTime.toString());

        if (checkIn != null && checkOut != null) {
          final hours = checkOut.difference(checkIn).inMinutes / 60.0;
          weeklyHours += hours;
        }
      }
    }

    // Get the week range for display
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Week of ${DateFormat('MMM d').format(weekStart)}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text('${weeklyHours.toStringAsFixed(1)} hrs',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}

class _FilterAndViewToggle extends StatelessWidget {
  final String filter;
  final String view;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onViewChanged;
  const _FilterAndViewToggle(
      {required this.filter,
      required this.view,
      required this.onFilterChanged,
      required this.onViewChanged});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            children: [
              _FilterButton(
                  label: 'All',
                  selected: filter == 'All',
                  onTap: () => onFilterChanged('All')),
              _FilterButton(
                  label: 'Approved',
                  selected: filter == 'Approved',
                  onTap: () => onFilterChanged('Approved')),
              _FilterButton(
                  label: 'Pending',
                  selected: filter == 'Pending',
                  onTap: () => onFilterChanged('Pending')),
              _FilterButton(
                  label: 'Rejected',
                  selected: filter == 'Rejected',
                  onTap: () => onFilterChanged('Rejected')),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ToggleButtons(
          borderRadius: BorderRadius.circular(8),
          isSelected: [view == 'List', view == 'Daily'],
          onPressed: (idx) => onViewChanged(idx == 0 ? 'List' : 'Daily'),
          children: const [
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('List View')),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Daily View')),
          ],
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterButton(
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Filter: $label',
      button: true,
      child: Tooltip(
        message: 'Filter by $label',
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: Colors.blue.shade100,
          backgroundColor: Colors.grey.shade100,
          labelStyle: TextStyle(color: selected ? Colors.blue : Colors.black87),
        ),
      ),
    );
  }
}

class _TimesheetEntriesList extends StatelessWidget {
  final String view;
  final String filter;
  final List<Map<String, dynamic>> data;

  const _TimesheetEntriesList({
    required this.view,
    required this.filter,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No timesheet entries found for this period.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Convert backend data to display format
    final entries = data.map((entry) {
      final date = DateTime.tryParse(entry['date']?.toString() ?? '');
      final checkInTime = entry['checkInTime'];
      final checkOutTime = entry['checkOutTime'];
      final totalBreakDuration = entry['totalBreakDuration'] ?? 0;
      final status = entry['status']?.toString() ?? 'Pending';

      // Format times
      String inTime = '--';
      String outTime = '--';
      String totalHours = '0.0 hrs';

      if (checkInTime != null) {
        final checkIn = DateTime.tryParse(checkInTime.toString());
        if (checkIn != null) {
          inTime = DateFormat('HH:mm').format(checkIn.toLocal());
        }
      }

      if (checkOutTime != null) {
        final checkOut = DateTime.tryParse(checkOutTime.toString());
        if (checkOut != null) {
          outTime = DateFormat('HH:mm').format(checkOut.toLocal());

          // Calculate total hours
          final checkIn = DateTime.tryParse(checkInTime.toString());
          if (checkIn != null) {
            final hours = checkOut.difference(checkIn).inMinutes / 60.0;
            totalHours = '${hours.toStringAsFixed(1)} hrs';
          }
        }
      }

      // Format break duration
      final breakMinutes = (totalBreakDuration / (1000 * 60)).round();
      final breakStr = breakMinutes > 0 ? '${breakMinutes}m' : '0m';

      return {
        'date': date ?? DateTime.now(),
        'in': inTime,
        'out': outTime,
        'break': breakStr,
        'total': totalHours,
        'status': status,
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children:
          entries.map((entry) => _TimesheetEntryCard(entry: entry)).toList(),
    );
  }
}

class _TimesheetEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _TimesheetEntryCard({required this.entry});
  @override
  Widget build(BuildContext context) {
    final statusColor = entry['status'] == 'Approved'
        ? Colors.green
        : entry['status'] == 'Pending'
            ? Colors.orange
            : Colors.red;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('d/M').format(entry['date']),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(DateFormat('EEE').format(entry['date']),
                    style: Theme.of(context).textTheme.bodySmall),
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
                      Text('Clock In:',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Text(entry['in'],
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.logout,
                          size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text('Clock Out:',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Text(entry['out'],
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.coffee, size: 18, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('Break:',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Text(entry['break'],
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 18, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text('Total:',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Text(entry['total'],
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Icon(Icons.circle, color: statusColor, size: 14),
                const SizedBox(height: 4),
                Text(entry['status'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
