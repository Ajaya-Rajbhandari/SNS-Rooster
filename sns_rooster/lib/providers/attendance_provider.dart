import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../services/attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  late final AttendanceService _attendanceService;
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _attendanceSummary;
  String? _todayStatus;
  Map<String, dynamic>? _currentAttendance;

  AttendanceProvider(this._authProvider) {
    _attendanceService = AttendanceService(_authProvider);
  }

  List<Map<String, dynamic>> get attendanceRecords => _attendanceRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get attendanceSummary => _attendanceSummary;
  String? get todayStatus => _todayStatus;
  Map<String, dynamic>? get currentAttendance => _currentAttendance;

  Future<void> fetchUserAttendance(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _attendanceRecords = await _attendanceService.getAttendanceHistory(userId);
      _error = null;
    } catch (e) {
      _error = 'Network error occurred: \\${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAttendanceSummary(String userId, {DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _attendanceSummary = await _attendanceService.getAttendanceSummary(userId, startDate: startDate, endDate: endDate);
      _error = null;
    } catch (e) {
      _error = 'Network error occurred: \\${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }  // Call this on dashboard load or after login to ensure correct state
  Future<void> fetchTodayStatus(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final statusData = await _attendanceService.getAttendanceStatusWithData(userId);
      final fetchedStatus = statusData['status'] as String;
      final attendanceData = statusData['attendance'] as Map<String, dynamic>?;
      
      // Map backend status to UI status
      if (fetchedStatus == 'No current attendance') {
        _todayStatus = 'not_clocked_in';
        _currentAttendance = null;
      } else {
        _todayStatus = fetchedStatus;
        _currentAttendance = attendanceData;
      }
      print('DEBUG: _todayStatus after update in fetchTodayStatus: $_todayStatus');
      print('DEBUG: _currentAttendance after update in fetchTodayStatus: $_currentAttendance');
    } catch (e) {
      print('DEBUG: Error while fetching todayStatus: $e');
      _error = 'Failed to fetch attendance status.';
      _todayStatus = null;
      _currentAttendance = null;
    } finally {
      _isLoading = false;
      print('DEBUG: Notifying listeners after todayStatus update');
      notifyListeners();
    }
  }

  // Fetch detailed current attendance including break information
  Future<void> fetchCurrentAttendance(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentAttendance = await _attendanceService.getCurrentAttendance(userId);
      print('DEBUG: Current attendance details: $_currentAttendance');
      _error = null;
    } catch (e) {
      print('DEBUG: Error while fetching current attendance: $e');
      _error = 'Failed to fetch current attendance details.';
      _currentAttendance = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Break actions: these should call real backend endpoints if available
  Future<void> startBreakWithType(String userId, Map<String, dynamic> breakType) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _attendanceService.startBreakWithType(userId, breakType);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> endBreak(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _attendanceService.endBreak(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearAttendance() {
    _attendanceRecords = [];
    _error = null;
    notifyListeners();
  }

  Future<void> fetchBreakTypes(BuildContext context) async {
    try {
      print('FETCH_BREAK_TYPES_DEBUG: Token being sent: ${_authProvider.authToken}');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/attendance/break-types'),
        headers: {
          'Authorization': 'Bearer ${_authProvider.authToken}',
        },
      );

      print('FETCH_BREAK_TYPES_DEBUG: Response status code: ${response.statusCode}');
      print('FETCH_BREAK_TYPES_DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Handle successful response
      } else {
        // Handle error response
      }
    } catch (e) {
      print('FETCH_BREAK_TYPES_DEBUG: Error during API call: $e');
    }
  }
}
