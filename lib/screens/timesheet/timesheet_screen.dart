import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class TimesheetScreen extends StatefulWidget {
  // ... (existing code)
}

class _TimesheetScreenState extends State<TimesheetScreen>
    with SingleTickerProviderStateMixin {
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  final clockInController = TextEditingController();
  final clockOutController = TextEditingController();
  final breakDurationController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  String _selectedFilter = 'All';
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (existing code)

    return Scaffold(
      // ... (existing code)

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ... (existing code)

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: clockInController,
                    decoration: InputDecoration(
                      labelText: 'Clock In Time',
                      prefixIcon: const Icon(Icons.login),
                      suffixIcon: const Icon(Icons.watch_later_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                          final parsed = format.parse(clockInController.text);
                          initialTime = TimeOfDay(
                              hour: parsed.hour, minute: parsed.minute);
                        } catch (_) {}
                      }
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: initialTime,
                      );
                      if (pickedTime != null) {
                        clockInController.text = pickedTime.format(context);
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
                TextButton(
                  onPressed: () {
                    final now = TimeOfDay.now();
                    clockInController.text = now.format(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text('Now'),
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
                      suffixIcon: const Icon(Icons.watch_later_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                          final parsed = format.parse(clockOutController.text);
                          initialTime = TimeOfDay(
                              hour: parsed.hour, minute: parsed.minute);
                        } catch (_) {}
                      }
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: initialTime,
                      );
                      if (pickedTime != null) {
                        clockOutController.text = pickedTime.format(context);
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
                TextButton(
                  onPressed: () {
                    final now = TimeOfDay.now();
                    clockOutController.text = now.format(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text('Now'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
