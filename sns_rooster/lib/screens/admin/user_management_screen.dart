import 'package:flutter/material.dart';
import 'package:sns_rooster/utils/logger.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../../widgets/admin_side_navigation.dart';

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

    log('Attempting to load users...');

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      log('Auth Token: $token');

      log('DEBUG: ApiConfig.baseUrl = \'${ApiConfig.baseUrl}\'');
      log('DEBUG: Auth Token = $token');

      if (token == null || token.isEmpty) {
        log('Authentication token is missing or empty.');
        setState(() {
          _error = 'Authentication token is missing.';
          _isLoading = false;
        });
        return;
      }

      // Add showInactive parameter to the URL
      final url =
          '${ApiConfig.baseUrl}/auth/users${_showInactive ? '?showInactive=true' : ''}';
      log('Requesting users from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      log('Response Status Code: ${response.statusCode}');
      log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Backend returns a list, not a map
        final List<dynamic> usersJson = json.decode(response.body);
        setState(() {
          _users = usersJson.cast<Map<String, dynamic>>();
          _isLoading = false;
          _error = null; // Clear error on successful load
        });
        log('Users loaded successfully: \\${_users.length} users');
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Session expired or invalid token. Please log in again.';
          _isLoading = false;
        });
        // Show a snackbar for better UX
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Session expired. Please log in again.')),
          );
        }
        // Navigate to login screen
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        log('Failed to load users. Status: ${response.statusCode}, Body: ${response.body}');
        if (showErrors) {
          setState(() {
            _error =
                'Failed to load users: ${response.statusCode} ${response.body}';
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e, stackTrace) {
      log('NETWORK ERROR during user list reload: $e');
      log('Error loading users: $e');
      log('Stack trace: $stackTrace');
      if (showErrors) {
        setState(() {
          _error = 'Failed to load users: $e';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetFormFields() {
    _formKey.currentState?.reset();
    _emailController.clear();
    _passwordController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: json.encode({
          'email': _emailController.text,
          'password': _passwordController.text,
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
        }),
      );

      log('Create user response status: \\${response.statusCode}');
      log('Create user response body: \\${response.body}');

      if (!mounted) return;
      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully')),
        );
        _resetFormFields();
        // Await user list reload before finishing
        await _loadUsers(showErrors: true);
        // Do NOT call setState here; _loadUsers handles _isLoading and _error
      } else {
        setState(() {
          _error = data['message'] ?? 'Failed to create user';
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/auth/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: json.encode({'isActive': !currentStatus}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        _loadUsers();
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to update user status'),
          ),
        );
      }
    } catch (e) {
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.delete(
        Uri.parse(
            '${ApiConfig.baseUrl}/auth/users/$userId'), // Assuming this is the delete endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
        _loadUsers(); // Refresh the user list
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ??
                'Failed to delete user: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Network error occurred while deleting user')),
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
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _createUser,
                                  child: const Text('Create User'),
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
                                            onPressed: () =>
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
