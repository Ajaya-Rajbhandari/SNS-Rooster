// lib/services/mock_employee_service.dart

import 'package:sns_rooster/models/employee.dart';

class MockEmployeeService {
  Future<List<Employee>> getAllUsers() async {
    // Mock user data
    List<Employee> mockUsers = [
      Employee(
        id: 'user_id_1',
        name: 'John Doe',
        email: 'john.doe@example.com',
        role: 'employee',
        department: 'IT',
        position: 'Developer',
        isActive: true,
        isProfileComplete: true,
      ),
      Employee(
        id: 'user_id_2',
        name: 'Jane Smith',
        email: 'jane.smith@example.com',
        role: 'admin',
        department: 'HR',
        position: 'Manager',
        isActive: true,
        isProfileComplete: true,
      ),
    ];

    // Simulate successful retrieval of users
    return mockUsers;
  }

  Future<Employee> getUser(String userId) async {
    // Mock user data
    Employee mockUser = Employee(
      id: userId,
      name: 'Mock User',
      email: 'user@example.com',
      role: 'employee',
      department: 'IT',
      position: 'Developer',
      isActive: true,
      isProfileComplete: true,
    );

    // Simulate successful retrieval of user
    return mockUser;
  }

  Future<Employee> updateUser(String userId, Map<String, dynamic> updates) async {
    // Mock user data
    Employee mockUser = Employee(
      id: userId,
      name: updates['name'] ?? 'Mock User',
      email: 'user@example.com',
      role: 'employee',
      department: updates['department'] ?? 'IT',
      position: updates['position'] ?? 'Developer',
      isActive: updates['isActive'] ?? true,
      isProfileComplete: true,
    );

    // Simulate successful update of user
    return mockUser;
  }

  Future<void> deleteUser(String userId) async {
    // Simulate successful deletion of user
    return;
  }

  Future<Employee> createUser(Map<String, dynamic> userData) async {
      // Mock user data
      Employee mockUser = Employee(
        id: 'new_user_id',
        name: userData['name'] ?? 'New User',
        email: userData['email'] ?? 'newuser@example.com',
        role: userData['role'] ?? 'employee',
        department: userData['department'] ?? 'IT',
        position: userData['position'] ?? 'Developer',
        isActive: true,
        isProfileComplete: false,
      );

      return mockUser;
  }
}
