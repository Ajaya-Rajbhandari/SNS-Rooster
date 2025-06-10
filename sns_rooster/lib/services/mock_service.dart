import 'dart:convert';

// Mock data (simulating API responses) for SNS Rooster frontend.
// Use this mock service (with useMock = true) to build and test your UI without a backend.
// Later, replace with real HTTP calls (e.g., using http or dio).

// --- Mock Data ---

final Map<String, dynamic> _mockUser = {
  "_id": "mock_user_id_123",
  "name": "Mock User",
  "email": "testuser@example.com",
  "role": "employee",
  "department": "IT",
  "position": "Developer",
  "isActive": true,
  "isProfileComplete": true,
  "lastLogin": "2023-10-01T12:00:00Z",
  "avatar": "assets/images/sample_avatar.png",
  "password": "password123",
};

final List<Map<String, dynamic>> _mockUsers = [
  {
    "_id": "mock_user_1",
    "name": "Mock User 1",
    "email": "mock1@example.com",
    "role": "employee",
    "department": "IT",
    "position": "Developer",
    "isActive": true,
    "isProfileComplete": true,
    "lastLogin": "2023-10-01T12:00:00Z"
  },
  {
    "_id": "mock_user_2",
    "name": "Mock User 2",
    "email": "mock2@example.com",
    "role": "employee",
    "department": "HR",
    "position": "Manager",
    "isActive": true,
    "isProfileComplete": true,
    "lastLogin": "2023-10-01T12:00:00Z"
  },
  {
    "_id": "mock_user_3",
    "name": "Mock User 3",
    "email": "mock3@example.com",
    "role": "employee",
    "department": "Finance",
    "position": "Analyst",
    "isActive": false,
    "isProfileComplete": true,
    "lastLogin": "2023-10-01T12:00:00Z"
  },
  {
    "_id": "mock_user_test",
    "name": "Test User",
    "email": "testuser@example.com",
    "role": "employee",
    "department": "IT",
    "position": "Developer",
    "isActive": true,
    "isProfileComplete": true,
    "lastLogin": "2023-10-01T12:00:00Z",
    "avatar": "assets/images/sample_avatar.png",
    "password": "password123"
  },
  {
    "_id": "mock_admin_user_2",
    "name": "Admin User",
    "email": "adminuser@example.com",
    "role": "admin",
    "department": "Management",
    "position": "Senior Administrator",
    "isActive": true,
    "isProfileComplete": true,
    "lastLogin": "2023-10-01T12:00:00Z",
    "avatar": "assets/images/sample_avatar.png",
    "password": "adminpass2"
  }
];

final List<Map<String, dynamic>> _mockLeaveRequests = [
  {
    "_id": "leave_1",
    "userId": "mock_user_1",
    "leaveType": "annual",
    "startDate": "2023-10-01",
    "endDate": "2023-10-05",
    "status": "pending",
    "reason": "Vacation"
  },
  {
    "_id": "leave_2",
    "userId": "mock_user_2",
    "leaveType": "sick",
    "startDate": "2023-10-02",
    "endDate": "2023-10-03",
    "status": "approved",
    "reason": "Illness"
  }
];

// Mock Leave Balances
final Map<String, Map<String, dynamic>> _mockLeaveBalances = {
  "mock_user_id_123": {
    "annual": {"total": 20, "used": 15, "remaining": 5},
    "sick": {"total": 10, "used": 8, "remaining": 2},
    "casual": {"total": 5, "used": 3, "remaining": 2},
  },
  "mock_user_1": {
    "annual": {"total": 25, "used": 10, "remaining": 15},
    "sick": {"total": 12, "used": 5, "remaining": 7},
    "casual": {"total": 7, "used": 2, "remaining": 5},
  },
  "mock_admin_user_2": {
    "annual": {"total": 30, "used": 5, "remaining": 25},
    "sick": {"total": 15, "used": 2, "remaining": 13},
    "casual": {"total": 10, "used": 0, "remaining": 10},
  },
};

