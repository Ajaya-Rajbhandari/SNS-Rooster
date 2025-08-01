import 'package:flutter/material.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  Icons.flash_on,
                  color: Colors.indigo[800],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[800],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildActionCard(
                  context,
                  'Add Company',
                  Icons.add_business,
                  Colors.green,
                  () {
                    // TODO: Navigate to add company
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Add Company - Coming Soon')),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  'Manage Users',
                  Icons.people,
                  Colors.blue,
                  () {
                    // TODO: Navigate to user management
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('User Management - Coming Soon')),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  'View Analytics',
                  Icons.analytics,
                  Colors.orange,
                  () {
                    // TODO: Navigate to analytics
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Analytics - Coming Soon')),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  'System Settings',
                  Icons.settings,
                  Colors.purple,
                  () {
                    // TODO: Navigate to system settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('System Settings - Coming Soon')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
