import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart'; // Added import for ProfileProvider
import '../../services/secure_storage_service.dart';
import '../../services/company_service.dart';
import '../../services/app_update_service.dart';
import '../../models/company.dart';
import '../employee/employee_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../super_admin/super_admin_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  // Company selection
  List<Company> _availableCompanies = [];
  Company? _selectedCompany;
  bool _isLoadingCompanies = false;

  // App version and update info
  String _appVersion = '';
  String _buildNumber = '';
  bool _updateAvailable = false;
  String _latestVersion = '';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _loadAvailableCompanies();
    _loadAppVersion();
    _checkForUpdates();
  }

  void _loadSavedCredentials() async {
    try {
      // Load remembered credentials from secure storage
      final rememberedCreds =
          await SecureStorageService.getRememberedCredentials();
      final remember = rememberedCreds['remember_me'] == 'true';

      if (remember) {
        setState(() {
          _rememberMe = true;
          _emailController.text = rememberedCreds['email'] ?? '';
          _passwordController.text = rememberedCreds['password'] ?? '';
        });
      }
    } catch (e) {
      // Fallback to SharedPreferences for migration
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool('rememberMe') ?? false;
      if (remember) {
        setState(() {
          _rememberMe = true;
          _emailController.text = prefs.getString('savedEmail') ?? '';
          _passwordController.text = prefs.getString('savedPassword') ?? '';
        });

        // Migrate to secure storage
        await SecureStorageService.storeRememberedCredentials(
          email: _emailController.text,
          password: _passwordController.text,
          rememberMe: true,
        );

        // Clear from SharedPreferences
        await prefs.remove('rememberMe');
        await prefs.remove('savedEmail');
        await prefs.remove('savedPassword');
      }
    }
  }

  Future<void> _loadAvailableCompanies() async {
    setState(() {
      _isLoadingCompanies = true;
    });

    try {
      final companies = await CompanyService.getAvailableCompanies();
      setState(() {
        _availableCompanies = companies;
        if (_availableCompanies.isNotEmpty) {
          _selectedCompany = _availableCompanies.first;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load companies: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingCompanies = false;
      });
    }
  }

  /// Load app version information
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      print('Error loading app version: $e');
    }
  }

  /// Check for app updates
  Future<void> _checkForUpdates() async {
    try {
      final updateInfo =
          await AppUpdateService.checkForUpdates(showAlert: false);
      if (updateInfo != null && updateInfo.hasUpdate) {
        setState(() {
          _updateAvailable = true;
          _latestVersion = updateInfo.latestVersion;
        });
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a company'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Set remember me state in AuthProvider
      authProvider.setRememberMe(_rememberMe);

      // Store selected company ID before login
      await SecureStorageService.storeCompanyId(_selectedCompany!.id);

      final success = await authProvider.login(
        _emailController.text,
        _passwordController.text,
        companyId: _selectedCompany!.id,
      );

      if (!mounted) return;

      if (success) {
        // Store remembered credentials if remember me is enabled
        if (_rememberMe) {
          await SecureStorageService.storeRememberedCredentials(
            email: _emailController.text,
            password: _passwordController.text,
            rememberMe: true,
          );
        } else {
          // Clear remembered credentials if remember me is disabled
          await SecureStorageService.clearRememberedCredentials();
        }

        if (authProvider.user?['role'] == 'super_admin') {
          final profileProvider =
              Provider.of<ProfileProvider>(context, listen: false);
          await profileProvider.forceRefreshProfile();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => const SuperAdminDashboardScreen()),
          );
        } else if (authProvider.user?['role'] == 'admin') {
          final profileProvider =
              Provider.of<ProfileProvider>(context, listen: false);
          await profileProvider.forceRefreshProfile();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          final profileProvider =
              Provider.of<ProfileProvider>(context, listen: false);
          await profileProvider.forceRefreshProfile();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const EmployeeDashboardScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred during login'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Company Selection Dropdown
                    if (_isLoadingCompanies)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_availableCompanies.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<Company>(
                          value: _selectedCompany,
                          decoration: const InputDecoration(
                            labelText: 'Select Company',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.business),
                          ),
                          items: _availableCompanies.map((company) {
                            return DropdownMenuItem<Company>(
                              value: company,
                              child: Text(company.name),
                            );
                          }).toList(),
                          onChanged: (Company? company) {
                            setState(() {
                              _selectedCompany = company;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a company';
                            }
                            return null;
                          },
                        ),
                      ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailRegex =
                            RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(trimmed)) {
                          return 'Please enter a valid email address';
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
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value?.trim().isEmpty == true) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Improved Remember Me Checkbox
                        GestureDetector(
                          onTap: () async {
                            setState(() {
                              _rememberMe = !_rememberMe;
                            });

                            // If unchecking remember me, clear saved credentials
                            if (!_rememberMe) {
                              await SecureStorageService
                                  .clearRememberedCredentials();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _rememberMe
                                        ? Colors.white
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: _rememberMe
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.blue,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remember me',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: _rememberMe
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/forgot_password');
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Show indicator if credentials were loaded from remember me
                    if (_rememberMe && _emailController.text.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Credentials loaded from saved data',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                    // App Version and Update Info
                    const SizedBox(height: 32),
                    _buildVersionInfo(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build version information widget
  Widget _buildVersionInfo() {
    return Column(
      children: [
        // App Version
        if (_appVersion.isNotEmpty)
          Text(
            'Version $_appVersion (Build $_buildNumber)',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),

        // Android App Download Link
        Container(
          margin: const EdgeInsets.only(top: 16),
          child: InkWell(
            onTap: () async {
              const downloadUrl = 'https://sns-rooster.onrender.com/api/app/download/android/file';
              final uri = Uri.parse(downloadUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.android,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Download Android App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Update Available Notification
        if (_updateAvailable)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.system_update,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Update available: v$_latestVersion',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await AppUpdateService.checkForUpdates(showAlert: true);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
