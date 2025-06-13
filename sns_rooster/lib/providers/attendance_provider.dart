import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart'; // Assuming AuthProvider is in this path
import '../services/mock_service.dart'; // Import the mock service

class AttendanceProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  List<Map<String, dynamic>> _attendanceRecords = [];
  Map<String, dynamic>?
      _currentAttendance; // New: to hold the active attendance record
  bool _isLoading = false;
  String? _error;
  bool useMock = true; // Define and initialize useMock

  // API base URL - ensure this matches your backend config
  final String _baseUrl =
      'http://192.168.1.71:5000/api'; // For Android emulator
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
        // TODO: Replace with real API call
        print("Real API call for fetchUserAttendance not implemented. Returning empty data for now.");
        _currentAttendance = null; // Simulate no current attendance
        _attendanceRecords = []; // Simulate empty history
        _error = null; // Simulate success
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
    print('DEBUG: useMock value in checkIn: \$useMock');
    notifyListeners();
    try {
      if (useMock) {
        final userId = _authProvider.user?['_id'] ?? 'mock_user_1';
        print('DEBUG: Using mockAttendanceService.checkIn for userId: \$userId');
        final response = await _mockAttendanceService.checkIn(userId);
        _currentAttendance = response["attendance"];
        return true;
      } else {
        print("DEBUG: Real API call for checkIn would be made here.");
        _currentAttendance = {"message": "Checked in via placeholder real API"};
        return true;
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
        print("Real API call for checkOut not implemented. Returning success for now.");
        _currentAttendance = {"message": "Checked out via placeholder real API"};
        return true; // Simulate success
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
        print("Real API call for getAttendanceHistory not implemented. Returning empty list for now.");
        _attendanceRecords = []; // Simulate success with empty data
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
        // TODO: Replace with real API call
        print("Real API call for startBreak not implemented. Returning success for now.");
        _currentAttendance = {"message": "Started break via placeholder real API"};
        return true; // Simulate success
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
        // TODO: Replace with real API call
        print("Real API call for endBreak not implemented. Returning success for now.");
        _currentAttendance = {"message": "Ended break via placeholder real API"};
        return true; // Simulate success
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
