/// Provider for employee dashboard state (for future use with Provider/Riverpod)
library;

import 'package:flutter/material.dart';
import '../models/employee.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/mock_employee_service.dart'; // Corrected import for the mock service

import 'package:sns_rooster/providers/auth_provider.dart';

class EmployeeProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  List<Map<String, dynamic>> _employees = [];
  Map<String, dynamic>? _profile;
  String? _error;
  bool _isLoading = false;

  // Instantiate the mock service (with useMock = true) so that we can simulate API responses.
  final MockEmployeeService _mockEmployeeService = MockEmployeeService();
  final bool useMock = true; // Explicitly set useMock to true

  EmployeeProvider(this._authProvider); // Constructor accepts AuthProvider

  List<Map<String, dynamic>> get employees => _employees;
  Map<String, dynamic>? get profile => _profile;
  String? get error => _error;
  bool get isLoading => _isLoading;

  // --- Get Employees (Admin) ---
  Future<void> getEmployees() async {
    print("EmployeeProvider: getEmployees called. useMock is: $useMock"); // Debug log
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        print("EmployeeProvider: Using mock service for getEmployees."); // Debug log
        final List<Employee> employeeObjects = await _mockEmployeeService.getAllUsers();
        _employees = employeeObjects.map((emp) => emp.toJson()).toList();
      } else {
        print("EmployeeProvider: Attempting real API call for getEmployees."); // Debug log
        // TODO: Replace with real API call (e.g., GET /api/users) (with Authorization header).
        // For example:
        // final response = await http.get(Uri.parse("http://yourbackend.com/api/users"), headers: { "Authorization": "Bearer YOUR_TOKEN" });
        // if (response.statusCode == 200) { final data = json.decode(response.body); _employees = List<Map<String, dynamic>>.from(data["users"]); } else { _error = "Failed to load employees"; }
        throw UnimplementedError("Real API call not implemented.");
      }
    } catch (e, s) {
      print("EmployeeProvider: Caught error in getEmployees: $e, type: ${e.runtimeType}"); // Debug log
      print("EmployeeProvider: StackTrace: $s"); // Debug log for stack trace
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Update Employee (Admin) ---
  Future<bool> updateEmployee(
      String employeeId, Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        final response =
            await _mockEmployeeService.updateUser(employeeId, updates);
        // In a real app, you might refresh the list (or update the local state) after an update.
        // For now, we just print (or log) the response.
        print("Update employee (mock) response: $response");
        // After updating, refresh the employee list
        await getEmployees(); 
        return true;
      } else {
        // TODO: Replace with real API call (e.g., PATCH /api/users/:employeeId) (with Authorization header).
        // For example:
        // final response = await http.patch(Uri.parse("http://yourbackend.com/api/users/$employeeId"), headers: { "Authorization": "Bearer YOUR_TOKEN" }, body: json.encode(updates));
        // if (response.statusCode == 200) { /* refresh or update local state */ return true; } else { _error = "Failed to update employee"; return false; }
        throw UnimplementedError("Real API call not implemented.");
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Add Employee (Admin) ---
  Future<bool> addEmployee(Map<String, dynamic> employeeData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        // Assuming MockEmployeeService has an `addUser` method
        // You might need to adjust the method name and parameters based on MockEmployeeService
        final Employee newEmployee = await _mockEmployeeService.createUser(employeeData);
        print("Add employee (mock) response: ${newEmployee.toJson()}");
        // After adding, refresh the employee list
        await getEmployees(); 
        return true;
      } else {
        // TODO: Replace with real API call (e.g., POST /api/users)
        throw UnimplementedError("Real API call not implemented for addEmployee.");
      }
    } catch (e, s) {
      print("EmployeeProvider: Caught error in addEmployee: $e, stackTrace: $s");
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Delete Employee (Admin) ---
  Future<bool> deleteEmployee(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        await _mockEmployeeService.deleteUser(employeeId);
        // In a real app, you might refresh the list (or remove the employee from local state) after deletion.
        // For now, we just print (or log) the response.
        print("Delete employee (mock) attempt for ID: $employeeId");
        // After deleting, refresh the employee list
        await getEmployees(); 
        return true;
      } else {
        // TODO: Replace with real API call (e.g., DELETE /api/users/:employeeId) (with Authorization header).
        // For example:
        // final response = await http.delete(Uri.parse("http://yourbackend.com/api/users/$employeeId"), headers: { "Authorization": "Bearer YOUR_TOKEN" });
        // if (response.statusCode == 200) { /* refresh or remove from local state */ return true; } else { _error = "Failed to delete employee"; return false; }
        throw UnimplementedError("Real API call not implemented.");
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Get Profile (Employee) --- (Commented out as MockEmployeeService does not implement this)
  /*
  Future<void> getProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        // final response = await _mockEmployeeService.getProfile(); // Method doesn't exist
        // _profile = response["user"];
        throw UnimplementedError("Mock getProfile not implemented in MockEmployeeService");
      } else {
        // TODO: Replace with real API call (e.g., GET /api/me) (with Authorization header).
        throw UnimplementedError("Real API call not implemented.");
      }
    } catch (e, s) {
      print("EmployeeProvider: Caught error in getProfile: $e, stackTrace: $s");
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  */

  // --- Update Profile (Employee) --- (Commented out as MockEmployeeService does not implement this)
  /*
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        // final response = await _mockEmployeeService.updateProfile(updates); // Method doesn't exist
        // print("Update profile (mock) response: $response");
        // _profile = response["user"];
        throw UnimplementedError("Mock updateProfile not implemented in MockEmployeeService");
        // return true;
      } else {
        // TODO: Replace with real API call (e.g., PATCH /api/me) (with Authorization header).
        throw UnimplementedError("Real API call not implemented.");
      }
    } catch (e, s) {
      print("EmployeeProvider: Caught error in updateProfile: $e, stackTrace: $s");
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  */
}
