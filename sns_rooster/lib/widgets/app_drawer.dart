import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sns_rooster/utils/logger.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/feature_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/user_avatar.dart'; // Assuming UserAvatar is a reusable widget
import '../../providers/profile_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  /// Extracted navigation logic to a reusable function
  String navigateToRoute(String route, bool isAdmin) {
    return route == '/' && !isAdmin ? '/employee_dashboard' : route;
  }

  Widget _buildNavTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    Widget? trailing,
    bool isAdmin = false, // Add isAdmin parameter to differentiate routes
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge,
      ),
      trailing: trailing,
      onTap: () {
        log('APP_DRAWER: Closing drawer');
        Navigator.pop(context); // Close the drawer
        // For dashboard, use employee_dashboard route instead of '/'
        final targetRoute = navigateToRoute(route, isAdmin);
        log('APP_DRAWER: Navigating to route: $targetRoute');
        Navigator.pushReplacementNamed(context, targetRoute);
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 0, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          fontSize: 13,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final featureProvider = Provider.of<FeatureProvider>(context);
    final theme = Theme.of(context);
    final user = authProvider.user;
    final isAdmin = user?['role'] == 'admin';

    return Drawer(
      child: SizedBox(
        width: 280, // Stronger width constraint for compact drawer
        child: Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            final profile = profileProvider.profile;
            final avatarPath = profile?['avatar'] ?? profile?['profilePicture'];
            var avatarUrl = avatarPath ?? '/uploads/avatars/default-avatar.png';
            log('APP_DRAWER: avatarUrl = $avatarUrl');

            return ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary, // Use theme primary color
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      UserAvatar(
                        avatarUrl: avatarUrl,
                        radius: 36,
                        userId: user?['_id'],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user != null &&
                                user['firstName'] != null &&
                                user['lastName'] != null
                            ? '${user['firstName']} ${user['lastName']}'
                            : 'Guest',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?['role'] ?? '',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // MAIN NAVIGATION SECTION
                _buildSectionHeader('MAIN NAVIGATION'),
                _buildNavTile(context,
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    route: '/',
                    isAdmin: isAdmin),

                // WORK MANAGEMENT SECTION
                _buildSectionHeader('WORK MANAGEMENT'),
                _buildNavTile(context,
                    icon: Icons.access_time,
                    label: 'Timesheet',
                    route: '/timesheet'),
                _buildNavTile(context,
                    icon: Icons.check_circle_outline,
                    label: 'Attendance',
                    route: '/attendance'),
                _buildNavTile(context,
                    icon: Icons.calendar_today,
                    label: 'Leave',
                    route: '/leave_request'),

                // FEATURES SECTION
                if (featureProvider.hasPayroll ||
                    featureProvider.hasAnalytics ||
                    featureProvider.hasEvents ||
                    featureProvider.hasPerformanceReviews ||
                    featureProvider.hasTrainingManagement) ...[
                  _buildSectionHeader('FEATURES'),
                  if (featureProvider.hasPayroll)
                    _buildNavTile(context,
                        icon: Icons.monetization_on,
                        label: 'Payroll',
                        route: '/payroll'),
                  if (featureProvider.hasAnalytics)
                    _buildNavTile(context,
                        icon: Icons.analytics,
                        label: 'Analytics & Reports',
                        route: '/analytics'),
                  if (featureProvider.hasEvents)
                    _buildNavTile(context,
                        icon: Icons.event, label: 'Events', route: '/events'),
                  if (featureProvider.hasPerformanceReviews)
                    _buildNavTile(context,
                        icon: Icons.assessment,
                        label: 'Performance Reviews',
                        route: '/performance_reviews'),
                  if (featureProvider.hasTrainingManagement)
                    _buildNavTile(context,
                        icon: Icons.school,
                        label: 'Training Programs',
                        route: '/training'),
                ],

                // ACCOUNT SECTION
                _buildSectionHeader('ACCOUNT'),
                _buildNavTile(context,
                    icon: Icons.person_outline,
                    label: 'Profile',
                    route: '/profile'),
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, child) {
                    return _buildNavTile(
                      context,
                      icon: Icons.notifications,
                      label: 'Notifications',
                      route: '/notification',
                      trailing: (notificationProvider.unreadCount ?? 0) > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${notificationProvider.unreadCount ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),

                const Divider(),

                // DOWNLOAD SECTION (Web Only)
                if (kIsWeb) ...[
                  _buildSectionHeader('DOWNLOAD'),
                  ListTile(
                    leading:
                        Icon(Icons.android, color: theme.colorScheme.onSurface),
                    title: Text(
                      'Download Android App',
                      style: theme.textTheme.bodyLarge,
                    ),
                    subtitle: const Text(
                      'Get the mobile app for better experience',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.download, size: 16),
                    onTap: () async {
                      Navigator.pop(context); // Close the drawer
                      // Use direct APK download URL with correct file name
                      const downloadUrl =
                          'https://github.com/Ajaya-Rajbhandari/SNS-Rooster/releases/latest/download/sns-rooster-v1.0.14.apk';
                      final uri = Uri.parse(downloadUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  const Divider(),
                ],

                // SETTINGS SECTION
                _buildSectionHeader('SETTINGS'),
                ListTile(
                  leading: Icon(Icons.privacy_tip,
                      color: theme.colorScheme.onSurface),
                  title: Text(
                    'Privacy Settings',
                    style: theme.textTheme.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/privacy-settings');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info_outline,
                      color: theme.colorScheme.onSurface),
                  title: Text(
                    'About',
                    style: theme.textTheme.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/about');
                  },
                ),

                const Divider(),

                // LOGOUT SECTION
                _buildSectionHeader('SESSION'),
                ListTile(
                  leading:
                      Icon(Icons.logout, color: theme.colorScheme.onSurface),
                  title: Text(
                    'Logout',
                    style: theme.textTheme.bodyLarge,
                  ),
                  onTap: () {
                    authProvider.logout();
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                ),
                const Divider(),
              ],
            );
          },
        ),
      ),
    );
  }
}
