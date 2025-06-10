import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sns_rooster/services/employee_service.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AddEmployeeDialog extends StatefulWidget {
  final EmployeeService employeeService;

  const AddEmployeeDialog({super.key, required this.employeeService});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _dialogResult = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _employeeIdController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _addEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final registerUrl = Uri.parse('${authProvider.baseUrl}/auth/register');
      final registerBody = json.encode({
        'name':
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'role': 'employee',
        'department': _departmentController.text.trim(),
        'position': _positionController.text.trim(),
      });

      print("Registering user to URL: $registerUrl");
      print("Registering user with body: $registerBody");

      final response = await http.post(
        registerUrl,
        headers: {'Content-Type': 'application/json'},
        body: registerBody,
      );

      print("User registration response status: ${response.statusCode}");
      print("User registration response body: ${response.body}");

      final data = json.decode(response.body);

      if (response.statusCode != 201) {
        throw Exception(data['message'] ?? 'Failed to register user');
      }

      final userId = data['user']['_id'];

      final newEmployee = {
        'userId': userId,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'employeeId': _employeeIdController.text.trim(),
        'position': _positionController.text.trim(),
        'department': _departmentController.text.trim(),
      };

      final addEmployeeUrl = Uri.parse('${authProvider.baseUrl}/employees');
      final addEmployeeBody = json.encode(newEmployee);

      print("Adding employee to URL: $addEmployeeUrl");
      print("Adding employee with body: $addEmployeeBody");

      final addEmployeeResponse = await http.post(
        addEmployeeUrl,
        headers: widget.employeeService.getHeaders(), // Use the correct headers
        body: addEmployeeBody,
      );

      print("Add employee response status: ${addEmployeeResponse.statusCode}");
      print("Add employee response body: ${addEmployeeResponse.body}");

      if (addEmployeeResponse.statusCode != 201) {
        throw Exception(json.decode(addEmployeeResponse.body)['message'] ??
            'Failed to add employee');
      }

      if (!mounted) return;

      _dialogResult = true;
    } on Exception catch (e) {
      if (!mounted) return;
      String errorMessage = 'An error occurred: ${e.toString()}';
      if (e.toString().contains('E11000 duplicate key error') &&
          e.toString().contains('email_1 dup key')) {
        errorMessage =
            'An employee with this email already exists. Please use a different email.';
      } else if (e.toString().contains('Failed to register user')) {
        errorMessage = 'Failed to create user account: ${e.toString()}';
      }
      setState(() {
        _error = errorMessage;
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
      title: const Text('Add Employee'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _employeeIdController,
                decoration: const InputDecoration(labelText: 'Employee ID'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _positionController,
                decoration: InputDecoration(
                  labelText: 'Position',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon:
                      Icon(Icons.work, color: theme.colorScheme.primary),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter position';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departmentController,
                decoration: InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon:
                      Icon(Icons.business, color: theme.colorScheme.primary),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter department';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
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
