// lib/services/mock_employee_service.dart

import 'package:sns_rooster/models/employee.dart';

class MockEmployeeService {
  Future<List<Employee>> getAllUsers() async {
    // Mock user data
    List<Employee> mockUsers = [
      Employee(
        id: 'user_id_1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        employeeId: 'EMP001',
        hireDate: DateTime(2020, 1, 15),
        department: 'IT',
        position: 'Developer',
      ),
      Employee(
        id: 'user_id_2',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane.smith@example.com',
        employeeId: 'EMP002',
        hireDate: DateTime(2019, 3, 22),
        department: 'HR',
        position: 'Manager',
      ),
    ];

    // Simulate successful retrieval of users
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    return mockUsers;
  }

  Future<Employee> getUser(String userId) async {
    // Mock user data
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    return Employee(
      id: userId,
      firstName: 'Mock',
      lastName: 'User',
      email: 'user@example.com',
      employeeId: 'EMP999',
      hireDate: DateTime.now(),
      department: 'IT',
      position: 'Developer',
    );
  }

  Future<Employee> updateUser(String userId, Map<String, dynamic> updates) async {
    // Mock user data
    await Future.delayed(const Duration(milliseconds: 400)); // Simulate network delay
    return Employee(
      id: userId,
      firstName: updates['firstName'] ?? 'Mock',
      lastName: updates['lastName'] ?? 'User',
      email: updates['email'] ?? 'user@example.com',
      employeeId: updates['employeeId'] ?? 'EMP999',
      hireDate: updates['hireDate'] is String ? DateTime.parse(updates['hireDate']) : (updates['hireDate'] ?? DateTime.now()),
      department: updates['department'] ?? 'IT',
      position: updates['position'] ?? 'Developer',
    );
  }

  Future<void> deleteUser(String userId) async {
    // Simulate successful deletion of user
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate network delay
    print('MockEmployeeService: Deleted user $userId');
    return;
  }

  Future<Employee> createUser(Map<String, dynamic> userData) async {
      // Mock user data
      await Future.delayed(const Duration(milliseconds: 600)); // Simulate network delay
      return Employee(
        id: 'new_user_${DateTime.now().millisecondsSinceEpoch}', // Generate a unique-ish ID
        firstName: userData['firstName'] ?? 'New',
        lastName: userData['lastName'] ?? 'User',
        email: userData['email'] ?? 'newuser@example.com',
        employeeId: userData['employeeId'] ?? 'EMPNEW',
        hireDate: userData['hireDate'] is String ? DateTime.parse(userData['hireDate']) : (userData['hireDate'] ?? DateTime.now()),
        department: userData['department'] ?? 'IT',
        position: userData['position'] ?? 'Developer',
      );
  }

  // Methods that were called by EmployeeProvider but not implemented:
  // These are not strictly needed for the current employee management screen but were referenced.
  // You can implement them if profile features are added.
  Future<Map<String, dynamic>> getProfile() async {
    print("MockEmployeeService: getProfile called - returning unimplemented stub");
    await Future.delayed(const Duration(milliseconds: 100));
    // This structure is a guess based on how _profile was used in EmployeeProvider
    return {
      "user": {
        "id": "mock_profile_id",
        "firstName": "Mock",
        "lastName": "ProfileUser",
        "email": "profile@example.com",
        "employeeId": "PROF001",
        "hireDate": DateTime.now().toIso8601String(),
        "department": "General",
        "position": "User"
      }
    };
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updates) async {
    print("MockEmployeeService: updateProfile called with $updates - returning unimplemented stub");
    await Future.delayed(const Duration(milliseconds: 100));
    return {
      "user": {
        "id": "mock_profile_id",
        "firstName": updates['firstName'] ?? "Mock",
        "lastName": updates['lastName'] ?? "ProfileUserUpdated",
        "email": updates['email'] ?? "profile@example.com",
        "employeeId": "PROF001",
        "hireDate": DateTime.now().toIso8601String(),
        "department": updates['department'] ?? "General",
        "position": updates['position'] ?? "User"
      }
    };
  }
}
