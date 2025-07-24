import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../../widgets/admin_side_navigation.dart';
import '../../services/api_service.dart';
import '../../utils/logger.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _users = [];
  bool _showInactive = false; // Track whether to show inactive users
  String? _selectedRole;
  final List<String> _roles = ['employee', 'admin'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool showErrors = true}) async {
    setState(() {
      _isLoading = true;
      _error = null; // Always clear error at the start of loading
    });

    Logger.info('Attempting to load users...');

    try {
      final apiService = ApiService(baseUrl: ApiConfig.baseUrl);

      // Add showInactive parameter to the URL
      final endpoint =
          '/auth/users${_showInactive ? '?showInactive=true' : ''}';
      Logger.info('Requesting users from: ${ApiConfig.baseUrl}$endpoint');

      final response = await apiService.get(endpoint);

      Logger.info('Load users response success: ${response.success}');
      Logger.info('Load users response message: ${response.message}');

      if (response.success) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response.data ?? []);
          _isLoading = false;
          _error = null; // Clear error on successful load
        });
        Logger.info('Users loaded successfully: ${_users.length} users');
      } else {
        setState(() {
          _error = response.message ?? 'Failed to load users';
          _isLoading = false;
        });
        // Show a snackbar for better UX
        if (mounted && showErrors) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_error ?? 'Failed to load users')),
          );
        }
      }
    } catch (e) {
      Logger.error('Error loading users: $e');
      setState(() {
        _error = 'Network error occurred';
        _isLoading = false;
      });
      if (mounted && showErrors) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error occurred')),
        );
      }
    }
  }

  void _resetFormFields() {
    _formKey.currentState?.reset();
    _emailController.clear();
    _passwordController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    setState(() {
      _selectedRole = null;
    });
    // _generateEmployeeId(); // Also, auto-generate Employee ID after form reset
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService(baseUrl: ApiConfig.baseUrl);

      final userData = {
        'email': _emailController.text,
        'password': _passwordController.text,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'role': _selectedRole,
      };

      Logger.info('Creating user with data: $userData');

      final response = await apiService.post('/auth/register', userData);

      Logger.info('Create user response success: ${response.success}');
      Logger.info('Create user response message: ${response.message}');

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully')),
        );
        _resetFormFields();
        // Await user list reload before finishing
        await _loadUsers(showErrors: true);
        // Do NOT call setState here; _loadUsers handles _isLoading and _error
      } else {
        setState(() {
          _error = response.message ?? 'Failed to create user';
          _isLoading = false;
        });
        // Show error in a SnackBar for visibility
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_error ?? 'Failed to create user')),
          );
        }
      }
    } catch (e) {
      Logger.error('Error creating user: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Network error occurred';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    if (!mounted) return;
    try {
      final apiService = ApiService(baseUrl: ApiConfig.baseUrl);
      final response = await apiService
          .patch('/auth/users/$userId', {'isActive': !currentStatus});

      if (!mounted) return;
      if (response.success) {
        _loadUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to update user status'),
          ),
        );
      }
    } catch (e) {
      Logger.error('Error toggling user status: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Network error occurred')));
    }
  }

  Future<void> _deleteUser(String userId) async {
    if (!mounted) return;

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
              'Are you sure you want to delete this user? This action cannot be undone.'),
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

    if (confirmed == null || !confirmed) {
      return; // User cancelled the dialog
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      final apiService = ApiService(baseUrl: ApiConfig.baseUrl);
      final response = await apiService.delete('/auth/users/$userId');

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
        _loadUsers(); // Refresh the user list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to delete user'),
          ),
        );
      }
    } catch (e) {
      Logger.error('Error deleting user: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error occurred')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).user?['_id'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          // Toggle button to show/hide inactive users
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
                  _loadUsers(); // Reload users with new filter
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
      drawer: const AdminSideNavigation(currentRoute: '/user_management'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_users.isNotEmpty)
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter an email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                TextFormField(
                                  controller: _firstNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'First Name',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a first name';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    // _generateEmployeeId();
                                  },
                                ),
                                TextFormField(
                                  controller: _lastNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Last Name',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a last name';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    // _generateEmployeeId();
                                  },
                                ),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Role',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _selectedRole,
                                  items: _roles.map((String role) {
                                    return DropdownMenuItem<String>(
                                      value: role,
                                      child: Text(role[0].toUpperCase() +
                                          role.substring(1)),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedRole = newValue;
                                    });
                                  },
                                  validator: (value) => value == null
                                      ? 'Please select a role'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _createUser,
                                        child: const Text('Create User'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _resetFormFields,
                                        child: const Text('Clear Form'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'User List',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Reload User List',
                            onPressed: _isLoading ? null : () => _loadUsers(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'User List',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_users.isEmpty)
                                const Center(
                                  child: Text(
                                    'No users found.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _users.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final user = _users[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        child: Text(
                                          (user['firstName'] != null &&
                                                  user['firstName'].isNotEmpty)
                                              ? user['firstName'][0]
                                                  .toUpperCase()
                                              : '?',
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              (user['firstName'] ?? '') +
                                                  (user['lastName'] != null &&
                                                          user['lastName']
                                                              .isNotEmpty
                                                      ? ' ' + user['lastName']
                                                      : ''),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          // Show inactive badge if user is inactive
                                          if (user['isActive'] == false)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
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
                                      subtitle: Text(user['email'] ?? ''),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Switch(
                                            value: user['isActive'] ?? false,
                                            onChanged: (value) =>
                                                _toggleUserStatus(
                                              user['_id'],
                                              user['isActive'],
                                            ),
                                            activeColor: Colors.green,
                                            inactiveThumbColor: Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: user['_id'] ==
                                                    currentUserId
                                                ? () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                            'Action Not Allowed'),
                                                        content: const Text(
                                                            'You cannot delete your own admin account.'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(),
                                                            child: const Text(
                                                                'OK'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }
                                                : () =>
                                                    _deleteUser(user['_id']),
                                            tooltip: 'Delete User',
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : (_error != null)
                  ? Center(
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                    )
                  : const Center(
                      child: Text('No users found.',
                          style: TextStyle(color: Colors.grey)),
                    ),
    );
  }
}
