import 'package:flutter/material.dart';
import 'package:sns_rooster/services/employee_service.dart';
import 'package:sns_rooster/models/user_model.dart';
import 'package:sns_rooster/services/user_service.dart';

class AddEmployeeDialog extends StatefulWidget {
  final EmployeeService employeeService;

  const AddEmployeeDialog({super.key, required this.employeeService});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _employeeIdController = TextEditingController();

  final UserService _userService = UserService();
  List<UserModel> _users = [];
  UserModel? _selectedUser;
  String? _selectedRole;
  bool _isLoadingUsers = true;

  final List<String> _roles = ['employee', 'admin'];

  bool _isLoading = false;
  String? _error;
  bool _dialogResult = false;

  List<Map<String, dynamic>> _employees = [];

  // Added Position and Department dropdowns
  final List<String> positions = ['Manager', 'Developer', 'Designer', 'QA', 'HR', 'Support', 'Intern', 'Other'];
  final List<String> departments = ['Engineering', 'Design', 'HR', 'Support', 'Sales', 'Marketing', 'Finance', 'Other'];

  String? _selectedPosition;
  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchEmployees();
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });
    try {
      final users = await _userService.getUsers();
      // Filter out admin/test users
      final filtered = users.where((user) {
        final email = user.email.toLowerCase();
        return !email.contains('admin') && !email.contains('test');
      }).toList();
      setState(() {
        _users = filtered;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load users: {e.toString()}')),
        );
      }
    }
  }

  Future<void> _fetchEmployees() async {
    try {
      final employees = await widget.employeeService.getEmployees();
      setState(() {
        _employees = employees;
      });
    } catch (e) {
      // Optionally show a warning, but don't block the dialog
      setState(() {
        _employees = [];
      });
    }
  }

  Future<void> _addEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUser == null) {
      setState(() {
        _error = 'Please select a user.';
      });
      return;
    }
    if (_selectedRole == null) {
      setState(() {
        _error = 'Please select a role.';
      });
      return;
    }

    // Extra validation: check if this user is already an employee
    final alreadyEmployee = _employees.any((emp) => emp['userId'] == _selectedUser!.id);
    if (alreadyEmployee) {
      setState(() {
        _error = 'This user is already assigned as an employee.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newEmployeeData = {
        'userId': _selectedUser!.id,
        'firstName': _selectedUser!.firstName,
        'lastName': _selectedUser!.lastName,
        'email': _selectedUser!.email,
        'employeeId': _employeeIdController.text.trim(),
        'role': _selectedRole,
        'position': _selectedPosition,
        'department': _selectedDepartment,
      };

      await widget.employeeService.addEmployee(newEmployeeData);

      if (!mounted) return;
      _dialogResult = true;
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'An error occurred: ${e.toString()}';
      });
      _dialogResult = false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(_dialogResult);
        }
      }
    }
  }

  // Fixed Employee ID generation logic
  String _generateEmployeeIdFromUser(UserModel user) {
    final first = user.firstName.trim();
    final last = user.lastName.trim();
    String initials = '';
    if (first.isNotEmpty) initials += first[0].toUpperCase();
    if (last.isNotEmpty) initials += last[0].toUpperCase();
    final ts = DateTime.now().millisecondsSinceEpoch % 100000;
    return initials.isNotEmpty ? '$initials$ts' : 'EMP$ts';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Add New Employee'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User Selection
              _isLoadingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? const Center(child: Text('No users available'))
                      : Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select User',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<UserModel>(
                                  decoration: const InputDecoration(
                                    hintText: 'Select a user to add as employee',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _selectedUser,
                                  isExpanded: true,
                                  items: _users.map((UserModel user) {
                                    return DropdownMenuItem<UserModel>(
                                      value: user,
                                      child: Text(
                                        user.displayName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (UserModel? newValue) {
                                    setState(() {
                                      _selectedUser = newValue;
                                      // Auto-fill and generate Employee ID when user is selected
                                      if (newValue != null) {
                                        _employeeIdController.text = _generateEmployeeIdFromUser(newValue);
                                      } else {
                                        _employeeIdController.clear();
                                      }
                                    });
                                  },
                                  validator: (value) => value == null ? 'Please select a user' : null,
                                ),
                                if (_selectedUser != null) ...[
                                  const SizedBox(height: 8),
                                  Text('Selected: ${_selectedUser!.displayName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Email: ${_selectedUser!.email}', style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
                                ],
                              ],
                            ),
                          ),
                        ),
              const SizedBox(height: 16),

              // Role Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign Role',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          hintText: 'Select role',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedRole,
                        items: _roles.map((String role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role[0].toUpperCase() + role.substring(1)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedRole = newValue;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a role' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Employee ID Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Employee ID',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _employeeIdController,
                        decoration: const InputDecoration(
                          labelText: 'Employee ID',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),

              // Position Dropdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Position',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          hintText: 'Select position',
                          border: OutlineInputBorder(),
                        ),
                        items: positions.map((String position) {
                          return DropdownMenuItem<String>(
                            value: position,
                            child: Text(position),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPosition = newValue;
                          });
                        },
                        validator: (value) => value == null ? 'Please select a position' : null,
                      ),
                    ],
                  ),
                ),
              ),

              // Department Dropdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Department',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          hintText: 'Select department',
                          border: OutlineInputBorder(),
                        ),
                        items: departments.map((String department) {
                          return DropdownMenuItem<String>(
                            value: department,
                            child: Text(department),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDepartment = newValue;
                          });
                        },
                        validator: (value) => value == null ? 'Please select a department' : null,
                      ),
                    ],
                  ),
                ),
              ),

              if (_error != null) ...[  // Show error message if present
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addEmployee,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
