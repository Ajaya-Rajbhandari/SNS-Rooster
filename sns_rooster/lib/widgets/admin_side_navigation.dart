import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/employee_management_screen.dart';
import '../screens/admin/payroll_management_screen.dart';
import '../screens/admin/leave_management_screen.dart';
import '../screens/admin/notification_alert_screen.dart';
import '../screens/admin/settings_screen.dart';
import '../screens/admin/help_support_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/admin_overview_screen.dart';
import '../screens/admin/admin_timesheet_screen.dart';
import '../screens/admin/attendance_management_screen.dart';
import '../screens/admin/leave_request_management_screen.dart';

class AdminSideNavigation extends StatelessWidget {
  final String currentRoute;
  
  const AdminSideNavigation({
    Key? key,
    required this.currentRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                Text(
                  'Admin Panel',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: Colors.white),
                ),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final user = authProvider.user;
                    return Text(
                      user?['email'] ?? 'admin@example.com',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.white70),
                    );
                  },
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            route: '/admin_dashboard',
            screen: const AdminDashboardScreen(),
            colorScheme: colorScheme,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.analytics,
            title: 'Overview',
            route: '/admin_overview',
            screen: const AdminOverviewScreen(),
            colorScheme: colorScheme,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.people,
            title: 'Employee Management',
            route: '/employee_management',
            screen: const EmployeeManagementScreen(),
            colorScheme: colorScheme,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.person_add,
            title: 'User Management',
            route: '/user_management',
            screen: const UserManagementScreen(),
            colorScheme: colorScheme,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.payments,
            title: 'Payroll Management',
            route: '/payroll_management',
            screen: const PayrollManagementScreen(),
            colorScheme: colorScheme,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.access_time,
            title: 'Timesheet Management',
            route: '/admin_timesheet',
            screen: const AdminTimesheetScreen(),
            colorScheme: colorScheme,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.calendar_today,
            title: 'Attendance Management',
            route: '/attendance_management',
            screen: const AttendanceManagementScreen(),
            colorScheme: colorScheme,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.beach_access,
            title: 'Leave Management',
            route: '/leave_management',
            screen: const LeaveManagementScreen(),
            colorScheme: colorScheme,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.assignment,
            title: 'Leave Requests',
            route: '/leave_request_management',
            screen: const LeaveRequestManagementScreen(),
            colorScheme: colorScheme,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.notifications,
            title: 'Notifications & Alerts',
            route: '/notification_alert',
            screen: const NotificationAlertScreen(),
            colorScheme: colorScheme,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            route: '/admin_settings',
            screen: const SettingsScreen(),
            colorScheme: colorScheme,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            route: '/help_support',
            screen: const HelpSupportScreen(),
            colorScheme: colorScheme,
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            route: '/logout',
            onTap: () => _handleLogout(context),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    Widget? screen,
    VoidCallback? onTap,
    required ColorScheme colorScheme,
  }) {
    final isSelected = currentRoute == route;
    
    return ListTile(
      leading: Icon(
        icon, 
        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: colorScheme.primary.withOpacity(0.1),
      onTap: onTap ?? () {
        if (!isSelected && screen != null) {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        } else {
          Navigator.pop(context);
        }
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.pop(context);
    
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Perform logout
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }
}