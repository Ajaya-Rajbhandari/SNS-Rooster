// lib/services/mock_leave_request_service.dart

import 'package:sns_rooster/models/leave_request.dart';

class MockLeaveRequestService {
  Future<LeaveRequest> createLeaveRequest({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    // Mock leave request data
    LeaveRequest mockLeaveRequest = LeaveRequest(
      id: 'leave_request_id',
      userId: 'user_id',
      leaveType: leaveType,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      status: 'pending',
    );

    // Simulate successful leave request submission
    return mockLeaveRequest;
  }

  Future<List<LeaveRequest>> getLeaveRequests() async {
    // Mock leave request data
    List<LeaveRequest> mockLeaveRequests = [
      LeaveRequest(
        id: 'leave_request_id_1',
        userId: 'user_id',
        leaveType: 'annual',
        startDate: DateTime.now().add(Duration(days: 10)),
        endDate: DateTime.now().add(Duration(days: 15)),
        reason: 'Vacation',
        status: 'pending',
      ),
      LeaveRequest(
        id: 'leave_request_id_2',
        userId: 'user_id',
        leaveType: 'sick',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: 2)),
        reason: 'Feeling unwell',
        status: 'approved',
      ),
    ];

    // Simulate successful retrieval of leave requests
    return mockLeaveRequests;
  }
}
