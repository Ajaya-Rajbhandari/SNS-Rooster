import 'package:flutter/material.dart';
import 'package:sns_rooster/utils/logger.dart';
import '../providers/auth_provider.dart';
import '../services/payroll_service.dart';

class PayrollProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  late final PayrollService _payrollService;
  List<Map<String, dynamic>> _payrollSlips = [];
  bool _isLoading = false;
  String? _error;

  PayrollProvider(this._authProvider) {
    _payrollService = PayrollService(_authProvider);
  }

  List<Map<String, dynamic>> get payrollSlips => _payrollSlips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPayrollSlips() async {
    log('PayrollProvider: fetchPayrollSlips called');
    _isLoading = true;
    _error = null;
    notifyListeners();

    final userId = _authProvider.user?['_id'];

    if (userId == null) {
      log('PayrollProvider: userId is null');
      _error = 'User not logged in.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      log('PayrollProvider: calling getPayrollSlips for userId: $userId');
      _payrollSlips = await _payrollService.getPayrollSlips(userId);
      log('PayrollProvider: payrollSlips fetched: ${_payrollSlips.length}');
      _payrollSlips.sort((a, b) => b['periodEnd'].compareTo(a['periodEnd']));
    } catch (e) {
      log('PayrollProvider: error fetching payroll slips: $e');

      // Check if it's a company context error or user not found error
      if (e.toString().contains('Company context required') ||
          e.toString().contains('User not found') ||
          e.toString().contains('User must be authenticated') ||
          e.toString().contains('400')) {
        _error =
            'Authentication issue detected. Please log out and log back in to refresh your session.';
      } else {
        _error = e.toString();
      }

      _payrollSlips = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearPayrollData() {
    log('PayrollProvider: clearPayrollData called');
    _payrollSlips = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> updatePayslipStatus(String payslipId, String status,
      {String? comment}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _payrollService.updatePayslipStatus(payslipId, status,
          comment: comment);
      await fetchPayrollSlips();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
