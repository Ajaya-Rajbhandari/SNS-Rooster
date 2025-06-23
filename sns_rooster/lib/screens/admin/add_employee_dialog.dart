import 'package:flutter/material.dart';
import 'package:sns_rooster/services/employee_service.dart';
import 'package:sns_rooster/models/user_model.dart';
import 'package:sns_rooster/services/user_service.dart';
import 'package:sns_rooster/utils/constants.dart';

class AddEmployeeDialog extends StatefulWidget {
  final EmployeeService employeeService;

  const AddEmployeeDialog({super.key, required this.employeeService});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  final UserService _userService = UserService();
  List<UserModel> _users = [];
  UserModel? _selectedUser;
  String? _selectedPosition;
  String? _selectedDepartment;
  String? _selectedRole;
  bool _isLoadingUsers = true;

  final List<String> _roles = ['employee', 'admin'];

  bool _isLoading = false;
  String? _error;
  bool _dialogResult = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });
    try {
      final users = await _userService.getUsers();
      setState(() {
        _users = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: ${e.toString()}')),
        );
      }
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
    if (_selectedPosition == null) {
      setState(() {
        _error = 'Please select a position.';
      });
      return;
    }
    if (_selectedDepartment == null) {
      setState(() {
        _error = 'Please select a department.';
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
        'position': _selectedPosition,
        'department': _selectedDepartment,
        'role': _selectedRole,
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
                                  isExpanded: true, // Allow the dropdown to expand
                                  items: _users.map((UserModel user) {
                                    return DropdownMenuItem<UserModel>(
                                      value: user,
                                      child: Expanded(
                                        child: Text(
                                          user.displayName,
                                          overflow: TextOverflow.ellipsis, // Handle long text
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (UserModel? newValue) {
                                    setState(() {
                                      _selectedUser = newValue;
                                    });
                                  },
                                  validator: (value) =>
                                      value == null ? 'Please select a user' : null,
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

              // Employee Details Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Employee Details',
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
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Position',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedPosition,
                        items: EmployeeConstants.positions.map((String position) {
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
                        validator: (value) =>
                            value == null ? 'Please select a position' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedDepartment,
                        items: EmployeeConstants.departments.map((String department) {
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
                        validator: (value) =>
                            value == null ? 'Please select a department' : null,
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
