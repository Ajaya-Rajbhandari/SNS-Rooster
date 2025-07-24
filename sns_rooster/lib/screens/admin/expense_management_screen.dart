import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sns_rooster/providers/auth_provider.dart';
import 'package:sns_rooster/providers/feature_provider.dart';
import 'package:sns_rooster/services/api_service.dart';
import 'package:sns_rooster/utils/logger.dart';
import 'package:sns_rooster/widgets/admin_side_navigation.dart';
import 'package:sns_rooster/config/api_config.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  State<ExpenseManagementScreen> createState() =>
      _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  final ApiService _apiService = ApiService(baseUrl: ApiConfig.baseUrl);
  List<Map<String, dynamic>> _expenses = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _isCreating = false;
  String _selectedStatus = 'all';
  String _selectedCategory = 'all';
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategoryType = 'travel';
  String _selectedLocation = '';
  List<Map<String, dynamic>> _locations = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _loadStats();
    _loadLocations();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    try {
      setState(() => _isLoading = true);

      String url = '/expenses';
      final params = <String, String>{};
      if (_selectedStatus != 'all') params['status'] = _selectedStatus;
      if (_selectedCategory != 'all') params['category'] = _selectedCategory;

      if (params.isNotEmpty) {
        url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      final response = await _apiService.get(url);

      if (response.success) {
        setState(() {
          _expenses =
              List<Map<String, dynamic>>.from(response.data['expenses']);
          _isLoading = false;
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      Logger.error('Error loading expenses: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading expenses: $e')),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final response = await _apiService.get('/expenses/stats');

      if (response.success) {
        setState(() {
          _stats = response.data['stats'];
        });
      }
    } catch (e) {
      Logger.error('Error loading expense stats: $e');
    }
  }

  Future<void> _loadLocations() async {
    try {
      final response = await _apiService.get('/locations');

      if (response.success) {
        setState(() {
          _locations =
              List<Map<String, dynamic>>.from(response.data['locations']);
        });
      }
    } catch (e) {
      Logger.error('Error loading locations: $e');
    }
  }

  Future<void> _createExpense() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isCreating = true);

      final expenseData = {
        'employeeId':
            Provider.of<AuthProvider>(context, listen: false).user?['_id'],
        'locationId': _selectedLocation.isNotEmpty ? _selectedLocation : null,
        'category': _selectedCategoryType,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'amount': double.parse(_amountController.text),
        'currency': 'NPR',
      };

      final response = await _apiService.post('/expenses', expenseData);

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense submitted successfully')),
          );
          Navigator.of(context).pop();
          _loadExpenses();
          _loadStats();
        }
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      Logger.error('Error creating expense: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting expense: $e')),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _approveExpense(String expenseId) async {
    try {
      final response =
          await _apiService.post('/expenses/$expenseId/approve', {});

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense approved successfully')),
          );
          _loadExpenses();
          _loadStats();
        }
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      Logger.error('Error approving expense: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving expense: $e')),
        );
      }
    }
  }

  Future<void> _rejectExpense(String expenseId, String reason) async {
    try {
      final response = await _apiService.post('/expenses/$expenseId/reject', {
        'reason': reason,
      });

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense rejected successfully')),
          );
          _loadExpenses();
          _loadStats();
        }
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      Logger.error('Error rejecting expense: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting expense: $e')),
        );
      }
    }
  }

  void _showCreateExpenseDialog() {
    _titleController.clear();
    _descriptionController.clear();
    _amountController.clear();
    _selectedCategoryType = 'travel';
    _selectedLocation = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit New Expense'),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Expense Title *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Expense title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount (NPR) *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Amount is required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategoryType,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'travel',
                          'meals',
                          'office_supplies',
                          'equipment',
                          'software',
                          'training',
                          'entertainment',
                          'transportation',
                          'accommodation',
                          'other'
                        ]
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category
                                      .replaceAll('_', ' ')
                                      .toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) _selectedCategoryType = value;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_locations.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedLocation.isEmpty ? null : _selectedLocation,
                    decoration: const InputDecoration(
                      labelText: 'Location (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('No specific location'),
                      ),
                      ..._locations.map((location) => DropdownMenuItem(
                            value: location['_id'],
                            child: Text(location['name']),
                          )),
                    ],
                    onChanged: (value) {
                      _selectedLocation = value ?? '';
                    },
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isCreating ? null : _createExpense,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String expenseId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.of(context).pop();
                _rejectExpense(expenseId, reasonController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'paid':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final featureProvider = Provider.of<FeatureProvider>(context);

    // Check if expense management feature is available
    if (!featureProvider.isFeatureEnabled('expenseManagement')) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Expense Management'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Expense Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'This feature is available in Professional and Enterprise plans',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 16),
              Text(
                'Upgrade your plan to access expense management features',
                style: TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadExpenses();
              _loadStats();
            },
          ),
        ],
      ),
      drawer: const AdminSideNavigation(currentRoute: '/expense_management'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics Cards
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Icon(Icons.receipt,
                                    size: 32, color: Colors.blue),
                                const SizedBox(height: 8),
                                Text(
                                  '${_stats['totalCount'] ?? 0}',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text('Total Expenses'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Icon(Icons.pending,
                                    size: 32, color: Colors.orange),
                                const SizedBox(height: 8),
                                Text(
                                  '${_stats['pendingCount'] ?? 0}',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text('Pending'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Icon(Icons.check_circle,
                                    size: 32, color: Colors.green),
                                const SizedBox(height: 8),
                                Text(
                                  '${_stats['approvedCount'] ?? 0}',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text('Approved'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                                value: 'all', child: Text('All Status')),
                            const DropdownMenuItem(
                                value: 'pending', child: Text('Pending')),
                            const DropdownMenuItem(
                                value: 'approved', child: Text('Approved')),
                            const DropdownMenuItem(
                                value: 'rejected', child: Text('Rejected')),
                            const DropdownMenuItem(
                                value: 'paid', child: Text('Paid')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedStatus = value);
                              _loadExpenses();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                                value: 'all', child: Text('All Categories')),
                            const DropdownMenuItem(
                                value: 'travel', child: Text('Travel')),
                            const DropdownMenuItem(
                                value: 'meals', child: Text('Meals')),
                            const DropdownMenuItem(
                                value: 'office_supplies',
                                child: Text('Office Supplies')),
                            const DropdownMenuItem(
                                value: 'equipment', child: Text('Equipment')),
                            const DropdownMenuItem(
                                value: 'software', child: Text('Software')),
                            const DropdownMenuItem(
                                value: 'training', child: Text('Training')),
                            const DropdownMenuItem(
                                value: 'entertainment',
                                child: Text('Entertainment')),
                            const DropdownMenuItem(
                                value: 'transportation',
                                child: Text('Transportation')),
                            const DropdownMenuItem(
                                value: 'accommodation',
                                child: Text('Accommodation')),
                            const DropdownMenuItem(
                                value: 'other', child: Text('Other')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCategory = value);
                              _loadExpenses();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Expenses List
                Expanded(
                  child: _expenses.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No expenses found',
                                style:
                                    TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Submit your first expense to get started',
                                style:
                                    TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _expenses.length,
                          itemBuilder: (context, index) {
                            final expense = _expenses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _getStatusColor(expense['status']),
                                  child: Icon(
                                    _getStatusIcon(expense['status']),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  expense['title'] ?? 'Unknown Expense',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${expense['category']?.toString().replaceAll('_', ' ').toUpperCase()} • ${expense['employeeId']?['firstName']} ${expense['employeeId']?['lastName']}',
                                    ),
                                    Text(
                                      'Amount: NPR ${expense['amount']?.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Status: ${expense['status']?.toString().toUpperCase()}',
                                      style: TextStyle(
                                        color:
                                            _getStatusColor(expense['status']),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (expense['description']?.isNotEmpty ==
                                        true)
                                      Text(
                                        expense['description'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                                trailing: expense['status'] == 'pending'
                                    ? PopupMenuButton(
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'approve',
                                            child: Row(
                                              children: [
                                                Icon(Icons.check,
                                                    color: Colors.green),
                                                SizedBox(width: 8),
                                                Text('Approve',
                                                    style: TextStyle(
                                                        color: Colors.green)),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'reject',
                                            child: Row(
                                              children: [
                                                Icon(Icons.close,
                                                    color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Reject',
                                                    style: TextStyle(
                                                        color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'approve':
                                              _approveExpense(expense['_id']);
                                              break;
                                            case 'reject':
                                              _showRejectDialog(expense['_id']);
                                              break;
                                          }
                                        },
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateExpenseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check;
      case 'rejected':
        return Icons.close;
      case 'paid':
        return Icons.payment;
      default:
        return Icons.receipt;
    }
  }
}
