import 'dart:async';
import 'package:sns_rooster/utils/logger.dart';
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
      log('DEBUG: Initializing _apiService');
      final prefs = await SharedPreferences.getInstance();
      _apiService = ApiService(
        baseUrl: ApiConfig.baseUrl,
      );
      _apiServiceCompleter.complete();
      log('DEBUG: _apiService initialization complete');
    } catch (e) {
      _apiServiceCompleter.completeError(e);
      log('DEBUG: Error initializing _apiService: $e');
    }
  }

  List<LeaveRequest> get leaveRequests => _leaveRequests;
  bool get isLoading => _isLoading;

  Future<void> fetchLeaveRequests(
      {bool includeAdmins = true, String role = 'all'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiServiceCompleter.future; // Ensure initialization is complete

      final queryParams = {
        'includeAdmins': includeAdmins.toString(),
        'role': role
      };
      final response = await _apiService.get(
          '/leave/leave-requests?${Uri(queryParameters: queryParams).query}');
      if (response.success) {
        _leaveRequests = (response.data as List)
            .map((json) => LeaveRequest.fromJson(json))
            .toList();
      } else {
        log('Error fetching leave requests: ${response.message}');
        _leaveRequests = []; // Clear the list if the API call fails
      }
    } catch (e) {
      log('Error fetching leave requests: $e');
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
        log('Error approving leave request: ${response.message}');
      }
    } catch (e) {
      log('Error approving leave request: $e');
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
        log('Error rejecting leave request: ${response.message}');
      }
    } catch (e) {
      log('Error rejecting leave request: $e');
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
        log('Error creating leave request: ${response.message}');
      }
    } catch (e) {
      log('Error creating leave request: $e');
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
