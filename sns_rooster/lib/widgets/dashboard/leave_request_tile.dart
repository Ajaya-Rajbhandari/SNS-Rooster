import 'package:flutter/material.dart';

class LeaveRequestTile extends StatelessWidget {
  final String type;
  final String date;
  final String status;

  const LeaveRequestTile({
    required this.type,
    required this.date,
    required this.status,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (status) {
      case 'Approved':
        statusColor = Colors.green;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.event_note, color: Theme.of(context).primaryColor),
      title: Text('$type Leave'),
      subtitle: Text(date),
      trailing: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
    );
  }
}
