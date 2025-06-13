import 'package:flutter/material.dart';
import 'package:sns_rooster/screens/admin/edit_employee_dialog.dart';
import 'package:sns_rooster/screens/admin/add_employee_dialog.dart';
import 'package:provider/provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart'; // Keep if needed for other purposes
import 'package:sns_rooster/providers/employee_provider.dart'; // Import EmployeeProvider

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  // Remove _employeeService, _employees, _isLoading, _error as they will come from EmployeeProvider

  @override
  void initState() {
    super.initState();
    // Fetch employees using EmployeeProvider after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeeProvider>(context, listen: false).getEmployees();
    });
  }

  // _loadEmployees is no longer needed here as EmployeeProvider handles it

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access EmployeeProvider
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    final _employees = employeeProvider.employees;
    final _isLoading = employeeProvider.isLoading;
    final _error = employeeProvider.error;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                // Implement search logic here
              },
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(
                  child: Text(_error!,
                      style: TextStyle(color: theme.colorScheme.error)))
            else if (_employees.isEmpty)
              Center(
                child: Text(
                  'No employees found.',
                  style: theme.textTheme.bodyLarge,
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _employees.length,
                  itemBuilder: (context, index) {
                    final employee = _employees[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primary,
                              child: Text(employee['firstName'][0],
                                  style: TextStyle(
                                      color: theme.colorScheme.onPrimary)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${employee['firstName']} ${employee['lastName']}',
                                      style: theme.textTheme.titleMedium),
                                  Text(employee['position'] ?? 'N/A',
                                      style: theme.textTheme.bodyMedium),
                                  Text(employee['email'],
                                      style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => EditEmployeeDialog(
                                      employee: employee,
                                      // Pass EmployeeProvider instead of EmployeeService
                                      employeeProvider: employeeProvider),
                                );
                                if (result == true) {
                                  // EmployeeProvider will notify listeners, so direct refresh might not be needed
                                  // or call employeeProvider.getEmployees() if explicit refresh is desired
                                  employeeProvider.getEmployees(); 
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Employee'),
                                    content: const Text(
                                        'Are you sure you want to delete this employee?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          // Use EmployeeProvider to delete employee
                                          await employeeProvider
                                              .deleteEmployee(employee['id']);
                                          // EmployeeProvider will notify listeners, so direct refresh might not be needed
                                          // or call employeeProvider.getEmployees() if explicit refresh is desired
                                          // _loadEmployees(); // This method is removed
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) =>
                // Pass EmployeeProvider instead of EmployeeService
                AddEmployeeDialog(employeeProvider: employeeProvider),
          );
          if (result == true) {
            // EmployeeProvider will notify listeners, so direct refresh might not be needed
            // or call employeeProvider.getEmployees() if explicit refresh is desired
            employeeProvider.getEmployees();
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
      ),
    );
  }
}
