import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_provider.dart';

class PayrollAnalyticsProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  List<Map<String, dynamic>> _trend = [];
  Map<String, double> _deductionBreakdown = {};
  bool _isLoading = false;
  String? _error;

  PayrollAnalyticsProvider(this._authProvider);

  List<Map<String, dynamic>> get trend => _trend;
  Map<String, double> get deductionBreakdown => _deductionBreakdown;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTrend({int months = 6, String freq = 'monthly'}) async {
    if (!_authProvider.isAuthenticated) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/analytics/admin/payroll-trend')
              .replace(queryParameters: {
        'months': months.toString(),
        'freq': freq,
      });
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_authProvider.token}',
      });
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _trend = (data['trend'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        _error = 'Failed to fetch payroll trend';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDeductionBreakdown({String? month}) async {
    if (!_authProvider.isAuthenticated) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final params = <String, String>{};
      if (month != null) params['month'] = month;
      final uri = Uri.parse(
              '${ApiConfig.baseUrl}/analytics/admin/payroll-deductions-breakdown')
          .replace(queryParameters: params);
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_authProvider.token}',
      });
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _deductionBreakdown = Map<String, double>.from(
            (data['breakdown'] as Map<String, dynamic>)
                .map((k, v) => MapEntry(k, (v as num).toDouble())));
      } else {
        _error = 'Failed to fetch deduction breakdown';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _trend = [];
    _deductionBreakdown = {};
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
