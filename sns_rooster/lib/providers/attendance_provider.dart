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

  AttendanceProvider(this._authProvider) {
    _attendanceService = AttendanceService(_authProvider);
  }

  List<Map<String, dynamic>> get attendanceRecords => _attendanceRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get attendanceSummary => _attendanceSummary;
  String? get todayStatus => _todayStatus;

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
  }

  // Call this on dashboard load or after login to ensure correct state
  Future<void> fetchTodayStatus(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _todayStatus = await _attendanceService.getAttendanceStatus(userId);
      print('DEBUG: Updating todayStatus to: $_todayStatus');
    } catch (e) {
      print('DEBUG: Error while fetching todayStatus: $e');
      _error = e.toString();
      _todayStatus = null;
    } finally {
      _isLoading = false;
      print('DEBUG: Notifying listeners after todayStatus update');
      notifyListeners();
    }
  }

  // Break actions: these should call real backend endpoints if available
  Future<void> startBreakWithType(String userId, Map<String, dynamic> breakType) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // TODO: Replace with real backend call for starting break
      // await _attendanceService.startBreakWithType(userId, breakType);
      throw UnimplementedError('Break start endpoint not implemented');
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
      // TODO: Replace with real backend call for ending break
      // await _attendanceService.endBreak(userId);
      throw UnimplementedError('Break end endpoint not implemented');
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
