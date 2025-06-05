// EmployeeDashboardScreen
// ----------------------
// Main dashboard for employees.
// - Shows user info, live clock, status, quick actions, and attendance summary.
// - All data is dynamic and ready for backend integration.
// - Modular: uses widgets from widgets/dashboard/ and models/services.
//
// To connect to backend, use AttendanceService and Employee model.

import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../widgets/dashboard/leave_balance_tile.dart';
import '../../widgets/dashboard/leave_request_tile.dart';
import '../../widgets/dashboard/dashboard_action_button.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  // Simulated employee (replace with provider or API in production)
  final Employee employee = Employee(
    id: '1',
    name: 'John Doe',
    role: 'Software Engineer',
    avatar: 'assets/images/profile_placeholder.png',
  );

  bool isClockedIn = false;
  bool isOnBreak = false;
  DateTime? lastClockIn;
  DateTime? breakStart;
  Duration totalBreakDuration = Duration.zero;
  late final ValueNotifier<DateTime> _now;
  bool isLoadingClock = false;
  bool isLoadingBreak = false;

  @override
  void initState() {
    super.initState();
    _now = ValueNotifier(DateTime.now());
    // Update clock every second
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      _now.value = DateTime.now();
      return mounted;
    });
  }

  @override
  void dispose() {
    _now.dispose();
    super.dispose();
  }

  void _toggleClockInOut() async {
    if (isLoadingClock) return;
    if (isClockedIn && !isOnBreak) {
      // Show confirmation dialog before clocking out
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Clock Out'),
          content: const Text('Are you sure you want to clock out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clock Out'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    setState(() => isLoadingClock = true);
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate processing
    setState(() {
      if (isClockedIn) {
        // Prevent clock out if on break
        if (isOnBreak) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please end your break before clocking out.'),
              backgroundColor: Colors.orange,
            ),
          );
          isLoadingClock = false;
          return;
        }
        isClockedIn = false;
      } else {
        isClockedIn = true;
        lastClockIn = DateTime.now();
        isOnBreak = false;
      }
      isLoadingClock = false;
    });
  }

  void _toggleBreak() async {
    if (!isClockedIn || isLoadingBreak) return;
    setState(() => isLoadingBreak = true);
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate processing
    setState(() {
      if (!isOnBreak) {
        // Start break
        breakStart = DateTime.now();
      } else {
        // End break and record duration
        if (breakStart != null) {
          totalBreakDuration += DateTime.now().difference(breakStart!);
        }
        breakStart = null;
      }
      isOnBreak = !isOnBreak;
      isLoadingBreak = false;
    });
  }

  String get breakTimeDisplay {
    if (isOnBreak && breakStart != null) {
      final current = DateTime.now().difference(breakStart!) + totalBreakDuration;
      return _formatDuration(current);
    } else {
      return _formatDuration(totalBreakDuration);
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: theme.colorScheme.surface,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: AssetImage(employee.avatar),
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(employee.name, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(employee.role, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
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
              _buildNavTile(context, icon: Icons.dashboard, label: 'Dashboard', route: '/'),
              _buildNavTile(context, icon: Icons.access_time, label: 'Timesheet', route: '/timesheet'),
              _buildNavTile(context, icon: Icons.calendar_today, label: 'Leave', route: '/leave_request'),
              _buildNavTile(context, icon: Icons.check_circle_outline, label: 'Attendance', route: '/attendance'),
              _buildNavTile(context, icon: Icons.notifications_none, label: 'Notifications', route: '/notification', trailing: _buildNotificationDot()),
              _buildNavTile(context, icon: Icons.person_outline, label: 'Profile', route: '/profile'),
              const Divider(),
              _buildNavTile(context, icon: Icons.support_agent, label: 'Support', route: '/support'),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0), // More vertical padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 36, // Slightly larger for easier tap
                          backgroundImage: AssetImage(employee.avatar),
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.verified_user, color: theme.colorScheme.primary, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(employee.name, style: theme.textTheme.titleLarge),
                      Text(employee.role, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                    ],
                  ),
                  const Spacer(),
                  ValueListenableBuilder<DateTime>(
                    valueListenable: _now,
                    builder: (context, now, _) {
                      return Row(
                        children: [
                          Icon(Icons.access_time, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            TimeOfDay.fromDateTime(now).format(context),
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 22),
              // Status, Clock In/Out, Break
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status:', style: theme.textTheme.titleMedium),
                  Row(
                    children: [
                      Icon(
                        isClockedIn ? (isOnBreak ? Icons.free_breakfast : Icons.circle) : Icons.circle,
                        color: isClockedIn ? (isOnBreak ? Colors.orange : Colors.green) : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isClockedIn ? (isOnBreak ? 'On Break' : 'On Duty') : 'Clocked Out',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isClockedIn ? (isOnBreak ? Colors.orange : Colors.green) : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  // Add a divider for clarity
                  const SizedBox(height: 10),
                  Divider(height: 1, thickness: 1, color: Colors.black12),
                  const SizedBox(height: 10),
                  // Clock in/out and break buttons, side by side for visibility
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: isClockedIn ? 'Clock Out Button' : 'Clock In Button',
                          enabled: !isLoadingClock,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isClockedIn ? const Color(0xFFD32F2F) : const Color(0xFF388E3C), // Improved contrast
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            icon: isLoadingClock
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Icon(isClockedIn ? Icons.logout : Icons.login),
                            label: Text(isClockedIn ? 'Clock Out' : 'Clock In'),
                            onPressed: isLoadingClock ? null : _toggleClockInOut,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: isOnBreak ? 'End Break Button' : 'Start Break Button',
                          enabled: !isLoadingBreak && isClockedIn,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isOnBreak ? const Color(0xFFF57C00) : const Color(0xFF455A64), // Improved contrast
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            icon: isLoadingBreak
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.free_breakfast),
                            label: Text(isOnBreak ? 'End Break' : 'Start Break'),
                            onPressed: (!isClockedIn || isLoadingBreak) ? null : _toggleBreak,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Attendance summary with more spacing and icons
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Semantics(
                        label: 'Present Days',
                        child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ),
                      const SizedBox(width: 6),
                      Text('Present: 20', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 20),
                      Semantics(
                        label: 'Absent Days',
                        child: Icon(Icons.cancel, color: Colors.red, size: 20),
                      ),
                      const SizedBox(width: 6),
                      Text('Absent: 2', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  // Last clock in and break time
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text('Last Clock In:', style: theme.textTheme.bodySmall),
                      const SizedBox(width: 6),
                      Text(
                        lastClockIn != null
                            ? TimeOfDay.fromDateTime(lastClockIn!).format(context)
                            : '--:--',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (isClockedIn) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 18, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text('Break Time:', style: theme.textTheme.bodySmall),
                        const SizedBox(width: 6),
                        AnimatedBuilder(
                          animation: _now,
                          builder: (context, _) => Text(
                            breakTimeDisplay,
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              // Quick Actions
              Text('Quick Actions', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DashboardActionButton(
                    icon: Icons.access_time,
                    label: 'Timesheet',
                    color: theme.colorScheme.primary.withOpacity(0.7),
                    onTap: () => Navigator.pushNamed(context, '/timesheet'),
                  ),
                  DashboardActionButton(
                    icon: Icons.calendar_today,
                    label: 'Leave',
                    color: theme.colorScheme.secondary.withOpacity(0.7),
                    onTap: () => Navigator.pushNamed(context, '/leave_request'),
                  ),
                  DashboardActionButton(
                    icon: Icons.check_circle_outline,
                    label: 'Attendance',
                    color: Colors.green.withOpacity(0.7),
                    onTap: () => Navigator.pushNamed(context, '/attendance'),
                  ),
                  DashboardActionButton(
                    icon: Icons.notifications,
                    label: 'Notices',
                    color: Colors.orange.withOpacity(0.7),
                    onTap: () => Navigator.pushNamed(context, '/notification'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Leave Balance & Recent Requests
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Leave Balance', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          LeaveBalanceTile(type: 'Annual', days: 8, color: Colors.blue),
                          LeaveBalanceTile(type: 'Sick', days: 4, color: Colors.green),
                          LeaveBalanceTile(type: 'Casual', days: 2, color: Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text('Recent Leave Requests', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          LeaveRequestTile(type: 'Annual', date: '2025-06-01', status: 'Approved'),
                          LeaveRequestTile(type: 'Sick', date: '2025-05-20', status: 'Pending'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Support Button
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Support'),
                  onPressed: () => Navigator.pushNamed(context, '/support'), // You can change this route as needed
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTile(BuildContext context, {required IconData icon, required String label, required String route, Widget? trailing}) {
    final theme = Theme.of(context);
    final isSelected = ModalRoute.of(context)?.settings.name == route;
    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.blueGrey, size: 26),
      title: Text(label, style: TextStyle(
        color: isSelected ? theme.colorScheme.primary : Colors.blueGrey[900],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 16,
      )),
      trailing: trailing,
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () {
        Navigator.pop(context);
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamed(context, route);
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      horizontalTitleGap: 12,
      minLeadingWidth: 0,
    );
  }

  Widget _buildNotificationDot() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
      ),
    );
  }
}