// Mock Payroll Slips
final List<Map<String, dynamic>> _mockPayrollSlips = [
  {
    "_id": "payroll_0",
    "userId": "mock_user_id_123",
    "payPeriod": "2024-03-01 to 2024-03-15",
    "netPay": 2750.00,
    "grossPay": 3250.00,
    "deductions": 500.00,
    "issueDate": "2024-03-15",
    "fileName": "payslip_mar_1.pdf"
  },
  {
    "_id": "payroll_1",
    "userId": "mock_user_test",
    "payPeriod": "2024-01-01 to 2024-01-15",
    "netPay": 2500.00,
    "grossPay": 3000.00,
    "deductions": 500.00,
    "issueDate": "2024-01-15",
    "fileName": "payslip_jan_1.pdf"
  },
  {
    "_id": "payroll_2",
    "userId": "mock_user_test",
    "payPeriod": "2024-01-16 to 2024-01-31",
    "netPay": 2600.00,
    "grossPay": 3100.00,
    "deductions": 500.00,
    "issueDate": "2024-01-31",
    "fileName": "payslip_jan_2.pdf"
  },
  {
    "_id": "payroll_3",
    "userId": "mock_user_1",
    "payPeriod": "2024-02-01 to 2024-02-15",
    "netPay": 2800.00,
    "grossPay": 3300.00,
    "deductions": 500.00,
    "issueDate": "2024-02-15",
    "fileName": "payslip_feb_1.pdf"
  }
];

// Mock Analytics Data
final Map<String, Map<String, int>> _mockAttendanceAnalytics = {
  "mock_user_test": {
    "Present": 20,
    "Absent": 2,
    "Leave": 3,
  },
  "mock_user_1": {
    "Present": 18,
    "Absent": 4,
    "Leave": 3,
  },
  "mock_admin_user_2": {
    "Present": 22,
    "Absent": 1,
    "Leave": 2,
  },
};

final Map<String, List<double>> _mockWorkHoursAnalytics = {
  "mock_user_test": [8.0, 7.5, 8.0, 9.0, 7.0, 8.5, 7.0],
  "mock_user_1": [7.0, 8.0, 8.5, 7.0, 9.0, 7.5, 8.0],
  "mock_admin_user_2": [9.0, 8.0, 8.5, 9.0, 7.0, 8.0, 7.5],
};

// Mock Holiday/Event Data
final List<Map<String, dynamic>> _mockHolidays = [
  {
    "id": "holiday_1",
    "title": "New Year's Day",
    "date": "2025-01-01",
    "type": "public_holiday",
    "description": "Public holiday for New Year's Day."
  },
  {
    "id": "holiday_2",
    "title": "Independence Day",
    "date": "2024-07-04",
    "type": "public_holiday",
    "description": "National holiday."
  },
  {
    "id": "event_1",
    "title": "Company Picnic",
    "date": "2024-08-15",
    "type": "company_event",
    "description": "Annual company picnic for all employees."
  },
  {
    "id": "holiday_3",
    "title": "Christmas Day",
    "date": "2024-12-25",
    "type": "public_holiday",
    "description": "Public holiday for Christmas."
  },
  {
    "id": "event_2",
    "title": "Annual Performance Reviews Due",
    "date": "2024-06-30",
    "type": "deadline",
    "description": "All annual performance reviews must be submitted."
  },
];

// Make _mockAttendance a mutable variable
Map<String, dynamic>? _mockCurrentAttendance;
List<Map<String, dynamic>> _mockAttendanceHistory = [
  {
    "_id": "attendance_1",
    "userId": "mock_user_1",
    "checkIn": "2024-03-01T09:00:00Z",
    "checkOut": "2024-03-01T17:00:00Z",
    "status": "present",
    "breaks": [
      {
        "start": "2024-03-01T12:00:00Z",
        "end": "2024-03-01T13:00:00Z",
        "duration": 60
      }
    ],
    "totalBreakDuration": 60,
    "notes": "Regular day",
    "createdAt": "2024-03-01T09:00:00Z",
    "updatedAt": "2024-03-01T17:00:00Z"
  },
  {
    "_id": "attendance_2",
    "userId": "mock_user_1",
    "checkIn": "2024-03-02T09:30:00Z",
    "checkOut": "2024-03-02T17:00:00Z",
    "status": "late",
    "breaks": [
      {
        "start": "2024-03-02T12:00:00Z",
        "end": "2024-03-02T13:00:00Z",
        "duration": 60
      }
    ],
    "totalBreakDuration": 60,
    "notes": "Traffic delay",
    "createdAt": "2024-03-02T09:30:00Z",
    "updatedAt": "2024-03-02T17:00:00Z"
  },
  {
    "_id": "attendance_3",
    "userId": "mock_user_1",
    "status": "absent",
    "notes": "Sick leave",
    "createdAt": "2024-03-03T00:00:00Z",
    "updatedAt": "2024-03-03T00:00:00Z"
  }
];

// Helper to reset mock attendance (for testing purposes)
void resetMockAttendance() {
  _mockCurrentAttendance = null;
  _mockAttendanceHistory = [];
}

// --- Mock Service ---

// Set this flag to true to use mock data (for frontend development) or false to use real API calls.
const bool useMock = false;

