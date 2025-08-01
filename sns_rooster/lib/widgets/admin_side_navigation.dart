﻿import 'package:flutter/material.dart';
import 'package:sns_rooster/utils/logger.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/feature_provider.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/employee_management_screen.dart';
import '../screens/admin/payroll_management_screen.dart';
import '../screens/admin/leave_management_screen.dart';
import '../screens/admin/notification_alert_screen.dart';
import '../screens/admin/settings_screen.dart';
import '../screens/admin/help_support_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/admin_timesheet_screen.dart';
import '../screens/admin/attendance_management_screen.dart';
import '../screens/admin/break_management_screen.dart';
import '../screens/admin/break_types_screen.dart';
import '../screens/admin/analytics_reports_screen.dart';
import '../screens/admin/admin_profile_screen.dart';
import '../screens/admin/admin_attendance_screen.dart';
import '../screens/admin/event_management_screen.dart';
import '../screens/admin/performance_reviews_screen.dart';
import '../screens/admin/timesheet_approval_screen.dart';
import '../widgets/user_avatar.dart';
import 'package:sns_rooster/main.dart'; // Re-added import for navigatorKey
import '../screens/admin/company_settings_screen.dart';
import '../screens/admin/feature_management_screen.dart';
import '../screens/admin/advanced_reporting_screen.dart';
import '../screens/admin/location_management_screen.dart';
import '../screens/admin/expense_management_screen.dart';

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
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final featureProvider =
        Provider.of<FeatureProvider>(context, listen: false);

    return Drawer(
      child: Column(
        children: [
          // User profile section
          Container(
            color: colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Row(
              children: [
                UserAvatar(
                  avatarUrl:
                      profileProvider.profile?['avatar'] ?? user?['avatar'],
                  radius: 28,
                  userId: user?['_id'],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?['name'] ?? 'Administrator',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?['email'] ?? 'admin@company.com',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 🔥 HIGH FREQUENCY - Daily/Weekly Use
                _SidebarSectionHeader('Frequently Used'),
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: '/admin_dashboard',
                  screen: const AdminDashboardScreen(),
                  colorScheme: colorScheme,
                ),
                // Only show Employee Management if the feature is enabled
                if (featureProvider.hasEmployeeManagement)
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
                  icon: Icons.beach_access,
                  title: 'Leave Management',
                  route: '/leave_management',
                  screen: const LeaveManagementScreen(),
                  colorScheme: colorScheme,
                ),
                // Only show Payroll Management if the feature is enabled
                if (featureProvider.hasPayroll)
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

                const SizedBox(height: 8),

                // 📊 MEDIUM FREQUENCY - Weekly/Monthly Use
                _SidebarSectionHeader('Monitoring & Reports'),
                // Only show Attendance Management if the feature is enabled
                if (featureProvider.hasAttendanceManagement)
                  _buildDrawerItem(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Attendance Management',
                    route: '/attendance_management',
                    screen: const AttendanceManagementScreen(),
                    colorScheme: colorScheme,
                  ),
                // Only show Notifications & Alerts if the feature is enabled
                if (featureProvider.hasNotifications)
                  _buildDrawerItem(
                    context,
                    icon: Icons.notifications,
                    title: 'Notifications & Alerts',
                    route: '/notification_alert',
                    screen: const NotificationAlertScreen(),
                    colorScheme: colorScheme,
                  ),
                // Only show Analytics & Reports if the feature is enabled
                if (featureProvider.hasAnalytics)
                  _buildDrawerItem(
                    context,
                    icon: Icons.analytics,
                    title: 'Analytics & Reports',
                    route: '/analytics',
                    screen: const AdminAnalyticsScreen(),
                    colorScheme: colorScheme,
                  ),
                // Only show Event Management if the feature is enabled
                if (featureProvider.hasEvents)
                  _buildDrawerItem(
                    context,
                    icon: Icons.event,
                    title: 'Event Management',
                    route: '/event_management',
                    screen: const EventManagementScreen(),
                    colorScheme: colorScheme,
                  ),
                // Only show Performance Reviews if the feature is enabled
                if (featureProvider.hasPerformanceReviews)
                  _buildDrawerItem(
                    context,
                    icon: Icons.assessment,
                    title: 'Performance Reviews',
                    route: '/performance_reviews',
                    screen: const PerformanceReviewsScreen(),
                    colorScheme: colorScheme,
                  ),
                // Only show Timesheet Approvals if the feature is enabled
                if (featureProvider.hasTimesheetApprovals)
                  _buildDrawerItem(
                    context,
                    icon: Icons.approval,
                    title: 'Timesheet Approvals',
                    route: '/timesheet_approval',
                    screen: const TimesheetApprovalScreen(),
                    colorScheme: colorScheme,
                  ),

                const SizedBox(height: 8),

                // ⚙️ LOW FREQUENCY - Monthly/As Needed
                _SidebarSectionHeader('Configuration'),
                // Only show Break Management if the feature is enabled
                if (featureProvider.hasBreakManagement)
                  _buildDrawerItem(
                    context,
                    icon: Icons.coffee,
                    title: 'Break Management',
                    route: '/break_management',
                    screen: const BreakManagementScreen(),
                    colorScheme: colorScheme,
                  ),
                // Only show Break Types if the feature is enabled
                if (featureProvider.hasBreakTypes)
                  _buildDrawerItem(
                    context,
                    icon: Icons.category,
                    title: 'Break Types',
                    route: '/break_types',
                    screen: const BreakTypesScreen(),
                    colorScheme: colorScheme,
                  ),
                // Only show User Management if the feature is enabled
                if (featureProvider.hasUserManagement)
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_add,
                    title: 'User Management',
                    route: '/user_management',
                    screen: const UserManagementScreen(),
                    colorScheme: colorScheme,
                  ),
                // Only show Settings if the feature is enabled
                if (featureProvider.hasSettings)
                  _buildDrawerItem(
                    context,
                    icon: Icons.settings,
                    title: 'Settings',
                    route: '/admin_settings',
                    screen: const SettingsScreen(),
                    colorScheme: colorScheme,
                  ),
                // Only show Company Settings if the feature is enabled
                if (featureProvider.hasCompanySettings)
                  _buildDrawerItem(
                    context,
                    icon: Icons.business,
                    title: 'Company Settings',
                    route: '/admin/company_settings',
                    screen: const CompanySettingsScreen(),
                    colorScheme: colorScheme,
                  ),
                // Only show Feature Management if the feature is enabled
                if (featureProvider.hasFeatureManagement)
                  _buildDrawerItem(
                    context,
                    icon: Icons.featured_play_list,
                    title: 'Feature Management',
                    route: '/admin/feature_management',
                    screen: const FeatureManagementScreen(),
                    colorScheme: colorScheme,
                  ),
                // Only show Advanced Reporting if the feature is enabled
                if (featureProvider.hasAdvancedReporting)
                  _buildDrawerItem(
                    context,
                    icon: Icons.assessment,
                    title: 'Advanced Reporting',
                    route: '/advanced-reporting',
                    screen: const AdvancedReportingScreen(),
                    colorScheme: colorScheme,
                  ),

                // 🏢 ENTERPRISE FEATURES
                if (featureProvider.hasMultiLocation)
                  _buildDrawerItem(
                    context,
                    icon: Icons.location_on,
                    title: 'Location Management',
                    route: '/location_management',
                    screen: const LocationManagementScreen(),
                    colorScheme: colorScheme,
                  ),
                if (featureProvider.hasExpenseManagement)
                  _buildDrawerItem(
                    context,
                    icon: Icons.receipt_long,
                    title: 'Expense Management',
                    route: '/expense_management',
                    screen: const ExpenseManagementScreen(),
                    colorScheme: colorScheme,
                  ),

                const SizedBox(height: 8),

                // 👤 PERSONAL - As Needed
                _SidebarSectionHeader('Personal'),
                _buildDrawerItem(
                  context,
                  icon: Icons.account_circle,
                  title: 'My Profile',
                  route: '/admin_profile',
                  screen: const AdminProfileScreen(),
                  colorScheme: colorScheme,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.access_time,
                  title: 'My Attendance',
                  route: '/admin_attendance',
                  screen: const AdminAttendanceScreen(),
                  colorScheme: colorScheme,
                ),

                const SizedBox(height: 8),

                // 🆘 SUPPORT
                _SidebarSectionHeader('Support'),
                // Only show Help & Support if the feature is enabled
                if (featureProvider.hasHelpSupport)
                  _buildDrawerItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    route: '/help_support',
                    screen: const HelpSupportScreen(),
                    colorScheme: colorScheme,
                  ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              route: '/logout',
              onTap: () => _handleLogout(context),
              colorScheme: colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _SidebarSectionHeader(String title) {
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: isSelected
          ? BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color: colorScheme.primary,
                  width: 4,
                ),
              ),
            )
          : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          size: 26,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap ??
            () {
              if (!isSelected && screen != null) {
                Navigator.of(context).pop();
                Navigator.of(navigatorKey.currentContext!).pushReplacement(
                  MaterialPageRoute(builder: (context) => screen),
                );
              }
            },
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        minLeadingWidth: 0,
        horizontalTitleGap: 12,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.pop(context);
    log('LOGOUT: Initiating logout process');

    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              log('DIALOG: Cancel button clicked');
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              log('DIALOG: Logout button clicked');
              Navigator.pop(context, true);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    log('LOGOUT: shouldLogout value: $shouldLogout');

    if (shouldLogout != null && shouldLogout) {
      log('LOGOUT: User confirmed logout');

      await Future.delayed(const Duration(milliseconds: 100)); // Add delay

      if (navigatorKey.currentContext != null) {
        log('LOGOUT: Navigator context is available');

        // Show loading indicator
        showDialog(
          context: navigatorKey.currentContext!,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Perform logout
        final authProvider = Provider.of<AuthProvider>(
            navigatorKey.currentContext!,
            listen: false);
        await authProvider.logout();

        if (navigatorKey.currentContext != null) {
          Navigator.pushNamedAndRemoveUntil(
            navigatorKey.currentContext!,
            '/login',
            (route) => false,
          );
        } else {
          // Fallback navigation
          navigatorKey.currentState
              ?.pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } else {
        // Fallback navigation
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState
              ?.pushNamedAndRemoveUntil('/login', (route) => false);
        } else {
          // Final fallback: Use a direct MaterialPageRoute
          // runApp(MaterialApp(
          //   home: const LoginScreen(),
          // ));
          // log('LOGOUT: Used direct MaterialPageRoute for fallback navigation');
        }
      }
    } else {
      log('LOGOUT: User canceled logout');
    }
  }
}
