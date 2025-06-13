import 'package:flutter/material.dart';
import 'package:sns_rooster/providers/employee_provider.dart'; // Import EmployeeProvider

class EditEmployeeDialog extends StatefulWidget {
  final Map<String, dynamic> employee;
  final EmployeeProvider employeeProvider; // Change to EmployeeProvider

  const EditEmployeeDialog(
      {super.key, required this.employee, required this.employeeProvider}); // Update constructor

  @override
  State<EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<EditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _employeeIdController;
  late TextEditingController _positionController;
  late TextEditingController _departmentController;
  bool _isLoading = false;
  String? _error;
  bool _dialogResult = false;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.employee['firstName']);
    _lastNameController =
        TextEditingController(text: widget.employee['lastName']);
    _emailController = TextEditingController(text: widget.employee['email']);
    _employeeIdController =
        TextEditingController(text: widget.employee['employeeId']);
    _positionController =
        TextEditingController(text: widget.employee['position']);
    _departmentController =
        TextEditingController(text: widget.employee['department']);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _employeeIdController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _updateEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final updates = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'employeeId': _employeeIdController.text.trim(),
        'position': _positionController.text.trim(),
        'department': _departmentController.text.trim(),
      };
      // Call updateEmployee on the EmployeeProvider
      await widget.employeeProvider
          .updateEmployee(widget.employee['_id'], updates);

      // No snackbar here; success is indicated by the dialog closing and list refreshing
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
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Edit Employee'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.person, color: colorScheme.primary),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.person, color: colorScheme.primary),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.email, color: colorScheme.primary),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _employeeIdController,
                decoration: InputDecoration(
                  labelText: 'Employee ID',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.badge, color: colorScheme.primary),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _positionController,
                decoration: InputDecoration(
                  labelText: 'Position',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.work, color: colorScheme.primary),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _departmentController,
                decoration: InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.business, color: colorScheme.primary),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: colorScheme.error, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateEmployee,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: colorScheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
