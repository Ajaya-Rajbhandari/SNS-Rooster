import 'package:flutter/material.dart';
import 'package:sns_rooster/services/employee_service.dart';
import 'package:sns_rooster/models/user_model.dart';
import 'package:sns_rooster/services/user_service.dart';
import 'package:sns_rooster/services/api_service.dart';
import 'package:sns_rooster/config/api_config.dart';
import 'package:sns_rooster/utils/logger.dart';

class AddEmployeeDialog extends StatefulWidget {
  final EmployeeService employeeService;

  const AddEmployeeDialog({super.key, required this.employeeService});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();

  final UserService _userService = UserService();
  List<UserModel> _users = [];
  UserModel? _selectedUser;
  bool _isLoadingUsers = true;

  bool _isLoading = false;
  String? _error;
  bool _dialogResult = false;

  List<Map<String, dynamic>> _employees = [];

  // Added Position and Department dropdowns
  final List<String> positions = [
    'Manager',
    'Developer',
    'Designer',
    'QA',
    'HR',
    'Support',
    'Intern',
    'Other'
  ];
  final List<String> departments = [
    'Engineering',
    'Design',
    'HR',
    'Support',
    'Sales',
    'Marketing',
    'Finance',
    'Other'
  ];
  final List<String> employeeTypes = [
    'Permanent',
    'Temporary',
  ];
  final List<String> permanentTypes = [
    'Full-time',
    'Part-time',
  ];
  final List<String> temporaryTypes = [
    'Casual',
  ];
  String? _selectedEmployeeType;
  String? _selectedEmployeeSubType;

  String? _selectedPosition;
  String? _selectedDepartment;

  // Location selection variables
  List<Map<String, dynamic>> _locations = [];
  String? _selectedLocationId;
  bool _isLoadingLocations = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchEmployees();
    _fetchLocations(); // Add location fetching
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });
    try {
      // Fetch all users
      final users = await _userService.getUsers();
      // Fetch all employees (ensure _employees is up to date)
      if (_employees.isEmpty) {
        await _fetchEmployees();
      }
      final employeeUserIds = _employees.map((e) => e['userId']).toSet();
      // Filter: role == 'employee', not already employee, not admin/test in email
      final filtered = users.where((user) {
        final email = user.email.toLowerCase();
        final username = user.email.split('@').first.toLowerCase();
        final isEmployeeRole = user.role == 'employee';
        final notAlreadyEmployee = !employeeUserIds.contains(user.id);
        final notAdminOrTest = !email.contains('admin') &&
            !email.contains('test') &&
            !username.contains('admin') &&
            !username.contains('test');
        return isEmployeeRole && notAlreadyEmployee && notAdminOrTest;
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
          SnackBar(content: Text('Failed to load users: ${e.toString()}')),
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

  Future<void> _fetchLocations() async {
    setState(() {
      _isLoadingLocations = true;
    });

    try {
      final apiService = ApiService(baseUrl: ApiConfig.baseUrl);
      final response = await apiService.get('/locations');

      if (response.success) {
        setState(() {
          _locations =
              List<Map<String, dynamic>>.from(response.data['locations'] ?? []);
          _isLoadingLocations = false;
        });
        Logger.info(
            'Successfully loaded ${_locations.length} locations for employee assignment');
      } else {
        Logger.error('Failed to load locations: ${response.message}');
        setState(() {
          _locations = [];
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      Logger.error('Error loading locations: $e');
      setState(() {
        _locations = [];
        _isLoadingLocations = false;
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

    if (_selectedEmployeeType == null) {
      setState(() {
        _error = 'Please select an employee type.';
      });
      return;
    }

    if (_selectedEmployeeSubType == null) {
      setState(() {
        _error = 'Please select a subtype.';
      });
      return;
    }

    // Extra validation: check if this user is already an employee
    final alreadyEmployee =
        _employees.any((emp) => emp['userId'] == _selectedUser!.id);
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
        'position': _selectedPosition,
        'department': _selectedDepartment,
        'employeeType': _selectedEmployeeType,
        'employeeSubType': _selectedEmployeeSubType,
        'hourlyRate': double.tryParse(_hourlyRateController.text) ?? 0,
        'locationId': _selectedLocationId, // Add location assignment
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
                                    hintText:
                                        'Select a user to add as employee',
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
                                        _employeeIdController.text =
                                            _generateEmployeeIdFromUser(
                                                newValue);
                                      } else {
                                        _employeeIdController.clear();
                                      }
                                    });
                                  },
                                  validator: (value) => value == null
                                      ? 'Please select a user'
                                      : null,
                                ),
                                if (_selectedUser != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                      'Selected: ${_selectedUser!.displayName}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text('Email: ${_selectedUser!.email}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: theme
                                              .textTheme.bodySmall?.color)),
                                ],
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
                        validator: (value) =>
                            value == null ? 'Please select a position' : null,
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
                        validator: (value) =>
                            value == null ? 'Please select a department' : null,
                      ),
                    ],
                  ),
                ),
              ),

              // Location Dropdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Location',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _isLoadingLocations
                          ? const Center(child: CircularProgressIndicator())
                          : _locations.isEmpty
                              ? const Center(
                                  child: Text('No locations available'))
                              : DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    hintText: 'Select location (optional)',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _selectedLocationId,
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('No location assigned'),
                                    ),
                                    ..._locations.map((location) {
                                      return DropdownMenuItem<String>(
                                        value: location['_id'] as String,
                                        child: Text(location['name'] as String),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedLocationId = newValue;
                                    });
                                  },
                                ),
                    ],
                  ),
                ),
              ),

              // Employee Type Dropdowns
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Employee Type',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          hintText: 'Select employee type',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedEmployeeType,
                        items: employeeTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedEmployeeType = newValue;
                            // Set default subtype when type changes
                            if (newValue == 'Permanent') {
                              _selectedEmployeeSubType = 'Full-time';
                            } else if (newValue == 'Temporary') {
                              _selectedEmployeeSubType = 'Casual';
                            } else {
                              _selectedEmployeeSubType = null;
                            }
                          });
                        },
                        validator: (value) => value == null
                            ? 'Please select an employee type'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      if (_selectedEmployeeType == 'Permanent')
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            hintText: 'Select permanent type',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedEmployeeSubType,
                          items: permanentTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedEmployeeSubType = newValue;
                            });
                          },
                          validator: (value) => value == null
                              ? 'Please select a permanent type'
                              : null,
                        ),
                      if (_selectedEmployeeType == 'Temporary')
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            hintText: 'Select temporary type',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedEmployeeSubType,
                          items: temporaryTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedEmployeeSubType = newValue;
                            });
                          },
                          validator: (value) => value == null
                              ? 'Please select a temporary type'
                              : null,
                        ),
                    ],
                  ),
                ),
              ),

              // Hourly Rate Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hourly Rate',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _hourlyRateController,
                        decoration: const InputDecoration(
                          labelText: 'Hourly Rate',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),

              if (_error != null) ...[
                // Show error message if present
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style:
                      TextStyle(color: theme.colorScheme.error, fontSize: 14),
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
