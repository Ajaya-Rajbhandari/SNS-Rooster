import 'package:flutter/material.dart';
import 'package:sns_rooster/utils/logger.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_avatar.dart'; // Assuming UserAvatar is a reusable widget
import '../../providers/profile_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final user = authProvider.user;
    final isAdmin = user?['role'] == 'admin';

    return Drawer(
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
              _buildNavTile(context,
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  route: '/',
                  isAdmin: isAdmin),
              _buildNavTile(context,
                  icon: Icons.access_time,
                  label: 'Timesheet',
                  route: '/timesheet'),
              _buildNavTile(context,
                  icon: Icons.calendar_today,
                  label: 'Leave',
                  route: '/leave_request'),
              _buildNavTile(context,
                  icon: Icons.check_circle_outline,
                  label: 'Attendance',
                  route: '/attendance'),
              _buildNavTile(context,
                  icon: Icons.monetization_on,
                  label: 'Payroll',
                  route: '/payroll'),
              _buildNavTile(context,
                  icon: Icons.analytics,
                  label: 'Analytics & Reports',
                  route: '/analytics'),
              _buildNavTile(context,
                  icon: Icons.person_outline,
                  label: 'Profile',
                  route: '/profile'),
              _buildNavTile(context,
                  icon: Icons.notifications,
                  label: 'Notifications',
                  route: '/notification'),
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: theme.colorScheme.onSurface),
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
    );
  }
}
