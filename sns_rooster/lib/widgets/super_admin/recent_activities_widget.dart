import 'package:flutter/material.dart';

class RecentActivitiesWidget extends StatelessWidget {
  const RecentActivitiesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock data for recent activities
    final activities = [
      {
        'type': 'company_created',
        'title': 'New Company Created',
        'description': 'TechCorp Inc. was created by Super Admin',
        'time': '2 hours ago',
        'icon': Icons.add_business,
        'color': Colors.green,
      },
      {
        'type': 'user_registered',
        'title': 'New User Registration',
        'description': 'john.doe@techcorp.com registered as admin',
        'time': '4 hours ago',
        'icon': Icons.person_add,
        'color': Colors.blue,
      },
      {
        'type': 'subscription_updated',
        'title': 'Subscription Plan Updated',
        'description': 'Professional plan features were modified',
        'time': '6 hours ago',
        'icon': Icons.subscriptions,
        'color': Colors.orange,
      },
      {
        'type': 'system_backup',
        'title': 'System Backup Completed',
        'description': 'Daily backup completed successfully',
        'time': '8 hours ago',
        'icon': Icons.backup,
        'color': Colors.purple,
      },
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Colors.indigo[800],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Activities',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[800],
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full activity log
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Activity Log - Coming Soon')),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _buildActivityItem(context, activity);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      BuildContext context, Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activity['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              activity['icon'],
              color: activity['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['description'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['time'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
