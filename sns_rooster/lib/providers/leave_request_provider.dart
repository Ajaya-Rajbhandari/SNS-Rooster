import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/mock_service.dart'; // Import the mock service

class LeaveRequestProvider with ChangeNotifier {
  List<Map<String, dynamic>> _leaveRequests = [];
  String? _error;
  bool _isLoading = false;

  // Instantiate the mock service (with useMock = true) so that we can simulate API responses.
  final MockLeaveRequestService _mockLeaveRequestService =
      MockLeaveRequestService();

  List<Map<String, dynamic>> get leaveRequests => _leaveRequests;
  String? get error => _error;
  bool get isLoading => _isLoading;

  // --- Get All Leave Requests (Admin) ---
  Future<void> getAllLeaveRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        _leaveRequests = await _mockLeaveRequestService.getLeaveRequests();
      } else {
        // TODO: Replace with real API call (e.g., GET /api/leave-requests).
        throw UnimplementedError("Real API call not implemented.");
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Get User Leave Requests (Employee) ---
  Future<void> getUserLeaveRequests(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        _leaveRequests =
            await _mockLeaveRequestService.getLeaveRequestsByUser(userId);
        print(
            'LeaveRequestProvider: _leaveRequests after fetch: $_leaveRequests');
      } else {
        // TODO: Replace with real API call (e.g., GET /api/users/:userId/leave-requests).
        throw UnimplementedError("Real API call not implemented.");
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Create Leave Request (Employee) ---
  Future<bool> createLeaveRequest(Map<String, dynamic> requestData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        final response =
            await _mockLeaveRequestService.createLeaveRequest(requestData);
        // Add the new request to the local state
        if (response['leaveRequest'] != null) {
          _leaveRequests.add(response['leaveRequest']);
        }
        print("Create leave request (mock) response: ${response}");
        return true;
      } else {
        // TODO: Replace with real API call (e.g., POST /api/leave-requests).
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

  // --- Approve Leave Request (Admin) ---
  Future<bool> approveLeaveRequest(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        final response = await _mockLeaveRequestService
            .updateLeaveRequestStatus(requestId, "approved");
        // In a real app, you might refresh the list (or update local state) after approval.
        print("Approve leave request (mock) response: ${response}");
        return true;
      } else {
        // TODO: Replace with real API call (e.g., PATCH /api/leave-requests/:requestId/approve).
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

  // --- Reject Leave Request (Admin) ---
  Future<bool> rejectLeaveRequest(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (useMock) {
        final response = await _mockLeaveRequestService
            .updateLeaveRequestStatus(requestId, "rejected");
        // In a real app, you might refresh the list (or update local state) after rejection.
        print("Reject leave request (mock) response: ${response}");
        return true;
      } else {
        // TODO: Replace with real API call (e.g., PATCH /api/leave-requests/:requestId/reject).
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

  Future<bool> deleteLeaveRequest(String leaveId) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (useMock) {
        final result =
            await _mockLeaveRequestService.deleteLeaveRequest(leaveId);
        if (result) {
          _leaveRequests.removeWhere((leave) => leave['_id'] == leaveId);
        }
        return result;
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

  Future<bool> updateLeaveRequest(
      String leaveId, Map<String, dynamic> updates) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (useMock) {
        final result =
            await _mockLeaveRequestService.updateLeaveRequest(leaveId, updates);
        if (result) {
          final index =
              _leaveRequests.indexWhere((leave) => leave['_id'] == leaveId);
          if (index != -1) {
            _leaveRequests[index] = {..._leaveRequests[index], ...updates};
          }
        }
        return result;
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
}
