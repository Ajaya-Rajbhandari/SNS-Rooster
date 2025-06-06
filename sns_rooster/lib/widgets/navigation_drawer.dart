import 'package:flutter/material.dart';

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildNavTile(BuildContext context, {
      required IconData icon,
      required String label,
      required String route,
      Widget? trailing,
    }) {
      final isSelected = ModalRoute.of(context)?.settings.name == route;
      return StatefulBuilder(
        builder: (context, setState) {
          bool isHovered = false;
          return MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            child: Container(
              decoration: BoxDecoration(
                color: isHovered ? theme.colorScheme.primary.withOpacity(0.1) : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: Icon(
                  icon,
                  color: isSelected || isHovered ? theme.colorScheme.primary : Colors.blueGrey,
                  size: 26,
                ),
                title: Text(
                  label,
                  style: TextStyle(
                    color: isSelected || isHovered ? theme.colorScheme.primary : Colors.blueGrey[900],
                    fontWeight: isSelected || isHovered ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                trailing: trailing,
                selected: isSelected,
                onTap: () {
                  Navigator.pop(context);
                  if (ModalRoute.of(context)?.settings.name != route) {
                    Navigator.pushNamed(context, route);
                  }
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                horizontalTitleGap: 12,
                minLeadingWidth: 0,
              ),
            ),
          );
        },
      );
    }

    return Drawer(
      child: Container(
        color: theme.colorScheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'John Doe',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Software Engineer',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            buildNavTile(context, icon: Icons.dashboard, label: 'Dashboard', route: '/'),
            buildNavTile(context, icon: Icons.access_time, label: 'Timesheet', route: '/timesheet'),
            buildNavTile(context, icon: Icons.calendar_today, label: 'Leave', route: '/leave_request'),
            buildNavTile(context, icon: Icons.check_circle_outline, label: 'Attendance', route: '/attendance'),
            buildNavTile(context, icon: Icons.notifications_none, label: 'Notifications', route: '/notification'),
            buildNavTile(context, icon: Icons.person_outline, label: 'Profile', route: '/profile'),
            const Divider(),
            buildNavTile(context, icon: Icons.support_agent, label: 'Support', route: '/support'),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
