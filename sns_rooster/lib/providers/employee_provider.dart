/// Provider for employee dashboard state (for future use with Provider/Riverpod)
library;

import 'package:flutter/material.dart';
import '../services/mock_service.dart'; // Import the mock service

class EmployeeProvider with ChangeNotifier {
  List<Map<String, dynamic>> _employees = [];
  Map<String, dynamic>? _profile;
  String? _error;
  bool _isLoading = false;

  // Instantiate the mock service (with useMock = true) so that we can simulate API responses.
  final MockEmployeeService _mockEmployeeService = MockEmployeeService();

  List<Map<String, dynamic>> get employees => _employees;
  Map<String, dynamic>? get profile => _profile;
  String? get error => _error;
  bool get isLoading => _isLoading;

  // --- Get Employees (Admin) ---
  Future<void> getEmployees() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        _employees = await _mockEmployeeService.getUsers();
      } else {
        // TODO: Replace with real API call (e.g., GET /api/users) (with Authorization header).
        // For example:
        // final response = await http.get(Uri.parse("http://yourbackend.com/api/users"), headers: { "Authorization": "Bearer YOUR_TOKEN" });
        // if (response.statusCode == 200) { final data = json.decode(response.body); _employees = List<Map<String, dynamic>>.from(data["users"]); } else { _error = "Failed to load employees"; }
        throw UnimplementedError("Real API call not implemented.");
      }
    } catch (e) {
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

  // --- Delete Employee (Admin) ---
  Future<bool> deleteEmployee(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        final response = await _mockEmployeeService.deleteUser(employeeId);
        // In a real app, you might refresh the list (or remove the employee from local state) after deletion.
        // For now, we just print (or log) the response.
        print("Delete employee (mock) response: $response");
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

  // --- Get Profile (Employee) ---
  Future<void> getProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        final response = await _mockEmployeeService.getProfile();
        _profile = response["user"];
      } else {
        // TODO: Replace with real API call (e.g., GET /api/me) (with Authorization header).
        // For example:
        // final response = await http.get(Uri.parse("http://yourbackend.com/api/me"), headers: { "Authorization": "Bearer YOUR_TOKEN" });
        // if (response.statusCode == 200) { final data = json.decode(response.body); _profile = data["user"]; } else { _error = "Failed to load profile"; }
        throw UnimplementedError("Real API call not implemented.");
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Update Profile (Employee) ---
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        final response = await _mockEmployeeService.updateProfile(updates);
        // In a real app, you might update the local profile (or refresh) after an update.
        // For now, we just print (or log) the response.
        print("Update profile (mock) response: $response");
        _profile = response["user"];
        return true;
      } else {
        // TODO: Replace with real API call (e.g., PATCH /api/me) (with Authorization header).
        // For example:
        // final response = await http.patch(Uri.parse("http://yourbackend.com/api/me"), headers: { "Authorization": "Bearer YOUR_TOKEN" }, body: json.encode(updates));
        // if (response.statusCode == 200) { final data = json.decode(response.body); _profile = data["user"]; return true; } else { _error = "Failed to update profile"; return false; }
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
}
