import 'package:flutter/material.dart';
import 'package:sns_rooster/utils/logger.dart';
import 'package:sns_rooster/services/api_service.dart';
import 'package:sns_rooster/config/api_config.dart';

class LeaveRequestProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _leaveRequests = [];
  final Map<String, dynamic> _leaveBalances = {};
  String? _error;
  bool _isLoading = false;

  List<Map<String, dynamic>> get leaveRequests => _leaveRequests;
  Map<String, dynamic> get leaveBalances => _leaveBalances;
  String? get error => _error;
  bool get isLoading => _isLoading;

  // --- Get All Leave Requests (Admin) ---
  Future<void> getAllLeaveRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // TODO: Replace with real API call (e.g., GET /api/leave-requests).
      throw UnimplementedError("Real API call not implemented.");
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Get User Leave Requests (Employee) ---
  Future<void> getUserLeaveRequests(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final api = ApiService(baseUrl: ApiConfig.baseUrl);
      final response =
          await api.get('/leave/simple/history?employeeId=$employeeId');
      if (response.success && response.data != null) {
        _leaveRequests.clear();
        for (final item in response.data) {
          _leaveRequests.add(item);
        }
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Get User Leave Balances ---
  Future<void> fetchLeaveBalances(String employeeId) async {
    log('Fetching leave balance for employeeId: $employeeId');
    print('DEBUG: fetchLeaveBalances called with employeeId: $employeeId');
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final api = ApiService(baseUrl: ApiConfig.baseUrl);
      final response =
          await api.get('/employees/simple/$employeeId/leave-balance');
      print('DEBUG: Leave balance response: ${response.data}');
      print('DEBUG: Response success: ${response.success}');
      print('DEBUG: Response data type: ${response.data.runtimeType}');
      if (response.success && response.data != null) {
        _leaveBalances.clear();

        // Handle the new policy-driven balance format
        if (response.data['balance'] != null) {
          // Convert the balance format to the expected format
          final balance = response.data['balance'] as Map<String, dynamic>;
          final convertedBalances = <String, Map<String, dynamic>>{};

          balance.forEach((key, value) {
            // Convert keys like 'annualLeave' to 'annual'
            final shortKey =
                key.toString().replaceAll('Leave', '').toLowerCase();
            final valueMap = value as Map<String, dynamic>;
            convertedBalances[shortKey] = {
              'total': valueMap['total'],
              'used': valueMap['used'],
              'available': valueMap['available']
            };
          });

          print('DEBUG: Converted balances: $convertedBalances');
          _leaveBalances.addAll(convertedBalances);
        } else {
          // Fallback to old format
          print('DEBUG: Using fallback format: ${response.data}');
          _leaveBalances.addAll(response.data);
        }
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Create Leave Request (Employee/Admin) ---
  Future<bool> createLeaveRequest(Map<String, dynamic> requestData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final api = ApiService(baseUrl: ApiConfig.baseUrl);
      final response = await api.post('/leave/simple/apply', requestData);
      if (response.success) {
        // Optionally refresh leave requests after successful application
        // For admins, we might need a different endpoint to get their leave history
        if (requestData['employeeId'] != null) {
          await getUserLeaveRequests(requestData['employeeId'] ?? '');
        }
        return true;
      } else {
        _error = response.message;
        return false;
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
      // TODO: Replace with real API call (e.g., PATCH /api/leave-requests/:requestId/approve).
      throw UnimplementedError("Real API call not implemented.");
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
      // TODO: Replace with real API call (e.g., PATCH /api/leave-requests/:requestId/reject).
      throw UnimplementedError("Real API call not implemented.");
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Cancel Leave Request (Employee) ---
  Future<bool> cancelLeaveRequest(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final api = ApiService(baseUrl: ApiConfig.baseUrl);
      final response = await api.delete('/leave/simple/$requestId');
      if (response.success) {
        // Refresh leave requests after successful cancellation
        if (_leaveRequests.isNotEmpty) {
          final employeeId = _leaveRequests.first['employeeId'];
          if (employeeId != null) {
            await getUserLeaveRequests(employeeId);
          }
        }
        return true;
      } else {
        _error = response.message;
        return false;
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
      // TODO: Replace with real API call (e.g., DELETE /api/leave-requests/:leaveId).
      throw UnimplementedError("Real API call not implemented.");
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
      // TODO: Replace with real API call (e.g., PATCH /api/leave-requests/:leaveId).
      throw UnimplementedError("Real API call not implemented.");
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Fetch Employee ID by User ID ---
  Future<String?> fetchEmployeeIdByUserId(String userId) async {
    try {
      final api = ApiService(baseUrl: ApiConfig.baseUrl);
      final response = await api.get('/employees/user/$userId');

      if (response.success && response.data != null) {
        final employeeId = response.data['_id'];
        if (employeeId != null) {
          log('DEBUG: Successfully fetched employeeId: $employeeId');
          return employeeId;
        } else {
          log('ERROR: employeeId is null in response data.');
        }
      } else {
        log('ERROR: Failed to fetch employeeId. Response: success=${response.success}, message=${response.message}, data=${response.data}');
      }
    } catch (e) {
      log('ERROR: Exception while fetching employeeId: $e');
    }

    log('ERROR: Returning null for employeeId.');
    return null;
  }
}
