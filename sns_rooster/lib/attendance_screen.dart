import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

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
      body: Column(
        children: [
          CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            onDateChanged: (newDate) {
              setState(() {
                _selectedDate = newDate;
              });
            },
          ),
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  title: Text('Clock In'),
                  subtitle: Text('2023-10-26 09:00 AM'),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
                ListTile(
                  title: Text('Clock Out'),
                  subtitle: Text('2023-10-26 05:00 PM'),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
                ListTile(
                  title: Text('Clock In'),
                  subtitle: Text('2023-10-25 09:00 AM'),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
                ListTile(
                  title: Text('Clock Out'),
                  subtitle: Text('2023-10-25 05:00 PM'),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
