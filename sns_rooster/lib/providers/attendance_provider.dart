import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // Assuming AuthProvider is in this path
import '../services/mock_service.dart'; // Import the mock service

class AttendanceProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  List<Map<String, dynamic>> _attendanceRecords = [];
  Map<String, dynamic>?
      _currentAttendance; // New: to hold the active attendance record
  bool _isLoading = false;
  String? _error;

  // API base URL - ensure this matches your backend config
  final String _baseUrl = 'http://10.0.2.2:5000/api'; // For Android emulator
  // Use 'http://localhost:5000/api' for iOS simulator

  // Instantiate the mock service (with useMock = true) so that we can simulate API responses.
  final MockAttendanceService _mockAttendanceService = MockAttendanceService();

  AttendanceProvider(this._authProvider);

  List<Map<String, dynamic>> get attendanceRecords => _attendanceRecords;
  Map<String, dynamic>? get currentAttendance =>
      _currentAttendance; // New getter
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllAttendance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (!_authProvider.isAuthenticated || _authProvider.token == null) {
      _error = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      if (useMock) {
        final userId = _authProvider.user?['_id'] ?? 'mock_user_1';
        final response =
            await _mockAttendanceService.getAttendanceHistory(userId);
        _attendanceRecords = response;
      } else {
        final response = await http.get(
          Uri.parse('$_baseUrl/attendance'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_authProvider.token}',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _attendanceRecords =
              List<Map<String, dynamic>>.from(data['attendance']);
          _error = null;
        } else {
          final data = json.decode(response.body);
          _error = data['message'] ?? 'Failed to fetch attendance records';
        }
      }
    } catch (e) {
      _error = 'Network error occurred: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserAttendance(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (!_authProvider.isAuthenticated || _authProvider.token == null) {
      _error = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      if (useMock) {
        final response =
            await _mockAttendanceService.getAttendanceHistory(userId);
        _attendanceRecords = response;

        // Get current attendance
        _currentAttendance =
            await _mockAttendanceService.getCurrentAttendance(userId);
      } else {
        final response = await http.get(
          Uri.parse('$_baseUrl/attendance/user/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_authProvider.token}',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _currentAttendance = data['attendance'];
          _attendanceRecords =
              List<Map<String, dynamic>>.from(data['history'] ?? []);
          _error = null;
        } else {
          final data = json.decode(response.body);
          _error = data['message'] ?? 'Failed to fetch user attendance records';
        }
      }
    } catch (e) {
      _error = 'Network error occurred: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkIn() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        final userId = _authProvider.user?['_id'] ?? 'mock_user_1';
        final response = await _mockAttendanceService.checkIn(userId);
        _currentAttendance = response["attendance"];
        return true;
      } else {
        // TODO: Replace with real API call
        throw UnimplementedError("Real API call not implemented.");
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        final userId = _authProvider.user?['_id'] ?? 'mock_user_1';
        final response = await _mockAttendanceService.checkOut(userId);
        _currentAttendance = response["attendance"];
        return true;
      } else {
        // TODO: Replace with real API call
        throw UnimplementedError("Real API call not implemented.");
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getAttendanceHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        final userId = _authProvider.user?['_id'] ?? 'mock_user_1';
        final response =
            await _mockAttendanceService.getAttendanceHistory(userId);
        _attendanceRecords = response;
      } else {
        // TODO: Replace with real API call
        throw UnimplementedError("Real API call not implemented.");
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startBreak() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        final userId = _authProvider.user?['_id'] ?? 'mock_user_1';
        final response = await _mockAttendanceService.startBreak(userId);
        _currentAttendance = response["attendance"];
        return true;
      } else {
        throw UnimplementedError("Real API call not implemented.");
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> endBreak() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        final userId = _authProvider.user?['_id'] ?? 'mock_user_1';
        final response = await _mockAttendanceService.endBreak(userId);
        _currentAttendance = response["attendance"];
        return true;
      } else {
        throw UnimplementedError("Real API call not implemented.");
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Methods for check-in/check-out can be added here if needed for employee-side
}
