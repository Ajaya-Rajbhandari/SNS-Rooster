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
    print('PayrollProvider: fetchPayrollSlips called');
    _isLoading = true;
    _error = null;
    notifyListeners();

    final userId = _authProvider.user?['_id'];

    if (userId == null) {
      print('PayrollProvider: userId is null');
      _error = 'User not logged in.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      print('PayrollProvider: calling getPayrollSlips for userId: $userId');
      _payrollSlips = await _payrollService.getPayrollSlips(userId);
      print('PayrollProvider: payrollSlips fetched: ${_payrollSlips.length}');
      _payrollSlips.sort((a, b) => b['periodEnd'].compareTo(a['periodEnd']));
    } catch (e) {
      print('PayrollProvider: error fetching payroll slips: $e');
      _error = e.toString();
      _payrollSlips = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearPayrollData() {
    print('PayrollProvider: clearPayrollData called');
    _payrollSlips = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
