import 'package:flutter_test/flutter_test.dart';
import 'package:sns_rooster/providers/auth_provider.dart';

void main() {
  group('AuthProvider Tests', () {
    test('Initial token should be null', () {
      final authProvider = AuthProvider();
      expect(authProvider.token, null);
    });

    // Add more tests for login, logout, and token management here
  });
}
