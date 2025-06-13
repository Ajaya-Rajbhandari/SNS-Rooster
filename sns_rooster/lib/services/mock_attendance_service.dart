// lib/services/mock_attendance_service.dart

import 'package:sns_rooster/models/attendance.dart';

class MockAttendanceService {
  Future<Map<String, dynamic>> checkIn({String? note}) async {
    // Mock attendance data
    Attendance mockAttendance = Attendance(
      date: DateTime.now(), // Added date
      status: AttendanceStatus.present, // Added status
      checkInTime: DateTime.now(),
      notes: note,
      // id and userId are not part of the Attendance model constructor directly
    );

    // Simulate successful check-in
    return {'attendance': mockAttendance.toJson()};
  }

  Future<Map<String, dynamic>> checkOut({String? note}) async {
    // Mock attendance data
    Attendance mockAttendance = Attendance(
      date: DateTime.now(), // Added date
      status: AttendanceStatus.present, // Added status
      checkInTime: DateTime.now().subtract(const Duration(hours: 8)),
      checkOutTime: DateTime.now(),
      notes: note,
      // id and userId are not part of the Attendance model constructor directly
    );

    // Simulate successful check-out
    return {'attendance': mockAttendance.toJson()};
  }

  // Added getCurrentAttendance, getAttendanceHistory, startBreak, endBreak for completeness, returning empty or default values
  // as they are called by the provider but their detailed mock logic isn't the immediate focus for the clock-in issue.

  Future<Map<String, dynamic>?> getCurrentAttendance(String userId) async {
    // Simulate a scenario where there might be an active session
    // For now, let's return a checked-in state for a mock user
    if (userId == 'mock_user_1') {
      Attendance mockAttendance = Attendance(
        date: DateTime.now(),
        status: AttendanceStatus.present,
        checkInTime: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      return mockAttendance.toJson(); // Provider expects the direct JSON here based on its usage
    }
    return null; // No active session
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(String userId) async {
    // Return a list of mock attendance records
    return [
      Attendance(
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: AttendanceStatus.present,
        checkInTime: DateTime.now().subtract(const Duration(days: 1, hours: 9)),
        checkOutTime: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      ).toJson(),
      Attendance(
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: AttendanceStatus.absent,
      ).toJson(),
    ];
  }

  Future<Map<String, dynamic>> startBreak(String userId) async {
    Attendance mockAttendance = Attendance(
      date: DateTime.now(),
      status: AttendanceStatus.present,
      checkInTime: DateTime.now().subtract(const Duration(hours: 1)),
      // Simulate break started, but not ended
    );
    // Add a mock break entry
    // This part needs to align with how breaks are structured in your actual Attendance model and backend
    // For now, returning the attendance state
    return {'attendance': mockAttendance.toJson()};
  }

  Future<Map<String, dynamic>> endBreak(String userId) async {
    Attendance mockAttendance = Attendance(
      date: DateTime.now(),
      status: AttendanceStatus.present,
      checkInTime: DateTime.now().subtract(const Duration(hours: 1)),
      breakDuration: const Duration(minutes: 15), // Simulate break ended
    );
    return {'attendance': mockAttendance.toJson()};
  }
}
