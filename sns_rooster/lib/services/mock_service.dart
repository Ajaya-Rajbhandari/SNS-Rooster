import 'dart:convert';
import 'package:flutter/material.dart';

// Mock data (simulating API responses) for SNS Rooster frontend.
// Use this mock service (with useMock = true) to build and test your UI without a backend.
// Later, replace with real HTTP calls (e.g., using http or dio).

// --- Mock Data ---

final Map<String, dynamic> _mockUser = {
  "_id": "mock_user_id",
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
List<Map<String, dynamic>> _mockAttendanceHistory = [];

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
          (email == "testuser@example.com" && password == "password123")) {
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

  Future<Map<String, dynamic>> logout() async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      return {"message": "Logged out successfully"};
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
  Future<Map<String, dynamic>> checkIn({String? note}) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      final now = DateTime.now().toUtc().toIso8601String();
      // Simulate a new check-in record
      _mockCurrentAttendance = {
        "_id": "mock_attendance_id_" +
            DateTime.now().millisecondsSinceEpoch.toString(),
        "userId": _mockUser["_id"],
        "checkIn": now,
        "checkOut": null,
        "breaks": [], // Initialize with empty breaks array
        "totalBreakDuration": 0, // Initialize total break duration
        "note": note ?? "",
      };
      // Add to history for completeness (optional, but good for overview)
      _mockAttendanceHistory.add(_mockCurrentAttendance!);

      return {
        "message": "Check-in recorded",
        "attendance": _mockCurrentAttendance
      };
    } else {
      // TODO: Replace with real API call (e.g., POST /api/attendance/check-in).
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> checkOut({String? note}) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      final now = DateTime.now().toUtc().toIso8601String();

      if (_mockCurrentAttendance == null) {
        throw Exception("No active check-in to check out from.");
      }

      // Ensure any ongoing break is ended before checkout
      if (_mockCurrentAttendance!['breaks'] != null) {
        final lastBreak = _mockCurrentAttendance!['breaks'].isNotEmpty
            ? _mockCurrentAttendance!['breaks'].last
            : null;
        if (lastBreak != null && lastBreak['endTime'] == null) {
          final breakStartTime = DateTime.parse(lastBreak['startTime']);
          final breakDuration =
              DateTime.now().difference(breakStartTime).inMilliseconds;
          lastBreak['endTime'] = now;
          _mockCurrentAttendance!['totalBreakDuration'] =
              (_mockCurrentAttendance!['totalBreakDuration'] ?? 0) +
                  breakDuration;
        }
      }

      _mockCurrentAttendance!['checkOut'] = now;
      _mockCurrentAttendance!['note'] = note ?? '';

      return {
        "message": "Check-out recorded",
        "attendance": _mockCurrentAttendance
      };
    } else {
      // TODO: Replace with real API call (e.g., POST /api/attendance/check-out).
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> startBreak() async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      final now = DateTime.now().toUtc().toIso8601String();

      if (_mockCurrentAttendance == null ||
          _mockCurrentAttendance!['checkOut'] != null) {
        throw Exception("Not clocked in or already clocked out.");
      }

      if (_mockCurrentAttendance!['breaks'] != null &&
          _mockCurrentAttendance!['breaks'].isNotEmpty) {
        final lastBreak = _mockCurrentAttendance!['breaks'].last;
        if (lastBreak['endTime'] == null) {
          throw Exception("Already on break. Please end current break first.");
        }
      }

      // Add a new break entry
      _mockCurrentAttendance!['breaks'] =
          List.from(_mockCurrentAttendance!['breaks'] ?? []);
      _mockCurrentAttendance!['breaks'].add({
        "startTime": now,
        "endTime": null,
      });

      return {"message": "Break started", "attendance": _mockCurrentAttendance};
    } else {
      // TODO: Replace with real API call (e.g., POST /api/attendance/start-break).
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> endBreak() async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      final now = DateTime.now().toUtc().toIso8601String();

      if (_mockCurrentAttendance == null ||
          _mockCurrentAttendance!['checkOut'] != null) {
        throw Exception("Not clocked in or already clocked out.");
      }

      if (_mockCurrentAttendance!['breaks'] == null ||
          _mockCurrentAttendance!['breaks'].isEmpty) {
        throw Exception("No break in progress to end.");
      }

      final lastBreak = _mockCurrentAttendance!['breaks'].last;
      if (lastBreak['endTime'] != null) {
        throw Exception("No active break found to end.");
      }

      final breakStartTime = DateTime.parse(lastBreak['startTime']);
      final breakDuration =
          DateTime.now().difference(breakStartTime).inMilliseconds;

      lastBreak['endTime'] = now; // Mark the break as ended

      // Update total break duration
      _mockCurrentAttendance!['totalBreakDuration'] =
          (_mockCurrentAttendance!['totalBreakDuration'] ?? 0) + breakDuration;

      return {"message": "Break ended", "attendance": _mockCurrentAttendance};
    } else {
      // TODO: Replace with real API call (e.g., POST /api/attendance/end-break).
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> getAttendanceHistory() async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));

      // Combine current attendance with history. If current attendance is active, it should be the first entry.
      List<Map<String, dynamic>> history = [];
      if (_mockCurrentAttendance != null) {
        history.add(_mockCurrentAttendance!); // Add the active record
      }
      // Add other historical records, ensuring they don't duplicate the current one
      history.addAll(_mockAttendanceHistory.where((record) =>
          record['_id'] != _mockCurrentAttendance?['_id'] ||
          _mockCurrentAttendance == null));

      return {"message": "Attendance history fetched", "history": history};
    } else {
      // TODO: Replace with real API call (e.g., GET /api/attendance/history).
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
      return _mockLeaveRequests
          .where((req) => req["userId"] == userId)
          .toList();
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
        ...requestData,
      };
      _mockLeaveRequests.add(newRequest);
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
}
