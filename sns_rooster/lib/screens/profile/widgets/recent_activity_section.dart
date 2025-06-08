import 'package:flutter/material.dart';

class RecentActivitySection extends StatelessWidget {
  final List<String> activities;

  const RecentActivitySection({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...activities.map((activity) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text('• \$activity'),
            )),
          ],
        ),
      ),
    );
  }
}
