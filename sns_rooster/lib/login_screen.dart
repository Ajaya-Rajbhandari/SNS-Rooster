import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80), // Adjust as needed for top spacing
              Center(
                child: Image.asset(
                  'assets/images/logo.png', // Placeholder for your logo
                  height: 100,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Welcome Back 👋',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'to SNS HR Attendee',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hello there, login to continue',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Demo Login: employee@sns.com (Employee) / admin@sns.com (Admin)',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: Colors.blueGrey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'john.doe@example.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: '********',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.visibility_off),
                    onPressed: () {
                      if (_emailController.text == 'employee@sns.com') {
                        Navigator.pushReplacementNamed(context, '/dashboard');
                      } else if (_emailController.text == 'admin@sns.com') {
                        Navigator.pushReplacementNamed(
                          context,
                          '/admin_dashboard',
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid credentials.')),
                        );
                      }
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    if (_emailController.text == 'employee@sns.com') {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    } else if (_emailController.text == 'admin@sns.com') {
                      Navigator.pushReplacementNamed(
                        context,
                        '/admin_dashboard',
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid credentials.')),
                      );
                    }
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_emailController.text == 'employee@sns.com') {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    } else if (_emailController.text == 'admin@sns.com') {
                      Navigator.pushReplacementNamed(
                        context,
                        '/admin_dashboard',
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid credentials.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5, // Add shadow
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor, // Use primary color
                    foregroundColor: Colors.white, // Text color
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Or continue with social account',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (_emailController.text == 'employee@sns.com') {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    } else if (_emailController.text == 'admin@sns.com') {
                      Navigator.pushReplacementNamed(
                        context,
                        '/admin_dashboard',
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid credentials.')),
                      );
                    }
                  },
                  icon: Image.asset(
                    'assets/images/google_logo.png', // Placeholder for Google logo
                    height: 24,
                  ),
                  label: const Text('Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ), // Border color
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
