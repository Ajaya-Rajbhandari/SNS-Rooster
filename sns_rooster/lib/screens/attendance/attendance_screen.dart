import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 10, // Example: Replace with actual attendance data count
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text('Date: 2025-06-${index + 1}'),
              subtitle: Text('Status: ${index % 2 == 0 ? 'Present' : 'Absent'}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to detailed attendance view
              },
            ),
          );
        },
      ),
    );
  }
}
