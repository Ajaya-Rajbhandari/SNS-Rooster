import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../utils/logger.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = packageInfo;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading package info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  Future<void> _launchEmail(String email, String subject) async {
    final uri = Uri.parse('mailto:$email?subject=$subject');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // App Icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.schedule,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // App Name
                          Text(
                            'SNS Rooster HR',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // App Tagline
                          Text(
                            'Complete HR Management System',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Version Info
                          if (_packageInfo != null) ...[
                            Text(
                              'Version ${_packageInfo!.version} (${_packageInfo!.buildNumber})',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Build: ${_packageInfo!.packageName}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Company Information
                  Text(
                    'Company Information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.business,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SNS Tech Services',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text('Professional HR Solutions'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Company Details
                          _buildInfoRow('Website', 'snstechservices.com.au',
                              () {
                            _launchUrl('https://snstechservices.com.au');
                          }),
                          _buildInfoRow(
                              'Email', 'support@snstechservices.com.au', () {
                            _launchEmail('support@snstechservices.com.au',
                                'SNS Rooster HR Support');
                          }),
                          _buildInfoRow(
                              'Privacy', 'privacy@snstechservices.com.au', () {
                            _launchEmail('privacy@snstechservices.com.au',
                                'Privacy Question - SNS Rooster HR');
                          }),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Features
                  Text(
                    'Key Features',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildFeatureRow(
                              Icons.location_on, 'GPS Attendance Tracking'),
                          _buildFeatureRow(
                              Icons.access_time, 'Timesheet Management'),
                          _buildFeatureRow(
                              Icons.calendar_today, 'Leave Management'),
                          _buildFeatureRow(
                              Icons.monetization_on, 'Payroll Processing'),
                          _buildFeatureRow(
                              Icons.analytics, 'Analytics & Reporting'),
                          _buildFeatureRow(
                              Icons.notifications, 'Real-time Notifications'),
                          _buildFeatureRow(
                              Icons.security, 'Secure Data Protection'),
                          _buildFeatureRow(
                              Icons.devices, 'Cross-platform Access'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Legal & Support
                  Text(
                    'Legal & Support',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.privacy_tip),
                          title: const Text('Privacy Policy'),
                          subtitle: const Text('How we protect your data'),
                          onTap: () => _launchUrl(
                              'https://snstechservices.com.au/privacy'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.description),
                          title: const Text('Terms of Service'),
                          subtitle:
                              const Text('App usage terms and conditions'),
                          onTap: () => _launchUrl(
                              'https://snstechservices.com.au/terms'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text('Help & Support'),
                          subtitle: const Text('Get help and contact support'),
                          onTap: () => _launchUrl(
                              'https://snstechservices.com.au/support'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.bug_report),
                          title: const Text('Report an Issue'),
                          subtitle: const Text('Report bugs or problems'),
                          onTap: () => _launchEmail(
                              'support@snstechservices.com.au',
                              'Bug Report - SNS Rooster HR'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Technical Information
                  Text(
                    'Technical Information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTechInfoRow('Platform', 'Flutter'),
                          _buildTechInfoRow('Backend', 'Node.js / Express'),
                          _buildTechInfoRow('Database', 'MongoDB'),
                          _buildTechInfoRow('Cloud Hosting', 'Render.com'),
                          _buildTechInfoRow('Authentication', 'JWT'),
                          _buildTechInfoRow('Maps', 'Google Maps API'),
                          _buildTechInfoRow(
                              'Notifications', 'Firebase Cloud Messaging'),
                          _buildTechInfoRow(
                              'Security', 'HTTPS / SSL Encryption'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Copyright
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '© 2024 SNS Tech Services',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All rights reserved',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Made with ❤️ in Australia',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Store Links
                  Text(
                    'Download Mobile App',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            leading:
                                const Icon(Icons.android, color: Colors.green),
                            title: const Text('Android App'),
                            subtitle:
                                const Text('Download for Android devices'),
                            onTap: () => _launchUrl(
                                'https://sns-rooster.onrender.com/api/app/download/android/file'),
                            trailing: const Icon(Icons.download),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'iOS version coming soon!',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
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

  Widget _buildInfoRow(String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(feature),
          ),
        ],
      ),
    );
  }

  Widget _buildTechInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
