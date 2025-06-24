/// Provider for employee dashboard state (for future use with Provider/Riverpod)
library;

import 'package:flutter/material.dart';
import '../services/employee_service.dart';

class EmployeeProvider with ChangeNotifier {
  final EmployeeService _employeeService;

  EmployeeProvider(this._employeeService);

  List<Map<String, dynamic>> _employees = [];
  Map<String, dynamic>? _profile;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get employees => _employees;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- Get Employees (Admin) ---
  Future<void> getEmployees() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _employees = await _employeeService.getEmployees();
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
      await _employeeService.updateEmployee(employeeId, updates);
      return true;
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
      await _employeeService.deleteEmployee(employeeId);
      // Remove from local list and notify listeners
      _employees.removeWhere((emp) => emp['userId'] == employeeId || emp['_id'] == employeeId || emp['id'] == employeeId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Get Profile (Employee) ---
  Future<void> getProfile(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _employeeService.getEmployeeById(employeeId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Update Profile (Employee) ---
  Future<bool> updateProfile(String employeeId, Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _employeeService.updateEmployee(employeeId, updates);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
