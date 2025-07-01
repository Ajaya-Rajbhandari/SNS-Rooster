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
  int _longestStreak = 0;
  String _mostProductiveDay = 'N/A';
  String _avgCheckIn = 'N/A';

  AnalyticsProvider(this._authProvider);

  Map<String, int> get attendanceData => _attendanceData;
  List<double> get workHoursData => _workHoursData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get longestStreak => _longestStreak;
  String get mostProductiveDay => _mostProductiveDay;
  String get avgCheckIn => _avgCheckIn;

  Future<void> fetchAnalyticsData({int range = 7}) async {
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
      // Debug: Print outgoing request details
      print(
          'DEBUG: Analytics attendance URL: ${ApiConfig.baseUrl}/analytics/attendance/$userId?range=$range');
      print(
          'DEBUG: Analytics work hours URL: ${ApiConfig.baseUrl}/analytics/work-hours/$userId?range=$range');
      print('DEBUG: Authorization token: Bearer $token');
      // Fetch attendance analytics from backend
      final attendanceRes = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/analytics/attendance/$userId?range=$range'),
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
        throw Exception(
            data['message'] ?? 'Failed to fetch attendance analytics');
      }
      // Fetch work hours analytics from backend
      final workHoursRes = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/analytics/work-hours/$userId?range=$range'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (workHoursRes.statusCode == 200) {
        final data = json.decode(workHoursRes.body);
        _workHoursData = (data['workHours'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
      } else {
        final data = json.decode(workHoursRes.body);
        throw Exception(
            data['message'] ?? 'Failed to fetch work hours analytics');
      }
      // Fetch analytics summary from backend
      final summaryRes = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/analytics/summary/$userId?range=$range'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (summaryRes.statusCode == 200) {
        final data = json.decode(summaryRes.body);
        _longestStreak = data['longestStreak'] ?? 0;
        _mostProductiveDay = data['mostProductiveDay'] ?? 'N/A';
        _avgCheckIn = data['avgCheckIn'] ?? 'N/A';
      } else {
        _longestStreak = 0;
        _mostProductiveDay = 'N/A';
        _avgCheckIn = 'N/A';
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

class EmployeeAnalyticsService {
  static Future<Map<String, dynamic>> fetchLateCheckins(
      String userId, String token) async {
    final url = '${ApiConfig.baseUrl}/analytics/late-checkins/$userId';
    final response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load late check-ins');
    }
  }

  static Future<Map<String, dynamic>> fetchAvgCheckout(
      String userId, String token) async {
    final url = '${ApiConfig.baseUrl}/analytics/avg-checkout/$userId';
    final response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load average check-out time');
    }
  }

  static Future<List<dynamic>> fetchRecentActivity(
      String userId, String token) async {
    final url = '${ApiConfig.baseUrl}/analytics/recent-activity/$userId';
    final response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      return json.decode(response.body)['recentActivity'];
    } else {
      throw Exception('Failed to load recent activity');
    }
  }
}
