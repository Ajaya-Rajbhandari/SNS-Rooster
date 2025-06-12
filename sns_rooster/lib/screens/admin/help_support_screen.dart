import 'package:flutter/material.dart';
import '../../widgets/admin_side_navigation.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      drawer: const AdminSideNavigation(currentRoute: '/help_support'),
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('How do I add a new employee?'),
                      subtitle: Text(
                          'Navigate to Employee Management and click the \'Add Employee\' button.'),
                    ),
                    Divider(),
                    ListTile(
                      title: Text('Where can I see payroll reports?'),
                      subtitle: Text(
                          'Check the Payroll Insights section on the dashboard.'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Contact Support',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'If you need further assistance, please contact us:',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading:
                          Icon(Icons.email, color: theme.colorScheme.primary),
                      title: const Text('support@example.com'),
                      onTap: () {
                        // Implement email launch
                      },
                    ),
                    ListTile(
                      leading:
                          Icon(Icons.phone, color: theme.colorScheme.primary),
                      title: const Text('+1 (123) 456-7890'),
                      onTap: () {
                        // Implement phone call
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
