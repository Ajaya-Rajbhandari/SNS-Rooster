import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/admin_side_navigation.dart';
import '../../providers/admin_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/logger.dart';
import '../../services/fcm_service.dart';
import 'package:flutter/foundation.dart';

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
            const SizedBox(height: 24),
            // Debug Section (only in debug mode)
            if (kDebugMode) ...[
              Text(
                'Debug Tools',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.orange,
                ),
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
                        leading:
                            const Icon(Icons.bug_report, color: Colors.orange),
                        title: const Text('Save FCM Token to Database'),
                        subtitle:
                            const Text('Manually trigger FCM token saving'),
                        trailing: const Icon(Icons.send),
                        onTap: () async {
                          try {
                            final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false);
                            await authProvider.saveFCMTokenManually();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'FCM token save attempted. Check logs for details.'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            }
                          } catch (e) {
                            Logger.error('Error saving FCM token: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.token, color: Colors.green),
                        title: const Text('Test FCM Token Generation'),
                        subtitle:
                            const Text('Manually test FCM token generation'),
                        trailing: const Icon(Icons.refresh),
                        onTap: () async {
                          try {
                            // Import FCMService
                            final fcmService = FCMService();
                            await fcmService.testFCMTokenGeneration();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'FCM token test completed. Check logs for details.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            Logger.error('Error testing FCM token: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
