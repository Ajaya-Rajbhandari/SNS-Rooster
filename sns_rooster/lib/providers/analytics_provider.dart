import 'package:flutter/material.dart';
import '../providers/auth_provider.dart'; // To get current user ID
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AnalyticsProvider with ChangeNotifier {
  Map<String, int> _attendanceData = {};
  List<double> _workHoursData = [];
  bool _isLoading = false;
  String? _error;
  final AuthProvider _authProvider;

  AnalyticsProvider(this._authProvider);

  Map<String, int> get attendanceData => _attendanceData;
  List<double> get workHoursData => _workHoursData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAnalyticsData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _authProvider.user?['_id'];
      final token = _authProvider.token;
      if (userId == null || token == null) {
        _error = 'User not logged in.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      // Remove all mock code and use only real API logic
      // Fetch attendance analytics from backend
      final attendanceRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/analytics/attendance/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (attendanceRes.statusCode == 200) {
        final data = json.decode(attendanceRes.body);
        _attendanceData = Map<String, int>.from(data['attendance'] ?? {});
      } else {
        final data = json.decode(attendanceRes.body);
        throw Exception(data['message'] ?? 'Failed to fetch attendance analytics');
      }
      // Fetch work hours analytics from backend
      final workHoursRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/analytics/work-hours/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (workHoursRes.statusCode == 200) {
        final data = json.decode(workHoursRes.body);
        _workHoursData = List<double>.from(data['workHours'] ?? []);
      } else {
        final data = json.decode(workHoursRes.body);
        throw Exception(data['message'] ?? 'Failed to fetch work hours analytics');
      }
    } catch (e) {
      _error = e.toString();
      _attendanceData = {};
      _workHoursData = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearAnalyticsData() {
    _attendanceData = {};
    _workHoursData = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
