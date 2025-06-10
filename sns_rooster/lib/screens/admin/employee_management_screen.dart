import 'package:flutter/material.dart';
import 'package:sns_rooster/screens/admin/edit_employee_dialog.dart';
import 'package:sns_rooster/screens/admin/add_employee_dialog.dart';
import 'package:sns_rooster/services/employee_service.dart';
import 'package:provider/provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final EmployeeService _employeeService;
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _employeeService =
          EmployeeService(Provider.of<AuthProvider>(context, listen: false));
      _loadEmployees();
    });
  }

  Future<void> _loadEmployees() async {
    List<Map<String, dynamic>> fetchedEmployees = [];
    String? fetchError;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      fetchedEmployees = await _employeeService.getEmployees();
    } catch (e) {
      fetchError = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _employees = fetchedEmployees;
          _error = fetchError;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                                      employeeService: _employeeService),
                                );
                                if (result == true) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted) {
                                      _loadEmployees(); // Refresh list after update
                                    }
                                  });
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
                                          await _employeeService
                                              .deleteEmployee(employee['id']);
                                          _loadEmployees(); // Refresh list after delete
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
                AddEmployeeDialog(employeeService: _employeeService),
          );
          if (result == true) {
            if (mounted) {
              _loadEmployees(); // Refresh list after add
            }
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
      ),
    );
  }
}
