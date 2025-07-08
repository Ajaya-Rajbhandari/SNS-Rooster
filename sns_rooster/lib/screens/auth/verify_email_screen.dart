import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({Key? key}) : super(key: key);

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isLoading = true;
  String? _message;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    String? token;
    final uri = Uri.base;

    // Try to get token from query parameters (for non-web or direct deep links)
    token = uri.queryParameters['token'];

    // If not found, try to extract from hash (for web hash routing)
    if (token == null || token.isEmpty) {
      final hash = uri.fragment; // e.g. "/verify-email?token=..."
      final hashUri = Uri.parse(hash.startsWith('/') ? hash : '/$hash');
      token = hashUri.queryParameters['token'];
    }

    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _success = false;
        _message = 'Invalid or missing verification token.';
      });
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify-email?token=$token'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
          _success = true;
          _message = 'Your email has been verified! You can now log in.';
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
          _success = false;
          _message = data['message'] ?? 'Verification failed.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _success = false;
        _message = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _success ? Icons.check_circle : Icons.error,
                      color: _success ? Colors.green : Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _message ?? '',
                      style: TextStyle(
                        color: _success ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
