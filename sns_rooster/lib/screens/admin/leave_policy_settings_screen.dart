import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../config/leave_config.dart';
import '../../services/global_notification_service.dart';

class LeavePolicySettingsScreen extends StatefulWidget {
  const LeavePolicySettingsScreen({Key? key}) : super(key: key);

  @override
  State<LeavePolicySettingsScreen> createState() =>
      _LeavePolicySettingsScreenState();
}

class _LeavePolicySettingsScreenState extends State<LeavePolicySettingsScreen> {
  List<Map<String, dynamic>> _policies = [];
  Map<String, dynamic>? _defaultPolicy;
  bool _isLoading = true;
  bool _isCreating = false;
  final bool _isUpdating = false;

  // Form controllers for creating/editing policy
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Leave type controllers
  final _annualLeaveController = TextEditingController();
  final _sickLeaveController = TextEditingController();
  final _casualLeaveController = TextEditingController();
  final _maternityLeaveController = TextEditingController();
  final _paternityLeaveController = TextEditingController();
  final _unpaidLeaveController = TextEditingController();

  // Rules controllers
  final _minNoticeController = TextEditingController();
  final _maxConsecutiveController = TextEditingController();
  final _maxCarryOverController = TextEditingController();

  // Boolean values
  bool _allowHalfDays = false;
  bool _allowCancellation = true;
  bool _carryOverBalance = false;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _loadPolicies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _annualLeaveController.dispose();
    _sickLeaveController.dispose();
    _casualLeaveController.dispose();
    _maternityLeaveController.dispose();
    _paternityLeaveController.dispose();
    _unpaidLeaveController.dispose();
    _minNoticeController.dispose();
    _maxConsecutiveController.dispose();
    _maxCarryOverController.dispose();
    super.dispose();
  }

  Future<void> _loadPolicies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final api = ApiService(baseUrl: ApiConfig.baseUrl);
      final response = await api.get('/leave-policies/simple');

      if (response.success && response.data != null) {
        setState(() {
          _policies = List<Map<String, dynamic>>.from(response.data);
          _defaultPolicy = _policies.firstWhere(
            (policy) => policy['isDefault'] == true,
            orElse: () => {},
          );
        });
      }
    } catch (e) {
      print('Error loading policies: $e');
      final notificationService =
          Provider.of<GlobalNotificationService>(context, listen: false);
      notificationService.showError('Failed to load leave policies');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreatePolicyDialog() {
    _resetForm();
    _showPolicyDialog('Create Leave Policy');
  }

  void _showEditPolicyDialog(Map<String, dynamic> policy) {
    _populateForm(policy);
    _showPolicyDialog('Edit Leave Policy');
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _annualLeaveController.text = '12';
    _sickLeaveController.text = '10';
    _casualLeaveController.text = '5';
    _maternityLeaveController.text = '90';
    _paternityLeaveController.text = '10';
    _unpaidLeaveController.text = '0';
    _minNoticeController.text = '1';
    _maxConsecutiveController.text = '30';
    _maxCarryOverController.text = '5';
    _allowHalfDays = false;
    _allowCancellation = true;
    _carryOverBalance = false;
    _isDefault = false;
  }

  void _populateForm(Map<String, dynamic> policy) {
    _nameController.text = policy['name'] ?? '';
    _descriptionController.text = policy['description'] ?? '';

    final leaveTypes = policy['leaveTypes'] ?? {};
    _annualLeaveController.text =
        (leaveTypes['annualLeave']?['totalDays'] ?? 12).toString();
    _sickLeaveController.text =
        (leaveTypes['sickLeave']?['totalDays'] ?? 10).toString();
    _casualLeaveController.text =
        (leaveTypes['casualLeave']?['totalDays'] ?? 5).toString();
    _maternityLeaveController.text =
        (leaveTypes['maternityLeave']?['totalDays'] ?? 90).toString();
    _paternityLeaveController.text =
        (leaveTypes['paternityLeave']?['totalDays'] ?? 10).toString();
    _unpaidLeaveController.text =
        (leaveTypes['unpaidLeave']?['totalDays'] ?? 0).toString();

    final rules = policy['rules'] ?? {};
    _minNoticeController.text = (rules['minNoticeDays'] ?? 1).toString();
    _maxConsecutiveController.text =
        (rules['maxConsecutiveDays'] ?? 30).toString();
    _maxCarryOverController.text = (rules['maxCarryOverDays'] ?? 5).toString();
    _allowHalfDays = rules['allowHalfDays'] ?? false;
    _allowCancellation = rules['allowCancellation'] ?? true;
    _carryOverBalance = rules['carryOverBalance'] ?? false;
    _isDefault = policy['isDefault'] ?? false;
  }

  void _showPolicyDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Basic Information
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Policy Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Policy name is required';
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
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Leave Entitlements
                  const Text(
                    'Leave Entitlements (Days per Year)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _annualLeaveController,
                          decoration: const InputDecoration(
                            labelText: 'Annual Leave',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _sickLeaveController,
                          decoration: const InputDecoration(
                            labelText: 'Sick Leave',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _casualLeaveController,
                          decoration: const InputDecoration(
                            labelText: 'Casual Leave',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _maternityLeaveController,
                          decoration: const InputDecoration(
                            labelText: 'Maternity Leave',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _paternityLeaveController,
                          decoration: const InputDecoration(
                            labelText: 'Paternity Leave',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _unpaidLeaveController,
                          decoration: const InputDecoration(
                            labelText: 'Unpaid Leave',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Policy Rules
                  const Text(
                    'Policy Rules',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minNoticeController,
                          decoration: const InputDecoration(
                            labelText: 'Min Notice (Days)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _maxConsecutiveController,
                          decoration: const InputDecoration(
                            labelText: 'Max Consecutive Days',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _maxCarryOverController,
                    decoration: const InputDecoration(
                      labelText: 'Max Carry Over Days',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Toggle switches
                  SwitchListTile(
                    title: const Text('Allow Half Days'),
                    subtitle:
                        const Text('Employees can request half-day leaves'),
                    value: _allowHalfDays,
                    onChanged: (value) {
                      setDialogState(() {
                        _allowHalfDays = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Allow Cancellation'),
                    subtitle:
                        const Text('Employees can cancel approved leaves'),
                    value: _allowCancellation,
                    onChanged: (value) {
                      setDialogState(() {
                        _allowCancellation = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Carry Over Balance'),
                    subtitle:
                        const Text('Unused leave carries over to next year'),
                    value: _carryOverBalance,
                    onChanged: (value) {
                      setDialogState(() {
                        _carryOverBalance = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Set as Default'),
                    subtitle: const Text(
                        'Make this the default policy for new employees'),
                    value: _isDefault,
                    onChanged: (value) {
                      setDialogState(() {
                        _isDefault = value;
                      });
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
              onPressed: _isCreating || _isUpdating ? null : _savePolicy,
              child: _isCreating || _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePolicy() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final api = ApiService(baseUrl: ApiConfig.baseUrl);

      final policyData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'isDefault': _isDefault,
        'leaveTypes': {
          'annualLeave': {
            'totalDays': int.parse(_annualLeaveController.text),
            'description': LeaveConfig.getLeaveTypeDescription('Annual Leave'),
            'isActive': true,
          },
          'sickLeave': {
            'totalDays': int.parse(_sickLeaveController.text),
            'description': LeaveConfig.getLeaveTypeDescription('Sick Leave'),
            'isActive': true,
          },
          'casualLeave': {
            'totalDays': int.parse(_casualLeaveController.text),
            'description': LeaveConfig.getLeaveTypeDescription('Casual Leave'),
            'isActive': true,
          },
          'maternityLeave': {
            'totalDays': int.parse(_maternityLeaveController.text),
            'description':
                LeaveConfig.getLeaveTypeDescription('Maternity Leave'),
            'isActive': true,
          },
          'paternityLeave': {
            'totalDays': int.parse(_paternityLeaveController.text),
            'description':
                LeaveConfig.getLeaveTypeDescription('Paternity Leave'),
            'isActive': true,
          },
          'unpaidLeave': {
            'totalDays': int.parse(_unpaidLeaveController.text),
            'description': LeaveConfig.getLeaveTypeDescription('Unpaid Leave'),
            'isActive': true,
          },
        },
        'rules': {
          'minNoticeDays': int.parse(_minNoticeController.text),
          'maxConsecutiveDays': int.parse(_maxConsecutiveController.text),
          'allowHalfDays': _allowHalfDays,
          'allowCancellation': _allowCancellation,
          'carryOverBalance': _carryOverBalance,
          'maxCarryOverDays': int.parse(_maxCarryOverController.text),
          'leaveYearStartMonth': 1,
          'leaveYearStartDay': 1,
        },
      };

      final response = await api.post('/leave-policies/simple', policyData);

      if (response.success) {
        Navigator.of(context).pop();
        await _loadPolicies();
        final notificationService =
            Provider.of<GlobalNotificationService>(context, listen: false);
        notificationService.showSuccess('Leave policy saved successfully');
      } else {
        throw Exception(response.message ?? 'Failed to save policy');
      }
    } catch (e) {
      print('Error saving policy: $e');
      final notificationService =
          Provider.of<GlobalNotificationService>(context, listen: false);
      notificationService.showError('Failed to save leave policy');
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  Future<void> _deletePolicy(String policyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Policy'),
        content: const Text(
            'Are you sure you want to delete this policy? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final api = ApiService(baseUrl: ApiConfig.baseUrl);
      final response = await api.delete('/leave-policies/simple/$policyId');

      if (response.success) {
        await _loadPolicies();
        final notificationService =
            Provider.of<GlobalNotificationService>(context, listen: false);
        notificationService.showSuccess('Policy deleted successfully');
      } else {
        throw Exception(response.message ?? 'Failed to delete policy');
      }
    } catch (e) {
      print('Error deleting policy: $e');
      final notificationService =
          Provider.of<GlobalNotificationService>(context, listen: false);
      notificationService.showError('Failed to delete policy');
    }
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
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

  Widget _buildPolicyCard(
      BuildContext context, Map<String, dynamic> policy, bool isDefault) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(policy['name'] ?? 'Unnamed Policy'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (policy['description'] != null) Text(policy['description']),
            const SizedBox(height: 4),
            Row(
              children: [
                if (isDefault)
                  const Chip(
                    label: Text('DEFAULT'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                const SizedBox(width: 8),
                Text(
                  'Created: ${DateTime.parse(policy['createdAt']).toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditPolicyDialog(policy);
            } else if (value == 'delete') {
              _deletePolicy(policy['_id']);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            if (!isDefault)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.policy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No policies found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first leave policy to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Policy Settings'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPolicies,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPolicies,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats Section
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Total Policies',
                              '${_policies.length}',
                              Icons.policy,
                              colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Default Policy',
                              _defaultPolicy != null ? 'Active' : 'None',
                              Icons.star,
                              Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Custom Policies',
                              '${_policies.where((p) => p['isDefault'] != true).length}',
                              Icons.settings,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Header Section
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.policy,
                                  color: colorScheme.primary, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Leave Policies',
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Manage leave entitlements and rules for your company',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _showCreatePolicyDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Policy'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Default Policy Section
                    if (_defaultPolicy != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Default Policy',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildPolicyCard(context, _defaultPolicy!, true),
                          ],
                        ),
                      ),
                    ],

                    // All Policies Section
                    if (_policies.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Icon(Icons.list,
                                color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'All Policies',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._policies
                          .where((policy) => policy['isDefault'] != true)
                          .map((policy) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: _buildPolicyCard(context, policy, false),
                              ))
                          .toList(),
                    ],

                    // Empty State
                    if (_policies.isEmpty) _buildEmptyState(context),
                  ],
                ),
              ),
            ),
    );
  }
}
