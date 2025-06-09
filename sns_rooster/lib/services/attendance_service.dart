import 'mock_service.dart';

class AttendanceService {
  final MockAttendanceService _mockService = MockAttendanceService();

  Future<Map<String, dynamic>> checkIn(String userId, {String? notes}) async {
    if (useMock) {
      return _mockService.checkIn(userId, notes: notes);
    } else {
      // TODO: Implement real API call
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> checkOut(String userId, {String? notes}) async {
    if (useMock) {
      return _mockService.checkOut(userId, notes: notes);
    } else {
      // TODO: Implement real API call
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(String userId,
      {DateTime? startDate, DateTime? endDate}) async {
    if (useMock) {
      return _mockService.getAttendanceHistory(userId,
          startDate: startDate, endDate: endDate);
    } else {
      // TODO: Implement real API call
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>?> getCurrentAttendance(String userId) async {
    if (useMock) {
      return _mockService.getCurrentAttendance(userId);
    } else {
      // TODO: Implement real API call
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  Future<Map<String, dynamic>> getAttendanceSummary(String userId,
      {DateTime? startDate, DateTime? endDate}) async {
    if (useMock) {
      return _mockService.getAttendanceSummary(userId,
          startDate: startDate, endDate: endDate);
    } else {
      // TODO: Implement real API call
      throw UnimplementedError("Real API call not implemented.");
    }
  }

  // For future: integrate with backend API
}