// --- Auth Mock Service ---

class MockAuthService {
  Future<Map<String, dynamic>?> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    final user = _mockUsers.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => {},
    );

    if (user.isNotEmpty) {
      // Generate a mock JWT with a valid structure (header.payload.signature)
      final String header = base64Url
          .encode(utf8.encode(json.encode({"alg": "HS256", "typ": "JWT"})));
      final int expirationTime =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
              1000;
      final String payload = base64Url
          .encode(utf8.encode(json.encode({...user, "exp": expirationTime})));
      final String token = "$header.$payload.mock_signature";

      return {'token': token, 'user': user};
    } else {
      return null; // Simulate login failure
    }
  }

  Future<Map<String, dynamic>?> registerUser(String name, String email,
      String password, String role, String department, String position) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    // Simulate successful registration with a new mock user ID
    final String newUserId =
        'mock_user_id_${DateTime.now().millisecondsSinceEpoch}';
    final Map<String, dynamic> newUser = {
      "_id": newUserId,
      "name": name,
      "email": email,
      "role": role,
      "department": department,
      "position": position,
      "isActive": true,
      "isProfileComplete": true,
      "lastLogin": DateTime.now().toIso8601String(),
      "avatar": "assets/images/sample_avatar.png",
      "password": password,
    };

    _mockUsers.add(newUser); // Add the new user to mock data

    // Generate a mock JWT with a valid structure (header.payload.signature)
    final String header = base64Url
        .encode(utf8.encode(json.encode({"alg": "HS256", "typ": "JWT"})));
    final int expirationTime =
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000;
    final String payload = base64Url
        .encode(utf8.encode(json.encode({...newUser, "exp": expirationTime})));
    final String token = "$header.$payload.mock_signature";

    return {'success': true, 'user': newUser, 'token': token};
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return true;
  }

  Future<void> logout() async {
    if (useMock) {
      // Simulate a delay to mimic a network call
      await Future.delayed(const Duration(milliseconds: 500));
      // Clear any mock session data if needed
      return;
    } else {
      // TODO: Replace with real API call (e.g., POST /api/auth/logout).
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> register(String name, String email,
      String password, String role, String department, String position) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      // Simulate a new user (in a real app, the backend would assign an _id).
      final newUser = {
        "_id": "new_mock_user",
        "name": name,
        "email": email,
        "role": role,
        "department": department,
        "position": position,
        "isActive": true,
        "isProfileComplete": false,
        "lastLogin": null
      };
      return {"message": "User created successfully", "user": newUser};
    } else {
      // TODO: Replace with real API call (e.g., POST /api/auth/register).
      throw UnimplementedError("Real API call not implemented.");
    }
  }
}

// --- Payroll Mock Service ---

class MockPayrollService {
  Future<List<Map<String, dynamic>>> getPayrollSlips() async {
    if (useMock) {
      await Future.delayed(
          const Duration(milliseconds: 500)); // Simulate network delay
      return _mockPayrollSlips;
    } else {
      // TODO: Replace with real API call (e.g., GET /api/payroll/slips).
      throw UnimplementedError(
          "Real API call for payroll slips not implemented.");
    }
  }
}

// --- Analytics Mock Service ---

class MockAnalyticsService {
  Future<Map<String, int>> getAttendanceAnalytics() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockAttendanceAnalytics['mock_user_test'] ?? {};
    }
    throw UnimplementedError('Real API not implemented yet');
  }

  Future<List<double>> getWorkHoursAnalytics() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockWorkHoursAnalytics['mock_user_test'] ?? [];
    }
    throw UnimplementedError('Real API not implemented yet');
  }
}

// --- Employee Mock Service ---

class MockEmployeeService {
  Future<List<Map<String, dynamic>>> getUsers() async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      return _mockUsers;
    } else {
      // TODO: Replace with real API call (e.g., GET /api/users).
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> updateUser(
      String userId, Map<String, dynamic> updates) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      // Simulate updating a user (in a real app, the backend would update the user).
      final user = _mockUsers.firstWhere((u) => u["_id"] == userId,
          orElse: () => throw Exception("User not found"));
      // Merge updates (in a real app, the backend would merge and validate).
      final updatedUser = {...user, ...updates};
      return {"message": "User updated successfully", "user": updatedUser};
    } else {
      // TODO: Replace with real API call (e.g., PATCH /api/users/:userId).
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> deleteUser(String userId) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      // Simulate deleting a user (in a real app, the backend would remove the user).
      final index = _mockUsers.indexWhere((u) => u["_id"] == userId);
      if (index == -1) throw Exception("User not found");
      _mockUsers.removeAt(index);
      return {"message": "User deleted successfully"};
    } else {
      // TODO: Replace with real API call (e.g., DELETE /api/users/:userId).
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      return {"user": _mockUser};
    } else {
      // TODO: Replace with real API call (e.g., GET /api/me).
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> updates) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      // Simulate updating the profile (in a real app, the backend would update the user).
      _mockUser.addAll(updates); // Update the global _mockUser object
      return {"message": "Profile updated successfully", "user": _mockUser};
    } else {
      // TODO: Replace with real API call (e.g., PATCH /api/me).
      throw UnimplementedError("Real API call not implemented.");
    }
  }
}

