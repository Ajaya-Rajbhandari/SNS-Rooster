import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sns_rooster/widgets/navigation_drawer.dart';

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  DateTime _selectedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String currentDate = DateFormat('EEEE, MMM d, yyyy').format(_selectedDate);

    // Mock timesheet data for the selected week
    final List<Map<String, dynamic>> timesheetData = List.generate(7, (index) {
      final date = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1 - index));
      return {
        'date': date,
        'clockIn': index == 2 ? '--' : '09:${index % 2 == 0 ? '00' : '15'} AM',
        'clockOut': index == 2 ? '--' : '06:00 PM',
        'break': index == 2 ? '--' : '01:00',
        'total': index == 2 ? '--' : '08:00',
        'status': index == 2 ? 'Absent' : (index == 1 ? 'Late' : 'Present'),
      };
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timesheet'),
        backgroundColor: theme.primaryColor,
      ),
      drawer: const AppNavigationDrawer(),
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: theme.primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Date: $currentDate',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'View By:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onBackground,
                      ),
                    ),
                    DropdownButton<CalendarFormat>(
                      value: _calendarFormat,
                      items: const [
                        DropdownMenuItem(
                          value: CalendarFormat.week,
                          child: Text('Week'),
                        ),
                        DropdownMenuItem(
                          value: CalendarFormat.month,
                          child: Text('Month'),
                        ),
                      ],
                      onChanged: (format) {
                        setState(() {
                          _calendarFormat = format!;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: TableCalendar(
              key: ValueKey(_calendarFormat),
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _selectedDate,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: const TextStyle(color: Colors.redAccent),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold) ??
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TimesheetSummary(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('This Week', style: theme.textTheme.titleMedium),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: timesheetData.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => TimesheetRow(entry: timesheetData[index]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Timesheet Entry',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Clock In Time',
                            prefixIcon: Icon(Icons.login),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Clock Out Time',
                            prefixIcon: Icon(Icons.logout),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Break Duration',
                            prefixIcon: Icon(Icons.free_breakfast),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Add logic to save the entry
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: const Text('Save Entry'),
                        ),
                      ],
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

  Widget _buildNavTile(BuildContext context, {required IconData icon, required String label, required String route, Widget? trailing}) {
    final theme = Theme.of(context);
    final isSelected = ModalRoute.of(context)?.settings.name == route;
    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.blueGrey, size: 26),
      title: Text(label, style: TextStyle(
        color: isSelected ? theme.colorScheme.primary : Colors.blueGrey[900],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 16,
      )),
      trailing: trailing,
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () {
        Navigator.pop(context);
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamed(context, route);
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      horizontalTitleGap: 12,
      minLeadingWidth: 0,
    );
  }
}

class TimesheetSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // TODO: Replace with real summary data
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryTile(label: 'Total Hours', value: '40:00'),
            _SummaryTile(label: 'Present', value: '5'),
            _SummaryTile(label: 'Absent', value: '1'),
            _SummaryTile(label: 'Overtime', value: '02:30'),
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
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
      ],
    );
  }
}

class TimesheetRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  const TimesheetRow({required this.entry});

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
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _weekday(entry['date'].weekday),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
                      Icon(Icons.login, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text('In: ${entry['clockIn']}', style: theme.textTheme.bodyMedium),
                      const SizedBox(width: 12),
                      Icon(Icons.logout, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text('Out: ${entry['clockOut']}', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.free_breakfast, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('Break: ${entry['break']}', style: theme.textTheme.bodySmall),
                      const SizedBox(width: 12),
                      Icon(Icons.timer, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text('Total: ${entry['total']}', style: theme.textTheme.bodySmall),
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
                Text(entry['status'], style: theme.textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
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
