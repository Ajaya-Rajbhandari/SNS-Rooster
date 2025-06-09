// lib/services/mock_auth_service.dart

import 'package:sns_rooster/models/employee.dart';

class MockAuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Mock user data
    Employee mockUser = Employee(
      id: 'user_id',
      name: 'Mock User',
      email: email,
      role: 'employee',
      department: 'IT',
      position: 'Developer',
      isActive: true,
      isProfileComplete: true,
    );

    // Mock JWT token
    String mockToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

    // Simulate successful login
    if (email == 'user@example.com' && password == 'password') {
      return {
        'token': mockToken,
        'user': mockUser.toJson(),
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
