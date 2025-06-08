// Placeholder for splash screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Check authentication status after animation
    Future.delayed(const Duration(seconds: 3), () {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    if (!mounted) return;

    print('SPLASH: ===== STARTING AUTH CHECK =====');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    print(
        'SPLASH: Initial state - isAuthenticated: ${authProvider.isAuthenticated}');
    print(
        'SPLASH: Initial state - token exists: ${authProvider.token != null}');
    print('SPLASH: Initial state - user exists: ${authProvider.user != null}');

    await authProvider.initAuth();

    if (!mounted) {
      print('SPLASH: Widget no longer mounted, aborting navigation');
      return;
    }

    print(
        'SPLASH: After initAuth - isAuthenticated: ${authProvider.isAuthenticated}');
    print(
        'SPLASH: After initAuth - token exists: ${authProvider.token != null}');
    print('SPLASH: After initAuth - user exists: ${authProvider.user != null}');
    print('SPLASH: After initAuth - user role: ${authProvider.user?['role']}');

    if (authProvider.isAuthenticated) {
      print('SPLASH: User is authenticated, determining route...');
      // Check if profile is complete
      if (authProvider.user?['isProfileComplete'] == false) {
        print('SPLASH: Profile is incomplete, navigating to /profile');
        Navigator.pushReplacementNamed(context, '/profile');
      } else {
        final route = authProvider.user?['role'] == 'admin'
            ? '/admin_dashboard'
            : '/employee_dashboard';
        print('SPLASH: Profile complete, navigating to $route');
        Navigator.pushReplacementNamed(context, route);
      }
    } else {
      print('SPLASH: User is not authenticated, navigating to login');
      Navigator.pushReplacementNamed(context, '/login');
    }
    print('SPLASH: ===== AUTH CHECK COMPLETED =====');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 150,
                  height: 150,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'SNS Rooster',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
