import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(
      BuildContext context, Map<String, dynamic> user, String? currentUserId) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    (user['firstName'] != null && user['firstName'].isNotEmpty)
                        ? user['firstName'][0].toUpperCase()
                        : '?',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (user['firstName'] ?? '') +
                            (user['lastName'] != null &&
                                    user['lastName'].isNotEmpty
                                ? ' ' + user['lastName']
                                : ''),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(user['email'] ?? ''),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(
                  value: user['isActive'] ?? false,
                  onChanged: (value) => _toggleUserStatus(
                    user['_id'],
                    user['isActive'],
                  ),
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: user['_id'] == currentUserId
                      ? () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Action Not Allowed'),
                              content: const Text(
                                  'You cannot delete your own admin account.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      : () => _deleteUser(user['_id']),
                  tooltip: 'Delete User',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 60, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No users found.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add new users to get started.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).user?['_id'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadUsers(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AdminSideNavigation(currentRoute: '/user_management'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
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
                            'Total Users',
                            '${_users.length}',
                            Icons.people,
                            colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Active',
                            '${_users.where((user) => user['isActive'] != false).length}',
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Admins',
                            '${_users.where((user) => user['role'] == 'admin').length}',
                            Icons.admin_panel_settings,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Modern Filter Section
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
                            Icon(Icons.filter_list,
                                color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Filters',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Status Toggle
                        Row(
                          children: [
                            FilterChip(
                              label: Text(
                                  _showInactive ? 'All Users' : 'Active Only'),
                              selected: true,
                              onSelected: (value) {
                                setState(() {
                                  _showInactive = value;
                                });
                                _loadUsers();
                              },
                              backgroundColor: colorScheme.primaryContainer,
                              selectedColor: colorScheme.primaryContainer,
                              labelStyle: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Add User Section
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
                            Icon(Icons.person_add,
                                color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Add New User',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _firstNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'First Name',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a first name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _lastNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Last Name',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a last name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _emailController,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        border: OutlineInputBorder(),
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
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedRole,
                                      decoration: const InputDecoration(
                                        labelText: 'Role',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: _roles.map((role) {
                                        return DropdownMenuItem(
                                          value: role,
                                          child: Text(role.toUpperCase()),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedRole = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select a role';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  border: OutlineInputBorder(),
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
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _createUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Create User'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // User List Section
                  if (_users.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Icon(Icons.list,
                              color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'User List',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ..._users
                        .map((user) =>
                            _buildUserCard(context, user, currentUserId))
                        .toList(),
                  ] else ...[
                    _buildEmptyState(context),
                  ],
                ],
              ),
            ),
    );
  }
}
