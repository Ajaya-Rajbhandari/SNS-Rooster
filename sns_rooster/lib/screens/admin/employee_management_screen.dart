import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/auth_provider.dart';
import 'package:sns_rooster/screens/admin/edit_employee_dialog.dart';
import 'package:sns_rooster/screens/admin/add_employee_dialog.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _employees = [];

  // API base URL
  final String _baseUrl = 'http://10.0.2.2:5000/api'; // For Android emulator
  // Use 'http://localhost:5000/api' for iOS simulator

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse('$_baseUrl/users?role=employee'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      print('Load Employees response status: ${response.statusCode}');
      print('Load Employees response body: ${response.body}');

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _employees = List<Map<String, dynamic>>.from(data['users']);
        });
      } else {
        setState(() {
          _error = 'Failed to load employees';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Network error occurred';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateEmployeeStatus(String employeeId, bool isActive) async {
    if (!mounted) return;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.patch(
        Uri.parse('$_baseUrl/users/$employeeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: json.encode({'isActive': isActive}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        _loadEmployees();
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Failed to update employee status',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Network error occurred')));
    }
  }

  void _confirmDeleteEmployee(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text(
            'Are you sure you want to delete $name? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteEmployee(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEmployee(String employeeId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.delete(
        Uri.parse('$_baseUrl/auth/users/$employeeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee deleted successfully!')),
        );
        _loadEmployees(); // Refresh the list
      } else {
        final data = json.decode(response.body);
        setState(() {
          _error = data['message'] ?? 'Failed to delete employee';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Network error occurred: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_error!),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddEmployeeDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddEmployeeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Employee Management',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddEmployeeDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Employee'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadEmployees,
                          child: _employees.isEmpty
                              ? Center(
                                  child: Text(
                                    'No employees found. Tap the + button to add new employees.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _employees.length,
                                  itemBuilder: (context, index) {
                                    final employee = _employees[index];
                                    return Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                                          child: Text(
                                            employee['name']?[0]?.toUpperCase() ?? '?',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          employee['name'] ?? '',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: colorScheme.onSurface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              employee['email'] ?? '',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onSurface.withOpacity(0.7),
                                              ),
                                            ),
                                            Text(
                                              'Department: ${employee['department'] ?? 'N/A'}',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onSurface.withOpacity(0.7),
                                              ),
                                            ),
                                            Text(
                                              'Position: ${employee['position'] ?? 'N/A'}',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onSurface.withOpacity(0.7),
                                              ),
                                            ),
                                            Text(
                                              'Role: ${employee['role'] ?? 'N/A'}',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onSurface.withOpacity(0.7),
                                              ),
                                            ),
                                            Text(
                                              'Last Login: ${employee['lastLogin'] != null ? DateTime.parse(employee['lastLogin']).toLocal().toString().split('.')[0] : 'N/A'}',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onSurface.withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Tooltip(
                                              message: employee['isActive']
                                                  ? 'Deactivate Employee'
                                                  : 'Activate Employee',
                                              child: Switch(
                                                value: employee['isActive'] ?? false,
                                                onChanged: (value) =>
                                                    _updateEmployeeStatus(
                                                        employee['_id'], value),
                                                activeColor: colorScheme.primary,
                                                inactiveTrackColor: colorScheme
                                                    .onSurface
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            Tooltip(
                                              message: 'Edit Employee',
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  color: colorScheme.primary,
                                                ),
                                                onPressed: () async {
                                                  final result = await showDialog<bool>(
                                                    context: context,
                                                    builder:
                                                        (BuildContext dialogContext) {
                                                      return EditEmployeeDialog(
                                                          employee: employee);
                                                    },
                                                  );
                                                  if (result == true) {
                                                    _loadEmployees(); // Refresh list after edit
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'Employee updated successfully!')),
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                            Tooltip(
                                              message: 'Delete Employee',
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.delete,
                                                  color: colorScheme.error,
                                                ),
                                                onPressed: () => _confirmDeleteEmployee(
                                                    employee['_id'],
                                                    employee['name']),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
