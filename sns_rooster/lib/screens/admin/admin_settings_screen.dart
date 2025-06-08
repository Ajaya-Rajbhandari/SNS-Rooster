import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text(
            'Admin Settings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'General Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    value: true, // Replace with actual setting value
                    onChanged: (bool value) {
                      // Handle setting change
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: false, // Replace with actual setting value
                    onChanged: (bool value) {
                      // Handle setting change
                    },
                  ),
                  ListTile(
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Handle change password tap
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ListTile(
                    title: const Text('Backup Data'),
                    trailing: const Icon(Icons.cloud_upload),
                    onTap: () {
                      // Handle backup data tap
                    },
                  ),
                  ListTile(
                    title: const Text('Restore Data'),
                    trailing: const Icon(Icons.cloud_download),
                    onTap: () {
                      // Handle restore data tap
                    },
                  ),
                  ListTile(
                    title: const Text('View System Logs'),
                    trailing: const Icon(Icons.description),
                    onTap: () {
                      // Handle view system logs tap
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}