// --- Attendance Mock Service ---

class MockAttendanceService {
  Future<Map<String, dynamic>> checkIn(String userId, {String? notes}) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));

      // Check if user already has an active attendance
      if (_mockCurrentAttendance != null) {
        throw Exception("You have already checked in today");
      }

      final now = DateTime.now().toUtc();
      final attendance = {
        "_id": "attendance_${now.millisecondsSinceEpoch}",
        "userId": userId,
        "checkIn": now.toIso8601String(),
        "status": now.hour >= 9 ? "late" : "present",
        "breaks": [],
        "totalBreakDuration": 0,
        "notes": notes,
        "createdAt": now.toIso8601String(),
        "updatedAt": now.toIso8601String()
      };

      _mockCurrentAttendance = attendance;
      _mockAttendanceHistory.insert(0, attendance);

      return {"message": "Check-in successful", "attendance": attendance};
    } else {
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> checkOut(String userId, {String? notes}) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));

      if (_mockCurrentAttendance == null) {
        throw Exception("No active attendance found");
      }

      final now = DateTime.now().toUtc();
      final attendance = _mockCurrentAttendance!;
      attendance["checkOut"] = now.toIso8601String();
      attendance["notes"] = notes ?? attendance["notes"];
      attendance["updatedAt"] = now.toIso8601String();

      _mockCurrentAttendance = null;

      return {"message": "Check-out successful", "attendance": attendance};
    } else {
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(String userId,
      {DateTime? startDate, DateTime? endDate}) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));

      var filteredHistory =
          _mockAttendanceHistory.where((a) => a["userId"] == userId);

      if (startDate != null) {
        filteredHistory = filteredHistory
            .where((a) => DateTime.parse(a["createdAt"]).isAfter(startDate));
      }

      if (endDate != null) {
        filteredHistory = filteredHistory
            .where((a) => DateTime.parse(a["createdAt"]).isBefore(endDate));
      }

      return filteredHistory.toList();
    } else {
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>?> getCurrentAttendance(String userId) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      return _mockCurrentAttendance;
    } else {
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> getAttendanceSummary(String userId,
      {DateTime? startDate, DateTime? endDate}) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));

      final allAttendance = [..._mockAttendanceHistory];
      var filteredAttendance =
          allAttendance.where((a) => a["userId"] == userId);

      if (startDate != null) {
        filteredAttendance = filteredAttendance
            .where((a) => DateTime.parse(a["createdAt"]).isAfter(startDate));
      }

      if (endDate != null) {
        filteredAttendance = filteredAttendance
            .where((a) => DateTime.parse(a["createdAt"]).isBefore(endDate));
      }

      final attendanceList = filteredAttendance.toList();

      return {
        "totalDays": attendanceList.length,
        "presentDays":
            attendanceList.where((a) => a["status"] == "present").length,
        "lateDays": attendanceList.where((a) => a["status"] == "late").length,
        "absentDays":
            attendanceList.where((a) => a["status"] == "absent").length,
        "averageWorkHours": attendanceList
                .where((a) => a["checkIn"] != null && a["checkOut"] != null)
                .map((a) {
              final checkIn = DateTime.parse(a["checkIn"]);
              final checkOut = DateTime.parse(a["checkOut"]);
              final breakDuration = a["totalBreakDuration"] ?? 0;
              return checkOut.difference(checkIn).inHours -
                  (breakDuration / 60);
            }).fold(0.0, (sum, hours) => sum + hours) /
            (attendanceList
                .where((a) => a["checkIn"] != null && a["checkOut"] != null)
                .length)
      };
    } else {
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> startBreak(String userId) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_mockCurrentAttendance == null ||
          _mockCurrentAttendance!["userId"] != userId) {
        throw Exception("No active attendance found");
      }
      // Check if already on break
      final breaks = List<Map<String, dynamic>>.from(
          _mockCurrentAttendance!["breaks"] ?? []);
      if (breaks.isNotEmpty && breaks.last["end"] == null) {
        throw Exception("Already on break");
      }
      final now = DateTime.now().toUtc();
      breaks.add({"start": now.toIso8601String(), "end": null, "duration": 0});
      _mockCurrentAttendance!["breaks"] = breaks;
      _mockCurrentAttendance!["updatedAt"] = now.toIso8601String();
      return {"message": "Break started", "attendance": _mockCurrentAttendance};
    } else {
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> endBreak(String userId) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_mockCurrentAttendance == null ||
          _mockCurrentAttendance!["userId"] != userId) {
        throw Exception("No active attendance found");
      }
      final breaks = List<Map<String, dynamic>>.from(
          _mockCurrentAttendance!["breaks"] ?? []);
      if (breaks.isEmpty || breaks.last["end"] != null) {
        throw Exception("Not currently on break");
      }
      final now = DateTime.now().toUtc();
      final start = DateTime.parse(breaks.last["start"]);
      final duration = now.difference(start).inMinutes;
      breaks.last["end"] = now.toIso8601String();
      breaks.last["duration"] = duration;
      _mockCurrentAttendance!["breaks"] = breaks;
      // Update total break duration
      final totalBreakDuration =
          breaks.fold<int>(0, (sum, b) => sum + ((b["duration"] ?? 0) as int));
      _mockCurrentAttendance!["totalBreakDuration"] = totalBreakDuration;
      _mockCurrentAttendance!["updatedAt"] = now.toIso8601String();
      return {"message": "Break ended", "attendance": _mockCurrentAttendance};
    } else {
      throw UnimplementedError("Real API call not implemented.");
    }
  }
}

