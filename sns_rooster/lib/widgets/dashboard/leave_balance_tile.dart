import 'package:flutter/material.dart';

class LeaveBalanceTile extends StatelessWidget {
  final String type;
  final int days;
  final Color color;

  const LeaveBalanceTile({
    required this.type,
    required this.days,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text('$days', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(type, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
