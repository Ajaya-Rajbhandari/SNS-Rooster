// lib/services/mock_attendance_service.dart

import 'package:sns_rooster/models/attendance.dart';

class MockAttendanceService {
  Future<Attendance> checkIn({String? note}) async {
    // Mock attendance data
    Attendance mockAttendance = Attendance(
      id: 'attendance_id',
      userId: 'user_id',
      checkIn: DateTime.now(),
      note: note,
    );

    // Simulate successful check-in
    return mockAttendance;
  }

  Future<Attendance> checkOut({String? note}) async {
    // Mock attendance data
    Attendance mockAttendance = Attendance(
      id: 'attendance_id',
      userId: 'user_id',
      checkIn: DateTime.now().subtract(Duration(hours: 8)),
      checkOut: DateTime.now(),
      note: note,
    );

    // Simulate successful check-out
    return mockAttendance;
  }
}
