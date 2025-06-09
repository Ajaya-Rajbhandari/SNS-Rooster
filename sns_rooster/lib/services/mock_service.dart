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
  "avatar": "assets/images/profile_placeholder.png",
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
    "avatar": "assets/images/profile_placeholder.png",
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
    "avatar": "assets/images/profile_placeholder.png",
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
const bool useMock = true;

// --- Auth Mock Service ---

class MockAuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (useMock) {
      // Simulate a delay (e.g., 1 second) to mimic a network call.
      await Future.delayed(const Duration(seconds: 1));
      if ((email == "mock@example.com" && password == "password") ||
          (email == "testuser@example.com" && password == "password123") ||
          (email == "adminuser@example.com" && password == "adminpass2")) {
        // Find the user in _mockUsers
        final user = _mockUsers.firstWhere(
          (u) => u["email"] == email && u["password"] == password,
          orElse: () => _mockUser,
        );
        // Generate a mock JWT with a valid structure (header.payload.signature)
        final String header = base64Url
            .encode(utf8.encode(json.encode({"alg": "HS256", "typ": "JWT"})));
        final int expirationTime = DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000;
        final String payload = base64Url
            .encode(utf8.encode(json.encode({...user, "exp": expirationTime})));
        final String mockToken = "$header.$payload.mock_signature";

        return {"token": mockToken, "user": user};
      } else {
        throw Exception("Invalid email or password");
      }
    } else {
      // TODO: Replace with real API call (e.g., POST /api/auth/login).
      throw UnimplementedError("Real API call not implemented.");
    }
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
}
