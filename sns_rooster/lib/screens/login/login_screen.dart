import 'package:flutter/material.dart';
import 'package:sns_rooster/utils/logger.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../employee/employee_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../services/global_notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with RouteAware {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final bool _autoFill = false;
  final bool _autoLogin = false;
  final String _selectedRole = 'admin';
  bool _rememberMe = false;

  int _failedLoginCount = 0; // Track failed login attempts

  // Test credentials for developer convenience
  static const String _devEmployeeEmail = 'testuser@example.com';
  static const String _devEmployeePassword = 'Test@123';
  static const String _devAdminEmail = 'admin@snsrooster.com';
  static const String _devAdminPassword = 'Admin@123';

  RouteObserver<ModalRoute<void>>? _routeObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver =
        Provider.of<RouteObserver<ModalRoute<void>>>(context, listen: false);
    _routeObserver?.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back to this screen
    _handleScreenVisible();
  }

  @override
  void didPush() {
    // Called when this screen is pushed
    _handleScreenVisible();
  }

  void _handleScreenVisible() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.savedEmail != null &&
        authProvider.savedPassword != null &&
        authProvider.rememberMe) {
      _emailController.text = authProvider.savedEmail!;
      _passwordController.text = authProvider.savedPassword!;
      _rememberMe = true;
    } else {
      _emailController.clear();
      _passwordController.clear();
      _rememberMe = false;
      // Debug auto-fill removed for production
      // _updateAutoFillFields();
    }
    setState(() {}); // Refresh UI
  }

  @override
  void initState() {
    super.initState();
    // Initial fill handled in didPush
    // Debug auto-fill removed for production
    // _updateAutoFillFields();
  }

  void _updateAutoFillFields() {
    // Debug auto-fill removed for production
    // if (_autoFill) {
    //   _emailController.text =
    //       _selectedRole == 'admin' ? _devAdminEmail : _devEmployeeEmail;
    //   _passwordController.text =
    //       _selectedRole == 'admin' ? _devAdminPassword : _devEmployeePassword;
    //   if (_autoLogin) {
    //     Future.delayed(const Duration(milliseconds: 300), () {
    //       if (mounted) _login();
    //     });
    //   }
    // }
  }

  Future<void> _login() async {
    log('LOGIN SCREEN: Initiating login process');
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        _failedLoginCount = 0; // Reset on success
        log('LOGIN SCREEN: Login successful');
        // Ensure ProfileProvider is refreshed for the new user
        final profileProvider =
            Provider.of<ProfileProvider>(context, listen: false);
        await profileProvider.refreshProfile();
        // Add a short delay to ensure providers are updated before navigation
        await Future.delayed(const Duration(milliseconds: 1200));
        if (authProvider.user?['role'] == 'admin') {
          log('LOGIN SCREEN: Navigating to AdminDashboardScreen');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          log('LOGIN SCREEN: Navigating to EmployeeDashboardScreen');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const EmployeeDashboardScreen()),
          );
        }
      } else {
        _failedLoginCount++;
        log('LOGIN SCREEN: Login failed');
        final notificationService =
            Provider.of<GlobalNotificationService>(context, listen: false);
        notificationService.showError(authProvider.error ?? 'Login failed');
        if (_failedLoginCount == 2) {
          notificationService.showInfo(
              'Tip: After 4 failed attempts, your account will be temporarily locked.');
        }
      }
    } catch (e) {
      log('LOGIN SCREEN: Error during login: $e');
      if (!mounted) return;
      final notificationService =
          Provider.of<GlobalNotificationService>(context, listen: false);
      notificationService.showError('An error occurred during login');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    log('LOGIN SCREEN: BuildContext is ${context.hashCode}');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    log('LOGIN SCREEN: AuthProvider user data: ${authProvider.user}');

    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                // Desktop: Centered, constrained width
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _buildLoginForm(theme),
                  ),
                );
              } else {
                // Mobile/tablet: Full width with padding
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildLoginForm(theme),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome Back',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot_password');
                  },
                  child: Text(
                    'Forgot Password?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: Text(
                  'Remember Me',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                  ),
                ),
                value: _rememberMe,
                onChanged: (val) {
                  setState(() {
                    _rememberMe = val;
                  });
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  authProvider.setRememberMe(val);
                  if (val) {
                    // Save current credentials immediately
                    authProvider.saveCredentials(
                        _emailController.text, _passwordController.text);
                  } else {
                    // Clear saved credentials immediately
                    authProvider.clearSavedCredentials();
                  }
                },
                activeColor: theme.colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              if (_failedLoginCount >= 2 && _failedLoginCount < 4)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    'Tip: After 4 failed attempts, your account will be temporarily locked.',
                    style: TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
