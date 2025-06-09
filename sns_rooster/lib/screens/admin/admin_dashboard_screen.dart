import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import 'package:sns_rooster/screens/admin/admin_overview_screen.dart';
import 'package:sns_rooster/screens/admin/employee_management_screen.dart';
import 'package:sns_rooster/screens/admin/admin_settings_screen.dart';
import 'package:sns_rooster/screens/admin/leave_request_management_screen.dart';
import 'package:sns_rooster/screens/admin/add_employee_dialog.dart';
import 'package:sns_rooster/screens/login/login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Admin Dashboard',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: colorScheme.secondary,
            labelColor: colorScheme.onPrimary,
            unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
            tabs: [
              Tab(
                  icon: Icon(Icons.dashboard, color: colorScheme.onPrimary),
                  text: 'Overview'),
              Tab(
                  icon: Icon(Icons.people, color: colorScheme.onPrimary),
                  text: 'Employees'),
              Tab(
                  icon: Icon(Icons.settings, color: colorScheme.onPrimary),
                  text: 'Settings'),
            ],
          ),
        ),
        drawer: Drawer(
          child: Container(
            color: colorScheme.surface,
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primaryContainer
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Text(
                    'Admin Menu',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.assignment,
                  title: 'Manage Leave Requests',
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const LeaveRequestManagementScreen(),
                      ),
                    );
                  },
                  colorScheme: colorScheme,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.bar_chart,
                  title: 'View Reports',
                  onTap: () {
                    // Handle view reports tap
                    Navigator.pop(context); // Close the drawer
                  },
                  colorScheme: colorScheme,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.access_time,
                  title: 'Attendance Records',
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.pushNamed(context, '/attendance_management');
                  },
                  colorScheme: colorScheme,
                ),
                // Add more admin specific options here
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () async {
                    // Close the drawer first
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
                      await Provider.of<AuthProvider>(context, listen: false).logout();
                    }
                  },
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            AdminOverviewScreen(),
            EmployeeManagementScreen(),
            AdminSettingsScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurface),
      title: Text(
        title,
        style: TextStyle(color: colorScheme.onSurface),
      ),
      onTap: onTap,
      selectedTileColor: colorScheme.primary.withOpacity(0.1),
    );
  }
}
