// Placeholder for splash screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../login/login_screen.dart';
import '../employee/employee_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/verify_email_screen.dart';
import '../../utils/hash_fragment.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Poll for the hash fragment for up to 2 seconds
    String fragment = '';
    for (int i = 0; i < 20; i++) {
      fragment = getHashFragment();
      print('Polling for hash fragment: $fragment');
      if (fragment.isNotEmpty) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print('SplashScreen (universal): fragment: $fragment');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. Handle verification or reset-password first
    if (fragment.startsWith('/verify-email')) {
      final fakeUri = Uri.parse('http://dummy$fragment');
      final token = fakeUri.queryParameters['token'];
      print('SplashScreen: Navigating to VerifyEmailScreen with token: $token');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(token: token),
            ),
          );
        }
      });
      return;
    } else if (fragment.startsWith('/reset-password')) {
      final fakeUri = Uri.parse('http://dummy$fragment');
      final token = fakeUri.queryParameters['token'];
      print('SplashScreen: Navigating to ResetPassword with token: $token');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/reset-password',
              arguments: {'token': token});
        }
      });
      return;
    }

    // 2. If no special hash, proceed with auth check
    if (authProvider.isAuthenticated) {
      if (authProvider.user?['role'] == 'admin') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            );
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (_) => const EmployeeDashboardScreen()),
            );
          }
        });
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      });
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo with shadow
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 150,
                  height: 150,
                ),
              ),
              const SizedBox(height: 30),
              // App Name with gradient
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.white, Colors.white.withValues(alpha: 0.9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: const Text(
                  'SNS ROOSTER',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white,
                    fontFamily: 'ProductSans',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Tagline with stylish font
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'HR Management System',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 1,
                    fontFamily: 'ProductSans',
                  ),
                ),
              ),
              const SizedBox(height: 50),
              // Loading indicator with custom color
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.8),
                  ),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
