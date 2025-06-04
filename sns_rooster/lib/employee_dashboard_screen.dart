import 'package:flutter/material.dart';
import 'package:sns_rooster/timesheet_screen.dart';
import 'package:sns_rooster/attendance_screen.dart';
import 'package:sns_rooster/notification_screen.dart';
import 'package:sns_rooster/profile_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  String _currentStatus = 'Clocked Out'; // Initial status
  bool _isClockedIn = false;
  bool _isOnBreak = false;

  void _toggleClockIn() {
    setState(() {
      _isClockedIn = !_isClockedIn;
      if (_isClockedIn) {
        _currentStatus = 'On Duty';
        _isOnBreak = false; // Ensure not on break when clocking in
      } else {
        _currentStatus = 'Clocked Out';
      }
    });
  }

  void _toggleBreak() {
    if (!_isClockedIn) return; // Cannot go on break if not clocked in

    setState(() {
      _isOnBreak = !_isOnBreak;
      if (_isOnBreak) {
        _currentStatus = 'On Break';
      } else {
        _currentStatus = 'On Duty'; // Return to On Duty after break
      }
    });
  }

  // Extracted reusable spacer widget

  // Extracted quick action button widget
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: label.contains('Clock Out')
              ? Colors.redAccent
              : Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // Extracted performance metric widget
  Widget _buildPerformanceMetric(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Theme.of(context).primaryColor),
        const SizedBox(height: 5),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Extracted bottom action button widget
  Widget _buildBottomActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200], // Light grey background
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, size: 30, color: Theme.of(context).primaryColor),
            onPressed: onPressed,
            padding: const EdgeInsets.all(15),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // White background for app bar
        elevation: 0, // No shadow
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black), // Menu icon
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset(
              'assets/images/logo.png', // Your logo
              height: 40,
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Text(
                'SNS HR', // Or your app name
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.pushNamed(context, '/employee_dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Timesheet'),
              onTap: () {
                Navigator.pop(context); // Close the drawer first
                Navigator.pushNamed(context, '/timesheet');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Leave'),
              onTap: () {
                Navigator.pop(context); // Close the drawer first
                Navigator.pushNamed(
                  context,
                  '/leave_request',
                ); // Leave Request is not in bottom nav
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Attendance'),
              onTap: () {
                Navigator.pop(context); // Close the drawer first
                Navigator.pushNamed(context, '/attendance');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_none),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context); // Close the drawer first
                Navigator.pushNamed(context, '/notification');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context); // Close the drawer first
                Navigator.pushNamed(context, '/profile');
              },
            ),
            const Divider(), // Add a divider before logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Implement logout logic here
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back,',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              "Here's your summary for today.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Status: $_currentStatus',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Jun 10, 2024',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 5),
                Text('9:41 AM', style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                const Icon(Icons.notifications_none, color: Colors.black54),
                const SizedBox(width: 10),
                const CircleAvatar(
                  backgroundImage: AssetImage(
                    'assets/images/profile_placeholder.png',
                  ),
                  radius: 20,
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildQuickActionButton(
                  icon: _isClockedIn ? Icons.timer_off : Icons.timer,
                  label: _isClockedIn ? 'Clock Out' : 'Clock In',
                  onPressed: _toggleClockIn,
                ),
                const SizedBox(width: 10),
                _buildQuickActionButton(
                  icon: _isOnBreak
                      ? Icons.free_breakfast_outlined
                      : Icons.free_breakfast,
                  label: _isOnBreak ? 'End Break' : 'Start Break',
                  onPressed: _isClockedIn ? _toggleBreak : () {},
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search or start a quick action...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(5),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                    child: const Text(
                      'Go',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Your Performance',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPerformanceMetric(
                  context,
                  'Attendance',
                  '98%',
                  Icons.check_circle_outline,
                ),
                _buildPerformanceMetric(
                  context,
                  'Goals',
                  '8/10',
                  Icons.flag_outlined,
                ),
                _buildPerformanceMetric(
                  context,
                  'Rating',
                  '4.5',
                  Icons.star_half,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Monthly Progress',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: 0.8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                  child: _buildBottomActionButton(
                    context,
                    'Leave Request',
                    Icons.calendar_today,
                    () => Navigator.pushNamed(context, '/leave_request'),
                  ),
                ),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                  child: _buildBottomActionButton(
                    context,
                    'Timesheet',
                    Icons.access_time,
                    () => Navigator.pushNamed(context, '/timesheet'),
                  ),
                ),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                  child: _buildBottomActionButton(
                    context,
                    'Submit Incident',
                    Icons.warning_amber,
                    () {},
                  ),
                ),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                  child: _buildBottomActionButton(
                    context,
                    'Messages',
                    Icons.mail_outline,
                    () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
