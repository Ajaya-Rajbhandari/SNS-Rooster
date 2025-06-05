import 'package:flutter/material.dart';
import 'dart:ui';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
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
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                    (route) => false,
                  );
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage(
                'assets/images/profile_placeholder.png',
              ),
              // Placeholder image
            ),

            const SizedBox(height: 16.0),
            Text('John Doe', style: Theme.of(context).textTheme.headlineSmall),
            const Text('Software Engineer'),
            const SizedBox(height: 24.0),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.email),
                      title: Text('Email'),
                      subtitle: Text('john.doe@example.com'),
                    ),

                    ListTile(
                      leading: Icon(Icons.phone),
                      title: Text('Phone'),
                      subtitle: Text('+1 123-456-7890'),
                    ),

                    ListTile(
                      leading: Icon(Icons.location_on),
                      title: Text('Address'),
                      subtitle: Text('123 Main St, Anytown USA'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () {
                // Handle edit profile action
              },
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

}
