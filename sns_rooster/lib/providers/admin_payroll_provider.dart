import 'package:flutter/material.dart';
import '../services/admin_payroll_service.dart';
import '../providers/auth_provider.dart';

class AdminPayrollProvider with ChangeNotifier {
  final AdminPayrollService _service;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _payslips = [];
  bool _isLoading = false;
  String? _error;

  AdminPayrollProvider(AuthProvider authProvider)
      : _service = AdminPayrollService(authProvider);

  List<Map<String, dynamic>> get employees => _employees;
  List<Map<String, dynamic>> get payslips => _payslips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEmployees() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _employees = await _service.fetchEmployees();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPayslips(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _payslips = await _service.fetchPayslips(employeeId);
    } catch (e) {
      _error = e.toString();
      _payslips = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPayslip(
      Map<String, dynamic> payslip, String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      payslip['employee'] = employeeId;
      final newPayslip = await _service.addPayslip(payslip);
      _payslips.insert(0, newPayslip);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> editPayslip(
      String payslipId, Map<String, dynamic> payslip) async {
    print('DEBUG: AdminPayrollProvider.editPayslip called');
    print('DEBUG: payslipId: $payslipId');
    print('DEBUG: payslip data (before patch): $payslip');

    // Ensure employee field is present
    if (payslip['employee'] == null || payslip['employee'].toString().isEmpty) {
      // Try to get from the existing payslip in the list
      final idx = _payslips.indexWhere((p) => p['_id'] == payslipId);
      if (idx != -1 && _payslips[idx]['employee'] != null) {
        payslip['employee'] = _payslips[idx]['employee'];
        print(
            'DEBUG: Patched employee field from local payslip: \\${payslip['employee']}');
      }
    }

    print('DEBUG: payslip data (after patch): $payslip');

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      print('DEBUG: Calling _service.editPayslip...');
      final updated = await _service.editPayslip(payslipId, payslip);
      print('DEBUG: Service returned updated payslip: $updated');

      final idx = _payslips.indexWhere((p) => p['_id'] == payslipId);
      print('DEBUG: Found payslip at index: $idx');
      if (idx != -1) {
        _payslips[idx] = updated;
        print('DEBUG: Updated payslip in local list');
      }
    } catch (e) {
      print('DEBUG: Error in editPayslip: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePayslip(String payslipId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deletePayslip(payslipId);
      _payslips.removeWhere((p) => p['_id'] == payslipId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _employees = [];
    _payslips = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
