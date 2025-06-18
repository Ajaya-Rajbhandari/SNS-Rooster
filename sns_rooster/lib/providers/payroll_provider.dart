import 'package:flutter/material.dart';
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    final userId = _authProvider.user?['_id'];

    if (userId == null) {
      _error = 'User not logged in.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _payrollSlips = await _payrollService.getPayrollSlips(userId);
      _payrollSlips.sort((a, b) => b['periodEnd'].compareTo(a['periodEnd']));
    } catch (e) {
      _error = e.toString();
      _payrollSlips = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearPayrollData() {
    _payrollSlips = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
