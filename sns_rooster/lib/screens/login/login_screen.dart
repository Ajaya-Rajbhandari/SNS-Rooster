import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import '../admin/user_management_screen.dart';
import 'package:flutter/foundation.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isResetPassword = false;
  bool _obscurePassword = true;
  final _resetTokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _error;
  bool _autoFill = false;
  bool _autoLogin = false;
  String _selectedRole = 'employee'; // Default to employee for auto-fill

  // Test credentials for developer convenience
  static const String _devEmployeeEmail = 'testuser@example.com';
  static const String _devEmployeePassword = 'password123';
  static const String _devAdminEmail =
      'adminuser@example.com'; // New admin test email
  static const String _devAdminPassword =
      'adminpass2'; // New admin test password

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();

    // Auto-fill and auto-login logic (debug only)
    _updateAutoFillFields();
  }

  void _updateAutoFillFields() {
    assert(() {
      if (_autoFill) {
        _emailController.text =
            _selectedRole == 'admin' ? _devAdminEmail : _devEmployeeEmail;
        _passwordController.text =
            _selectedRole == 'admin' ? _devAdminPassword : _devEmployeePassword;
        if (_autoLogin) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _handleLogin();
          });
        }
      }
      return true;
    }());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetTokenController.dispose();
    _newPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    print('Starting login process...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Calling auth provider login...');
      await Provider.of<AuthProvider>(context, listen: false)
          .login(_emailController.text.trim(), _passwordController.text);

      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print(
          'Login completed - Auth status: ${authProvider.isAuthenticated}, Error: ${authProvider.error}');

      if (authProvider.isAuthenticated) {
        print('User authenticated, checking role...');
        final user = authProvider.user;
        print('User data: $user');

        if (user != null) {
          final role = user['role'];
          print('User role: $role');

          if (role == 'admin') {
            print('Navigating to admin dashboard...');
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
          } else {
            print('Navigating to employee dashboard...');
            Navigator.pushReplacementNamed(context, '/employee_dashboard');
          }
        } else {
          print('User data is null after authentication');
          setState(() {
            _error = 'Authentication error: User data not found';
          });
        }
      } else {
        print('Authentication failed');
        setState(() {
          _error = authProvider.error ?? 'Authentication failed';
        });
      }
    } catch (e) {
      print('Login error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'An error occurred during login';
      });
    } finally {
      if (mounted) {
        print('Login process completed, updating loading state');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!_isResetPassword) {
        await authProvider.requestPasswordReset(_emailController.text.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset instructions sent to your email'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isResetPassword = true;
        });
      } else {
        await authProvider.resetPassword(
          _resetTokenController.text.trim(),
          _newPasswordController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Password reset successful. Please login with your new password.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isResetPassword = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Debug toggles (only in debug mode)
                      if (kDebugMode) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              title: DropdownButtonFormField<String>(
                                value: _selectedRole,
                                decoration: InputDecoration(
                                  labelText: 'Auto-login Role',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedRole = newValue!;
                                    _updateAutoFillFields();
                                  });
                                },
                                items: <String>[
                                  'employee',
                                  'admin'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value.capitalize()),
                                  );
                                }).toList(),
                              ),
                            ),
                            SwitchListTile(
                              title: const Text('Auto-fill credentials'),
                              value: _autoFill,
                              onChanged: (val) {
                                setState(() {
                                  _autoFill = val;
                                  _updateAutoFillFields();
                                });
                              },
                            ),
                            SwitchListTile(
                              title: const Text('Auto-login'),
                              value: _autoLogin,
                              onChanged: (val) {
                                setState(() {
                                  _autoLogin = val;
                                  if (_autoLogin) {
                                    _updateAutoFillFields();
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ],
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 100,
                          width: 100,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // App Name
                      const Text(
                        'SNS Rooster',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Employee Management System',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      // Login Form
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              if (!_isResetPassword) ...[
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  obscureText: _obscurePassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                              ] else ...[
                                TextFormField(
                                  controller: _resetTokenController,
                                  decoration: InputDecoration(
                                    labelText: 'Reset Token',
                                    prefixIcon: const Icon(Icons.key),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter the reset token';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _newPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'New Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a new password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        _isResetPassword
                                            ? 'Reset Password'
                                            : 'Login',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _isResetPassword = !_isResetPassword;
                                        });
                                      },
                                child: Text(
                                  _isResetPassword
                                      ? 'Back to Login'
                                      : 'Forgot Password?',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
