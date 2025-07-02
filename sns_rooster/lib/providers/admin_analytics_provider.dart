import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_provider.dart';

class AdminAnalyticsProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _overview;
  List<dynamic> _workHoursTrend = [];
  Map<String, dynamic>? _leaveBreakdown;
  List<dynamic> _monthlyHoursTrend = [];
  bool _isLoading = false;
  String? _error;

  AdminAnalyticsProvider(this._authProvider);

  Map<String, dynamic>? get summary => _summary;
  Map<String, dynamic>? get overview => _overview;
  List<dynamic> get workHoursTrend => _workHoursTrend;
  Map<String, dynamic>? get leaveBreakdown => _leaveBreakdown;
  List<dynamic> get monthlyHoursTrend => _monthlyHoursTrend;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSummary({String? start, String? end}) async {
    if (!_authProvider.isAuthenticated) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/analytics/summary').replace(
        queryParameters: {
          if (start != null) 'start': start,
          if (end != null) 'end': end,
        },
      );
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_authProvider.token}',
      });
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _summary = data['summary'];
      } else {
        _error = 'Failed to load analytics';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOverview({String? start, String? end, int? range}) async {
    if (!_authProvider.isAuthenticated) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (start != null && end != null) {
        params['start'] = start;
        params['end'] = end;
      } else if (range != null) {
        params['range'] = range.toString();
      }
      final uri = Uri.parse('${ApiConfig.baseUrl}/analytics/admin/overview')
          .replace(queryParameters: params);

      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_authProvider.token}',
      });

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _overview = data;
        _workHoursTrend = data['workHoursTrend'] ?? [];
      } else {
        _error = 'Failed to load overview';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLeaveBreakdown({String? start, String? end}) async {
    if (!_authProvider.isAuthenticated) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
              '${ApiConfig.baseUrl}/analytics/admin/leave-types-breakdown')
          .replace(queryParameters: {
        if (start != null && end != null) 'startDate': start,
        'endDate': end,
      });

      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_authProvider.token}',
      });

      if (res.statusCode == 200) {
        _leaveBreakdown = json.decode(res.body);
      } else {
        _error = 'Failed to load leave breakdown';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMonthlyHoursTrend({String? start, String? end}) async {
    if (!_authProvider.isAuthenticated) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/analytics/admin/monthly-hours-trend')
              .replace(queryParameters: {
        if (start != null && end != null) 'start': start,
        'end': end,
      });

      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_authProvider.token}',
      });

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _monthlyHoursTrend = data['trend'] ?? [];
      } else {
        _error = 'Failed to load monthly hours trend';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
