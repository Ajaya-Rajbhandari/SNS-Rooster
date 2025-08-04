import 'package:flutter/material.dart';
import 'package:sns_rooster/services/performance_review_service.dart';
import 'package:sns_rooster/services/performance_review_template_service.dart';
import 'package:sns_rooster/services/employee_service.dart';
import 'package:sns_rooster/services/user_service.dart';
import 'package:sns_rooster/services/api_service.dart';
import 'package:sns_rooster/config/api_config.dart';
import 'package:sns_rooster/utils/logger.dart';

class CreatePerformanceReviewDialog extends StatefulWidget {
  const CreatePerformanceReviewDialog({Key? key}) : super(key: key);

  @override
  State<CreatePerformanceReviewDialog> createState() =>
      _CreatePerformanceReviewDialogState();
}

class _CreatePerformanceReviewDialogState
    extends State<CreatePerformanceReviewDialog> {
  final PerformanceReviewService _reviewService =
      PerformanceReviewService(ApiService(baseUrl: ApiConfig.baseUrl));
  final PerformanceReviewTemplateService _templateService =
      PerformanceReviewTemplateService(ApiService(baseUrl: ApiConfig.baseUrl));
  final EmployeeService _employeeService =
      EmployeeService(ApiService(baseUrl: ApiConfig.baseUrl));
  final UserService _userService = UserService();

  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _templates = [];
  Map<String, dynamic>? _selectedEmployee;
  Map<String, dynamic>? _selectedTemplate;
  Map<String, dynamic>? _selectedReviewer;

  final _formKey = GlobalKey<FormState>();
  final _reviewPeriodController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _dueDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _dueDate;

  bool _isLoading = true;
  bool _isCreating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _reviewPeriodController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load employees, users, and templates in parallel
      final results = await Future.wait([
        _employeeService.getEmployees(),
        _userService.getUsers(),
        _templateService.getTemplates(),
      ]);

      if (mounted) {
        setState(() {
          _employees = results[0] as List<Map<String, dynamic>>;
          _users = (results[1] as List)
              .map((user) => user.toJson())
              .toList()
              .cast<Map<String, dynamic>>();
          _templates = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      Logger.error('Error loading data: $e');
    }
  }

  Future<void> _selectDate(BuildContext context,
      TextEditingController controller, DateTime? initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        if (controller == _startDateController) _startDate = picked;
        if (controller == _endDateController) _endDate = picked;
        if (controller == _dueDateController) _dueDate = picked;
      });
    }
  }

  void _onTemplateChanged(Map<String, dynamic>? template) {
    setState(() {
      _selectedTemplate = template;
      if (template != null) {
        // Auto-fill some fields based on template
        _reviewPeriodController.text = template['name'] ?? '';
      }
    });
  }

  Future<void> _createReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee')),
      );
      return;
    }
    if (_selectedReviewer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reviewer')),
      );
      return;
    }

    try {
      setState(() {
        _isCreating = true;
      });

      // Debug logging
      Logger.info('Creating performance review...');
      Logger.info(
          'Employee: ${_selectedEmployee!['firstName']} ${_selectedEmployee!['lastName']} (${_selectedEmployee!['_id']})');
      Logger.info(
          'Reviewer: ${_selectedReviewer!['firstName']} ${_selectedReviewer!['lastName']} (${_selectedReviewer!['id']})');

      final reviewData = {
        'employeeId': _selectedEmployee!['_id'],
        'reviewerId':
            _selectedReviewer!['id'], // UserModel uses 'id', not '_id'
        'reviewPeriod': _reviewPeriodController.text,
        'startDate': _startDateController.text,
        'endDate': _endDateController.text,
        'dueDate': _dueDateController.text,
        'goals': _selectedTemplate?['goals'] ?? [],
        'scores': {},
      };

      Logger.info('Review data: $reviewData');

      await _reviewService.createPerformanceReview(reviewData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Performance review created successfully')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      Logger.error('Error creating performance review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating review: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create Performance Review',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading data',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Employee Selection
                          const Text(
                            'Employee',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedEmployee,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Select Employee',
                            ),
                            items: _employees.map((employee) {
                              return DropdownMenuItem(
                                value: employee,
                                child: Text(
                                    '${employee['firstName']} ${employee['lastName']}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedEmployee = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select an employee';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Reviewer Selection
                          const Text(
                            'Reviewer',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedReviewer,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Select Reviewer',
                            ),
                            items: _users.map((user) {
                              return DropdownMenuItem(
                                value: user,
                                child: Text(
                                    '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedReviewer = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a reviewer';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Template Selection
                          const Text(
                            'Template (Optional)',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedTemplate,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Select Template (Optional)',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('No Template'),
                              ),
                              ..._templates.map((template) {
                                return DropdownMenuItem(
                                  value: template,
                                  child: Text(
                                      template['name'] ?? 'Unnamed Template'),
                                );
                              }),
                            ],
                            onChanged: _onTemplateChanged,
                          ),
                          const SizedBox(height: 16),

                          // Review Period
                          TextFormField(
                            controller: _reviewPeriodController,
                            decoration: const InputDecoration(
                              labelText: 'Review Period',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., Q4 2024, Annual 2024',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a review period';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Date Fields
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _startDateController,
                                  decoration: const InputDecoration(
                                    labelText: 'Start Date',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate(context,
                                      _startDateController, _startDate),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select start date';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _endDateController,
                                  decoration: const InputDecoration(
                                    labelText: 'End Date',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDate(
                                      context, _endDateController, _endDate),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select end date';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _dueDateController,
                            decoration: const InputDecoration(
                              labelText: 'Due Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: () => _selectDate(
                                context, _dueDateController, _dueDate),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select due date';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isCreating ? null : _createReview,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: _isCreating
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Text('Create Review'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isCreating
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
