/// Provider for employee dashboard state (for future use with Provider/Riverpod)
library;

import 'package:flutter/material.dart';
import '../services/employee_service.dart';
import '../models/employee.dart';

class EmployeeProvider with ChangeNotifier {
  final EmployeeService _employeeService;

  EmployeeProvider(this._employeeService);

  List<Employee> _employees = [];
  Employee? _profile;
  bool _isLoading = false;
  String? _error;

  List<Employee> get employees => _employees;
  Employee? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- Get Employees (Admin) ---
  Future<void> getEmployees() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final rawList = await _employeeService.getEmployees();
      _employees = rawList.map((e) => Employee.fromJson(e)).toList();
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
      _employees.removeWhere(
          (emp) => emp.userId == employeeId || emp.id == employeeId);
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
      final raw = await _employeeService.getEmployeeById(employeeId);
      _profile = Employee.fromJson(raw);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Update Profile (Employee) ---
  Future<bool> updateProfile(
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
}
