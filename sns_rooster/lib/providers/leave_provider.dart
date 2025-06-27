import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leave_request.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class LeaveProvider with ChangeNotifier {
  late final ApiService _apiService;
  final Completer<void> _apiServiceCompleter = Completer<void>();
  List<LeaveRequest> _leaveRequests = [];
  bool _isLoading = false;

  LeaveProvider() {
    _initializeApiService();
  }

  Future<void> _initializeApiService() async {
    try {
      print('DEBUG: Initializing _apiService');
      final prefs = await SharedPreferences.getInstance();
      _apiService = ApiService(
        baseUrl: ApiConfig.baseUrl,
        prefs: prefs,
      );
      _apiServiceCompleter.complete();
      print('DEBUG: _apiService initialization complete');
    } catch (e) {
      _apiServiceCompleter.completeError(e);
      print('DEBUG: Error initializing _apiService: $e');
    }
  }

  List<LeaveRequest> get leaveRequests => _leaveRequests;
  bool get isLoading => _isLoading;

  Future<void> fetchLeaveRequests() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiServiceCompleter.future; // Ensure initialization is complete

      final response = await _apiService.get('/leave/leave-requests');
      if (response.success) {
        _leaveRequests = (response.data as List)
            .map((json) => LeaveRequest.fromJson(json))
            .toList();
      } else {
        print('Error fetching leave requests: ${response.message}');
        _leaveRequests = []; // Clear the list if the API call fails
      }
    } catch (e) {
      print('Error fetching leave requests: $e');
      _leaveRequests = []; // Clear the list if the API call fails
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveLeaveRequest(String id) async {
    try {
      final response = await _apiService.put('/leave/$id/approve');
      if (response.success) {
        _leaveRequests = _leaveRequests.map((request) {
          if (request.id == id) {
            return request.copyWith(
              status: LeaveRequestStatus.approved,
              updatedAt: DateTime.now(),
            );
          }
          return request;
        }).toList();
        notifyListeners();
      } else {
        print('Error approving leave request: ${response.message}');
      }
    } catch (e) {
      print('Error approving leave request: $e');
      // For development, update the mock data
      _leaveRequests = _leaveRequests.map((request) {
        if (request.id == id) {
          return request.copyWith(
            status: LeaveRequestStatus.approved,
            updatedAt: DateTime.now(),
          );
        }
        return request;
      }).toList();
      notifyListeners();
    }
  }

  Future<void> rejectLeaveRequest(String id) async {
    try {
      final response = await _apiService.put('/leave/$id/reject');
      if (response.success) {
        _leaveRequests = _leaveRequests.map((request) {
          if (request.id == id) {
            return request.copyWith(
              status: LeaveRequestStatus.rejected,
              updatedAt: DateTime.now(),
            );
          }
          return request;
        }).toList();
        notifyListeners();
      } else {
        print('Error rejecting leave request: ${response.message}');
      }
    } catch (e) {
      print('Error rejecting leave request: $e');
      // For development, update the mock data
      _leaveRequests = _leaveRequests.map((request) {
        if (request.id == id) {
          return request.copyWith(
            status: LeaveRequestStatus.rejected,
            updatedAt: DateTime.now(),
          );
        }
        return request;
      }).toList();
      notifyListeners();
    }
  }

  Future<void> createLeaveRequest(LeaveRequest request) async {
    try {
      final response = await _apiService.post('/leave', request.toJson());
      if (response.success) {
        final newRequest = LeaveRequest.fromJson(response.data);
        _leaveRequests.add(newRequest);
        notifyListeners();
      } else {
        print('Error creating leave request: ${response.message}');
      }
    } catch (e) {
      print('Error creating leave request: $e');
      // For development, add to mock data
      _leaveRequests.add(request);
      notifyListeners();
    }
  }

  Future<String> getAuthorizationHeader() async {
    return await _apiService.getAuthorizationHeader();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
