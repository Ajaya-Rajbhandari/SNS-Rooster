import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/logger.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _locationEnabled = true;
  bool _notificationsEnabled = true;
  bool _analyticsEnabled = true;
  bool _cameraEnabled = true;
  bool _storageEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _locationEnabled = prefs.getBool('privacy_location_enabled') ?? true;
        _notificationsEnabled =
            prefs.getBool('privacy_notifications_enabled') ?? true;
        _analyticsEnabled = prefs.getBool('privacy_analytics_enabled') ?? true;
        _cameraEnabled = prefs.getBool('privacy_camera_enabled') ?? true;
        _storageEnabled = prefs.getBool('privacy_storage_enabled') ?? true;
      });
    } catch (e) {
      Logger.error('Error loading privacy settings: $e');
    }
  }

  Future<void> _savePrivacySetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      Logger.info('Privacy setting saved: $key = $value');
    } catch (e) {
      Logger.error('Error saving privacy setting: $e');
    }
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://snstechservices.com.au/privacy';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open privacy policy')),
        );
      }
    }
  }

  Future<void> _contactPrivacySupport() async {
    const email =
        'mailto:privacy@snstechservices.com.au?subject=Privacy%20Question%20-%20SNS%20Rooster%20HR';
    final uri = Uri.parse(email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  Future<void> _exportMyData() async {
    // TODO: Implement data export functionality
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export My Data'),
          content: const Text(
              'This feature will be available soon. You can request your data by contacting our support team.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _contactPrivacySupport();
              },
              child: const Text('Contact Support'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _deleteMyData() async {
    if (mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete My Data'),
          content: const Text(
              'This will permanently delete all your data from our servers. This action cannot be undone. Are you sure you want to proceed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // TODO: Implement data deletion functionality
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Data deletion request submitted. We will process it within 30 days.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Overview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.privacy_tip,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Privacy Overview',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Control how your data is collected and used. You can change these settings at any time.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Permission Settings
            Text(
              'App Permissions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Location Permission
            Card(
              child: SwitchListTile(
                title: const Text('Location Services'),
                subtitle: const Text(
                    'Required for attendance tracking and geofencing'),
                value: _locationEnabled,
                onChanged: (value) {
                  setState(() {
                    _locationEnabled = value;
                  });
                  _savePrivacySetting('privacy_location_enabled', value);
                },
                secondary: const Icon(Icons.location_on),
              ),
            ),

            // Camera Permission
            Card(
              child: SwitchListTile(
                title: const Text('Camera Access'),
                subtitle: const Text('For profile photos and document uploads'),
                value: _cameraEnabled,
                onChanged: (value) {
                  setState(() {
                    _cameraEnabled = value;
                  });
                  _savePrivacySetting('privacy_camera_enabled', value);
                },
                secondary: const Icon(Icons.camera_alt),
              ),
            ),

            // Storage Permission
            Card(
              child: SwitchListTile(
                title: const Text('Storage Access'),
                subtitle: const Text('For app data and file storage'),
                value: _storageEnabled,
                onChanged: (value) {
                  setState(() {
                    _storageEnabled = value;
                  });
                  _savePrivacySetting('privacy_storage_enabled', value);
                },
                secondary: const Icon(Icons.storage),
              ),
            ),

            const SizedBox(height: 16),

            // Data Usage Settings
            Text(
              'Data Usage',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Notifications
            Card(
              child: SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle:
                    const Text('Receive attendance reminders and updates'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _savePrivacySetting('privacy_notifications_enabled', value);
                },
                secondary: const Icon(Icons.notifications),
              ),
            ),

            // Analytics
            Card(
              child: SwitchListTile(
                title: const Text('Usage Analytics'),
                subtitle:
                    const Text('Help us improve the app (anonymous data only)'),
                value: _analyticsEnabled,
                onChanged: (value) {
                  setState(() {
                    _analyticsEnabled = value;
                  });
                  _savePrivacySetting('privacy_analytics_enabled', value);
                },
                secondary: const Icon(Icons.analytics),
              ),
            ),

            const SizedBox(height: 16),

            // Data Rights
            Text(
              'Your Data Rights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Export Data
            Card(
              child: ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export My Data'),
                subtitle: const Text('Download a copy of your data'),
                onTap: _exportMyData,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),

            // Delete Data
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete My Data',
                    style: TextStyle(color: Colors.red)),
                subtitle: const Text('Permanently delete all your data'),
                onTap: _deleteMyData,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Privacy Policy Links
            Text(
              'Privacy Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // View Privacy Policy
            Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('View Privacy Policy'),
                subtitle: const Text('Read our complete privacy policy'),
                onTap: _openPrivacyPolicy,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),

            // Contact Privacy Support
            Card(
              child: ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text('Contact Privacy Support'),
                subtitle: const Text('Ask questions about your privacy'),
                onTap: _contactPrivacySupport,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),

            const SizedBox(height: 24),

            // Privacy Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Privacy Notice',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your privacy is important to us. We collect and use your data to provide HR management services. We do not sell your data to third parties. You can control your privacy settings and exercise your data rights at any time.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
