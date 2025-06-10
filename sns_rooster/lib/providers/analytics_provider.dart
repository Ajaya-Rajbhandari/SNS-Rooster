import 'package:flutter/material.dart';
import '../services/mock_service.dart'; // Assuming mock_service.dart contains analytics data
import '../providers/auth_provider.dart'; // To get current user ID

class AnalyticsProvider with ChangeNotifier {
  final MockAnalyticsService _mockService = MockAnalyticsService();
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
      if (userId == null) {
        _error = 'User not logged in.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      // Fetch attendance analytics data
      _attendanceData = await _mockService.getAttendanceAnalytics();
      // Fetch work hours analytics data
      _workHoursData = await _mockService.getWorkHoursAnalytics();
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
