import 'package:flutter/material.dart';

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timesheet')),
      body: Column(
        children: [
          CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            onDateChanged: (newDate) {
              setState(() {
                _selectedDate = newDate;
              });
            },
          ),
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  title: Text('Work Entry 1'),
                  subtitle: Text('9:00 AM - 5:00 PM'),
                  trailing: Text('8 hours'),
                ),
                ListTile(
                  title: Text('Work Entry 2'),
                  subtitle: Text('9:00 AM - 1:00 PM'),
                  trailing: Text('4 hours'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
