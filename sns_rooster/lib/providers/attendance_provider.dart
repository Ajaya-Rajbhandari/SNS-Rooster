import 'dart:convert';
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../services/attendance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    } catch (e) {
      _error = e.toString();
      _todayStatus = null;
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
}
