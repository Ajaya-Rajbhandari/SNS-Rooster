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
  final TextEditingController _searchController = TextEditingController();
  late final EmployeeService _employeeService;
  late final EmployeeProvider _employeeProvider;
  List<Map<String, dynamic>> _employees = []; // Master list of all employees
  List<Map<String, dynamic>> _filteredEmployees =
      []; // List of employees to display (after filtering)
  bool _isLoading = false;
  String? _error;
  bool _showInactive = false; // Track whether to show inactive employees

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterEmployees); // Add listener for search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _employeeService = EmployeeService(ApiService(baseUrl: ApiConfig.baseUrl));
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
          await _employeeService.getEmployees(showInactive: _showInactive);
      // Ensure each employee has a 'name' field for detail screen
      for (var emp in fetchedEmployees) {
        final firstName = emp['firstName'] ?? '';
        final lastName = emp['lastName'] ?? '';
        emp['name'] = (firstName.isNotEmpty || lastName.isNotEmpty)
            ? (firstName + (lastName.isNotEmpty ? ' ' + lastName : ''))
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
    _searchController.removeListener(_filterEmployees);
    _searchController.dispose();
    super.dispose();
  }

  void _filterEmployees() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredEmployees = _employees;
      });
    } else {
      setState(() {
        _filteredEmployees = _employees.where((employee) {
          final firstName =
              employee['firstName']?.toString().toLowerCase() ?? '';
          final lastName = employee['lastName']?.toString().toLowerCase() ?? '';
          final email = employee['email']?.toString().toLowerCase() ?? '';
          final position = employee['position']?.toString().toLowerCase() ?? '';
          return firstName.contains(query) ||
              lastName.contains(query) ||
              email.contains(query) ||
              position.contains(query);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          // Toggle button to show/hide inactive employees
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _showInactive ? 'All' : 'Active',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 12,
                ),
              ),
              Switch(
                value: _showInactive,
                onChanged: (value) {
                  setState(() {
                    _showInactive = value;
                  });
                  _loadEmployees(); // Reload employees with new filter
                },
                activeColor: theme.colorScheme.onPrimary,
                activeTrackColor: theme.colorScheme.onPrimary.withOpacity(0.3),
                inactiveThumbColor: theme.colorScheme.onPrimary,
                inactiveTrackColor:
                    theme.colorScheme.onPrimary.withOpacity(0.3),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: const AdminSideNavigation(currentRoute: '/employee_management'),
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
                _filterEmployees(); // Call filter method on change
              },
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(
                  child: Text(_error!,
                      style: TextStyle(color: theme.colorScheme.error)))
            else if (_filteredEmployees.isEmpty &&
                _searchController.text.isEmpty)
              Center(
                child: Text(
                  'No employees found.',
                  style: theme.textTheme.bodyLarge,
                ),
              )
            else if (_filteredEmployees.isEmpty &&
                _searchController.text.isNotEmpty)
              Center(
                child: Text(
                  'No employees match your search.',
                  style: theme.textTheme.bodyLarge,
                ),
              )
            else if (_employees
                .isEmpty) // This case might be redundant now but kept for safety
              Center(
                child: Text(
                  'No employees found.',
                  style: theme.textTheme.bodyLarge,
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = _filteredEmployees[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              insetPadding: const EdgeInsets.all(24),
                              child: SizedBox(
                                width: 500,
                                child: EmployeeDetailScreen(
                                    employee: employee,
                                    employeeProvider: _employeeProvider),
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: theme.colorScheme.primary,
                                child: Text(
                                    (employee['firstName'] != null &&
                                            employee['firstName'].isNotEmpty)
                                        ? employee['firstName'][0]
                                        : '?',
                                    style: TextStyle(
                                        color: theme.colorScheme.onPrimary)),
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
                                              "${employee['firstName'] ?? 'N/A'} ${employee['lastName'] ?? 'N/A'}",
                                              style:
                                                  theme.textTheme.titleMedium),
                                        ),
                                        // Show inactive badge if employee is inactive
                                        if (employee['isActive'] == false)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.red.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.red
                                                      .withOpacity(0.3)),
                                            ),
                                            child: const Text(
                                              'Inactive',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 10,
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
                                        employee['employeeType']
                                            .toString()
                                            .isNotEmpty)
                                      Text(
                                        'Employment: '
                                        '${employee['employeeType']}'
                                        '${employee['employeeSubType'] != null && employee['employeeSubType'].toString().isNotEmpty ? ' - ${employee['employeeSubType']}' : ''}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
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
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
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
                                  if (employeeId != null &&
                                      employeeId is String) {
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
} // Added missing closing brace for _EmployeeManagementScreenState
