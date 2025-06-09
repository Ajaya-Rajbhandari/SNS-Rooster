import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leave_request.dart';
import '../services/api_service.dart';

class LeaveProvider with ChangeNotifier {
  late final ApiService _apiService;
  List<LeaveRequest> _leaveRequests = [];
  bool _isLoading = false;

  LeaveProvider() {
    _initializeApiService();
  }

  Future<void> _initializeApiService() async {
    final prefs = await SharedPreferences.getInstance();
    _apiService = ApiService(
      baseUrl: 'http://localhost:3000/api', // Update with your backend URL
      prefs: prefs,
    );
  }

  List<LeaveRequest> get leaveRequests => _leaveRequests;
  bool get isLoading => _isLoading;

  Future<void> fetchLeaveRequests() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/leave-requests');
      if (response.success) {
        _leaveRequests = (response.data as List)
            .map((json) => LeaveRequest.fromJson(json))
            .toList();
      } else {
        print('Error fetching leave requests: ${response.message}');
        // For development, add some mock data
        _addMockData();
      }
    } catch (e) {
      print('Error fetching leave requests: $e');
      // For development, add some mock data
      _addMockData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _addMockData() {
    _leaveRequests = [
      LeaveRequest(
        id: '1',
        employeeId: 'emp1',
        employeeName: 'John Doe',
        leaveType: LeaveType.annual,
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 3)),
        duration: 3,
        reason: 'Family vacation',
        status: LeaveRequestStatus.pending,
        createdAt: DateTime.now(),
      ),
      LeaveRequest(
        id: '2',
        employeeId: 'emp2',
        employeeName: 'Jane Smith',
        leaveType: LeaveType.sick,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 2)),
        duration: 2,
        reason: 'Not feeling well',
        status: LeaveRequestStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  Future<void> approveLeaveRequest(String id) async {
    try {
      final response = await _apiService.put('/leave-requests/$id/approve');
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
      final response = await _apiService.put('/leave-requests/$id/reject');
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
      final response = await _apiService.post('/leave-requests', request.toJson());
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

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
} 