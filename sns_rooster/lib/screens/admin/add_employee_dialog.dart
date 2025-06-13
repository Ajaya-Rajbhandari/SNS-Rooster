import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:convert'; // Keep if still needed for other parts, or remove if EmployeeProvider handles all.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart'; // Keep if needed for other purposes
import 'package:sns_rooster/providers/employee_provider.dart'; // Import EmployeeProvider

class AddEmployeeDialog extends StatefulWidget {
  final EmployeeProvider employeeProvider; // Change to EmployeeProvider

  const AddEmployeeDialog({super.key, required this.employeeProvider}); // Update constructor

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
      // Prepare the employee data from the form controllers
      final employeeData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text, // Assuming EmployeeProvider handles registration or this is for a different purpose
        'employeeId': _employeeIdController.text.trim(),
        'position': _positionController.text.trim(),
        'department': _departmentController.text.trim(),
        // 'role': 'employee', // This might be set within EmployeeProvider or backend
      };

      // Call addEmployee on the EmployeeProvider
      await widget.employeeProvider.addEmployee(employeeData);

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
