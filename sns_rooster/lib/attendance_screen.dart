import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
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
                  title: Text('Clock In'),
                  subtitle: Text('2023-10-26 09:00 AM'),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
                ListTile(
                  title: Text('Clock Out'),
                  subtitle: Text('2023-10-26 05:00 PM'),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
                ListTile(
                  title: Text('Clock In'),
                  subtitle: Text('2023-10-25 09:00 AM'),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
                ListTile(
                  title: Text('Clock Out'),
                  subtitle: Text('2023-10-25 05:00 PM'),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
