import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/admin_side_navigation.dart';
import '../../providers/admin_settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      drawer: const AdminSideNavigation(currentRoute: '/settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Preferences',
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
                    Consumer<AdminSettingsProvider>(
                      builder: (context, settings, _) {
                        return SwitchListTile(
                          title: const Text('Enable Dark Mode'),
                          value: settings.darkModeEnabled,
                          onChanged: (value) {
                            settings.setDarkModeEnabled(value);
                          },
                        );
                      },
                    ),
                    Consumer<AdminSettingsProvider>(
                      builder: (context, settings, _) {
                        return SwitchListTile(
                          title: const Text('Receive Email Notifications'),
                          value: settings.notificationsEnabled,
                          onChanged: (value) {
                            settings.setNotificationsEnabled(value);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Profile Settings',
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
                      'Control which sections are visible in employee profiles',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<AdminSettingsProvider>(
                      builder: (context, settings, _) {
                        return SwitchListTile(
                          title: const Text('Enable Education Section'),
                          subtitle: const Text(
                              'Allow employees to add education information'),
                          value: settings.educationSectionEnabled,
                          onChanged: (value) {
                            settings.setEducationSectionEnabled(value);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'Education section enabled'
                                      : 'Education section disabled',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Consumer<AdminSettingsProvider>(
                      builder: (context, settings, _) {
                        return SwitchListTile(
                          title: const Text('Enable Certificates Section'),
                          subtitle:
                              const Text('Allow employees to add certificates'),
                          value: settings.certificatesSectionEnabled,
                          onChanged: (value) {
                            settings.setCertificatesSectionEnabled(value);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'Certificates section enabled'
                                      : 'Certificates section disabled',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'System Configuration',
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
                    ListTile(
                      title: const Text('Payroll Cycle Settings'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed('/admin/payroll_cycle_settings');
                      },
                    ),
                    ListTile(
                      title: const Text('Tax Configuration'),
                      subtitle: const Text(
                          'Configure income tax, social security & deductions'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context).pushNamed('/admin/tax_settings');
                      },
                    ),
                    ListTile(
                      title: const Text('Company Information'),
                      subtitle: const Text(
                          'Company details, logo & contact information'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed('/admin/company_settings');
                      },
                    ),
                    ListTile(
                      title: const Text('Leave Policy Settings'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed('/admin/leave_policy_settings');
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
