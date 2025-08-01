import 'package:flutter/material.dart';
import 'package:sns_rooster/screens/admin/edit_employee_dialog.dart';
import 'package:sns_rooster/screens/admin/add_employee_dialog.dart';
import 'package:sns_rooster/services/employee_service.dart';
import 'package:provider/provider.dart';
import 'package:sns_rooster/providers/employee_provider.dart';
import '../../widgets/admin_side_navigation.dart';
import 'package:sns_rooster/screens/admin/employee_detail_screen.dart';
import 'package:sns_rooster/services/api_service.dart';
import 'package:sns_rooster/config/api_config.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  late final EmployeeService _employeeService;
  late final EmployeeProvider _employeeProvider;
  List<Map<String, dynamic>> _employees = []; // Master list of all employees
  List<Map<String, dynamic>> _filteredEmployees =
      []; // List of employees to display (after filtering)
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _employeeService =
          EmployeeService(ApiService(baseUrl: ApiConfig.baseUrl));
      _employeeProvider = Provider.of<EmployeeProvider>(context,
          listen: false); // Initialize EmployeeProvider
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
      fetchedEmployees =
          await _employeeService.getEmployees(showInactive: true);
      // Ensure each employee has a 'name' field for detail screen
      for (var emp in fetchedEmployees) {
        final firstName = emp['firstName'] ?? '';
        final lastName = emp['lastName'] ?? '';
        emp['name'] = (firstName.isNotEmpty || lastName.isNotEmpty)
            ? '$firstName${lastName.isNotEmpty ? ' $lastName' : ''}'
            : null;
      }
    } catch (e) {
      fetchError = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _employees = fetchedEmployees;
          _filteredEmployees = fetchedEmployees; // Initialize filtered list
          _error = fetchError;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
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
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AdminSideNavigation(currentRoute: '/employee_management'),
      body: Column(
        children: [
          // Quick Stats Section
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Employees',
                    '${_employees.length}',
                    Icons.people,
                    colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Active',
                    '${_employees.where((emp) => emp['isActive'] != false).length}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Inactive',
                    '${_employees.where((emp) => emp['isActive'] == false).length}',
                    Icons.person_off,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Employee List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildEmptyState(context, 'Error', _error!, Icons.error,
                        colorScheme.error)
                    : _filteredEmployees.isEmpty
                        ? _buildEmptyState(
                            context,
                            'No Employees',
                            'No employees found in the system',
                            Icons.people_outline,
                            colorScheme.primary)
                        : _buildEmployeeList(context),
          ),
        ],
      ),
    );
  }

  // Helper method to build a stat card
  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build an empty state message
  Widget _buildEmptyState(BuildContext context, String title, String message,
      IconData icon, Color color) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: color),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build the employee list
  Widget _buildEmployeeList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListView.builder(
      itemCount: _filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = _filteredEmployees[index];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmployeeDetailScreen(
                    employee: employee,
                    employeeProvider: _employeeProvider,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primary,
                    child: Text(
                        (employee['firstName'] != null &&
                                employee['firstName'].toString().isNotEmpty)
                            ? employee['firstName'][0].toUpperCase()
                            : (employee['lastName'] != null &&
                                    employee['lastName'].toString().isNotEmpty)
                                ? employee['lastName'][0].toUpperCase()
                                : '?',
                        style: TextStyle(color: colorScheme.onPrimary)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${employee['firstName'] ?? ''} ${employee['lastName'] ?? ''}'
                                    .trim(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (employee['isActive'] == false)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Inactive',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(employee['position'] ?? 'N/A',
                            style: theme.textTheme.bodyMedium),
                        // Employment Type/Subtype
                        if (employee['employeeType'] != null &&
                            employee['employeeType'].toString().isNotEmpty)
                          Text(
                            'Employment: '
                            '${employee['employeeType']}'
                            '${employee['employeeSubType'] != null && employee['employeeSubType'].toString().isNotEmpty ? ' - ${employee['employeeSubType']}' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Colors.blueGrey),
                          ),
                        Text(employee['email'] ?? 'N/A',
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
                            employeeProvider: _employeeProvider),
                      );
                      if (result == true) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _loadEmployees();
                          }
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      final employeeId = employee['_id'];
                      if (employeeId != null && employeeId is String) {
                        _confirmDeleteEmployee(employeeId);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Cannot delete employee: Employee ID is missing.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Updated method to confirm and delete employee from database using provider
  Future<void> _confirmDeleteEmployee(String employeeId) async {
    if (!mounted) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete Employee'),
          content: const Text(
              'Are you sure you want to permanently delete this employee? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        // Use provider to delete and update UI
        final provider = Provider.of<EmployeeProvider>(context, listen: false);
        final success = await provider.deleteEmployee(employeeId);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee deleted successfully')),
          );
          setState(() {
            _employees.removeWhere((emp) =>
                emp['userId'] == employeeId ||
                emp['_id'] == employeeId ||
                emp['id'] == employeeId);
            _filteredEmployees.removeWhere((emp) =>
                emp['userId'] == employeeId ||
                emp['_id'] == employeeId ||
                emp['id'] == employeeId);
          });
          _loadEmployees(); // Always refresh the list after deletion
        } else {
          // If the error is a 404, treat as success
          if ((provider.error ?? '').contains('404')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Employee already deleted.')),
            );
            _loadEmployees();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Failed to delete employee: \\${provider.error ?? 'Unknown error'}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete employee: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