// --- Leave Request Mock Service ---

class MockLeaveRequestService {
  Future<List<Map<String, dynamic>>> getLeaveRequests() async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      return _mockLeaveRequests;
    } else {
      // TODO: Replace with real API call (e.g., GET /api/leave-requests).
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<List<Map<String, dynamic>>> getLeaveRequestsByUser(
      String userId) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      final userRequests =
          _mockLeaveRequests.where((req) => req["userId"] == userId).toList();
      print(
          'MockLeaveRequestService: Returning requests for user $userId: $userRequests');
      return userRequests;
    } else {
      // TODO: Replace with real API call (e.g., GET /api/users/:userId/leave-requests).
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> createLeaveRequest(
      Map<String, dynamic> requestData) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      // Simulate creating a new leave request (in a real app, the backend would assign an _id).
      final newRequest = {
        "_id": "leave_${_mockLeaveRequests.length + 1}",
        "status": "pending", // Default status for new requests
        "createdAt": DateTime.now().toIso8601String(),
        "updatedAt": DateTime.now().toIso8601String(),
        "approverId": null,
        "comments": "",
        ...requestData,
      };
      _mockLeaveRequests.add(newRequest);
      print(
          'MockLeaveRequestService: After creating, _mockLeaveRequests: $_mockLeaveRequests');
      return {
        "message": "Leave request created successfully",
        "leaveRequest": newRequest
      };
    } else {
      // TODO: Replace with real API call (e.g., POST /api/leave-requests).
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> updateLeaveRequestStatus(
      String requestId, String status) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      final requestIndex =
          _mockLeaveRequests.indexWhere((req) => req["_id"] == requestId);
      if (requestIndex == -1) throw Exception("Leave request not found");
      _mockLeaveRequests[requestIndex]["status"] = status;
      return {
        "message": "Leave request status updated",
        "leaveRequest": _mockLeaveRequests[requestIndex]
      };
    } else {
      // TODO: Replace with real API call (e.g., PATCH /api/leave-requests/:requestId/status).
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<bool> deleteLeaveRequest(String leaveId) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      final index =
          _mockLeaveRequests.indexWhere((req) => req["_id"] == leaveId);
      if (index != -1) {
        _mockLeaveRequests.removeAt(index);
        return true;
      }
      return false;
    } else {
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<bool> updateLeaveRequest(
      String leaveId, Map<String, dynamic> updates) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      final index =
          _mockLeaveRequests.indexWhere((req) => req["_id"] == leaveId);
      if (index != -1) {
        _mockLeaveRequests[index] = {..._mockLeaveRequests[index], ...updates};
        return true;
      }
      return false;
    } else {
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> getLeaveBalancesByUser(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockLeaveBalances[userId] ?? {};
  }
}

// --- Holiday/Event Mock Service ---
class MockHolidayService {
  Future<List<Map<String, dynamic>>> getHolidays() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockHolidays;
    }
    throw UnimplementedError('Real API not implemented yet');
  }
}
