import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_avatar.dart'; // Assuming UserAvatar is a reusable widget

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
        Navigator.pop(context); // Close the drawer
        // For dashboard, use employee_dashboard route instead of '/'
        final targetRoute =
            route == '/' && !isAdmin ? '/employee_dashboard' : route;
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
      child: ListView(
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
                  avatarUrl: user?['avatar'],
                  radius: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  user?['name'] ?? 'Guest',
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
              icon: Icons.access_time, label: 'Timesheet', route: '/timesheet'),
          _buildNavTile(context,
              icon: Icons.calendar_today,
              label: 'Leave',
              route: '/leave_request'),
          _buildNavTile(context,
              icon: Icons.check_circle_outline,
              label: 'Attendance',
              route: '/attendance'),
          _buildNavTile(context,
              icon: Icons.monetization_on, label: 'Payroll', route: '/payroll'),
          _buildNavTile(context,
              icon: Icons.analytics,
              label: 'Analytics & Reports',
              route: '/analytics'),
          _buildNavTile(context,
              icon: Icons.person_outline, label: 'Profile', route: '/profile'),
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
            onTap: () => authProvider.logout(),
          ),
        ],
      ),
    );
  }
}
