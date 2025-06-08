import 'package:flutter/material.dart';
import 'package:sns_rooster/screens/admin/edit_employee_dialog.dart';

class EmployeeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> employee;

  const EmployeeDetailScreen({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(employee['name'] ?? 'Employee Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: ${employee['name'] ?? 'N/A'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Designation: ${employee['position'] ?? 'N/A'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Email: ${employee['email'] ?? 'N/A'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final updatedEmployee = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return EditEmployeeDialog(
                      employee: employee,
                    );
                  },
                );
                if (updatedEmployee != null) {
                  // In a real app, you would update the employee data in your state management or database
                  // For now, we'll just print the updated data.
                  print(
                      'Updated Employee from detail screen: ${updatedEmployee['name']}, ${updatedEmployee['position']}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Employee updated: ${updatedEmployee['name']} - ${updatedEmployee['position']}')),
                  );
                }
              },
              child: const Text('Edit Employee Details'),
            ),
          ],
        ),
      ),
    );
  }
}
