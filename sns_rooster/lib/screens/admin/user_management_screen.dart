import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/auth_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = 'employee';
  String _selectedDepartment = 'IT';
  String _selectedPosition = 'Developer';
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _users = [];

  // API base URL
  final String _baseUrl = 'http://10.0.2.2:5000/api'; // For Android emulator
  // Use 'http://localhost:5000/api' for iOS simulator

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse('$_baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _users = List<Map<String, dynamic>>.from(data['users']);
        });
      } else {
        setState(() {
          _error = 'Failed to load users';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Network error occurred';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
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
        Uri.parse('$_baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: json.encode({
          'email': _emailController.text,
          'password': _passwordController.text,
          'name': _nameController.text,
          'role': _selectedRole,
          'department': _selectedDepartment,
          'position': _selectedPosition,
        }),
      );

      if (!mounted) return;
      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully')),
        );
        _formKey.currentState!.reset();
        _emailController.clear();
        _passwordController.clear();
        _nameController.clear();
        _loadUsers();
      } else {
        setState(() {
          _error = data['message'] ?? 'Failed to create user';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Network error occurred';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    if (!mounted) return;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.patch(
        Uri.parse('$_baseUrl/users/$userId'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                )
              : SingleChildScrollView(
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
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedRole,
                                  decoration: const InputDecoration(
                                    labelText: 'Role',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'admin',
                                      child: Text('Admin'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'manager',
                                      child: Text('Manager'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'employee',
                                      child: Text('Employee'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedDepartment,
                                  decoration: const InputDecoration(
                                    labelText: 'Department',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'IT',
                                      child: Text('IT'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'HR',
                                      child: Text('HR'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Finance',
                                      child: Text('Finance'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Operations',
                                      child: Text('Operations'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDepartment = value!;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedPosition,
                                  decoration: const InputDecoration(
                                    labelText: 'Position',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Developer',
                                      child: Text('Developer'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Designer',
                                      child: Text('Designer'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Manager',
                                      child: Text('Manager'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Analyst',
                                      child: Text('Analyst'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPosition = value!;
                                    });
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
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _users.length,
                                itemBuilder: (context, index) {
                                  final user = _users[index];
                                  return ListTile(
                                    title: Text(user['name'] ?? ''),
                                    subtitle: Text(user['email'] ?? ''),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(user['role'] ?? ''),
                                        const SizedBox(width: 8),
                                        Switch(
                                          value: user['isActive'] ?? false,
                                          onChanged: (value) =>
                                              _toggleUserStatus(
                                            user['_id'],
                                            user['isActive'],
                                          ),
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
                ),
    );
  }
}
