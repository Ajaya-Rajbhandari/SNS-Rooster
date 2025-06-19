import 'package:flutter/material.dart';

class AttendanceSummaryTile extends StatelessWidget {
  final int totalDays;
  final int presentDays;
  final int absentDays;

  const AttendanceSummaryTile({
    super.key,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Total Days: $totalDays'),
            Text('Present Days: $presentDays'),
            Text('Absent Days: $absentDays'),
          ],
        ),
      ),
    );
  }
}
