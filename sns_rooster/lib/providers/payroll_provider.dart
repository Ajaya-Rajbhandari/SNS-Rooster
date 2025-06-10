import 'package:flutter/material.dart';
import '../services/mock_service.dart'; // Import the mock_service.dart where MockPayrollService is defined
import '../providers/auth_provider.dart'; // To get current user ID
import 'package:collection/collection.dart'; // For groupBy

class PayrollProvider with ChangeNotifier {
  final MockPayrollService _mockService =
      MockPayrollService(); // Changed to MockPayrollService
  List<Map<String, dynamic>> _payrollSlips = [];
  bool _isLoading = false;
  String? _error;
  final AuthProvider _authProvider;

  PayrollProvider(this._authProvider);

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
      final allSlips = await _mockService.getPayrollSlips();
      _payrollSlips =
          allSlips.where((slip) => slip['userId'] == userId).toList();
      _payrollSlips.sort((a, b) =>
          b['issueDate'].compareTo(a['issueDate'])); // Sort by most recent
    } catch (e) {
      _error = e.toString();
      _payrollSlips = []; // Clear data on error
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
