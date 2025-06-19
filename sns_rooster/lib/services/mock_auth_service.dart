// lib/services/mock_auth_service.dart

class MockAuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Simulate successful login
    if (email == 'user@example.com' && password == 'password') {
      return {
        'token': 'mockToken',
        'user': {'id': 'user_id', 'name': 'Mock User', 'email': email},
      };
    } else {
      // Simulate invalid credentials
      throw Exception('Invalid email or password');
    }
  }

  Future<void> logout() async {
    // Simulate successful logout
    return;
  }
}
