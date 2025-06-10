import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('How do I add a new employee?'),
                      subtitle: const Text(
                          'Navigate to Employee Management and click the \'Add Employee\' button.'),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Where can I see payroll reports?'),
                      subtitle: const Text(
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
