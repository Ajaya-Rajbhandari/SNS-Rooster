import 'package:flutter/material.dart';
import '../../widgets/admin_side_navigation.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      drawer: const AdminSideNavigation(currentRoute: '/leave_management'),
      body: const Center(
        child: Text('Leave management screen will be implemented here.'),
      ),
    );
  }
}
