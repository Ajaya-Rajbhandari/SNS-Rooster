import 'mock_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sns_rooster/providers/auth_provider.dart';
import '../config/api_config.dart';

class AttendanceService {
  final MockAttendanceService _mockService = MockAttendanceService();
  final AuthProvider authProvider;

  AttendanceService(this.authProvider);

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
      try {
        final token = authProvider.token;
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer \$token',
        };
        String url = '\${ApiConfig.baseUrl}/attendance/user/\$userId';
        final queryParams = <String, String>{};
        if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
        if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
        if (queryParams.isNotEmpty) {
          url += '?' + Uri(queryParameters: queryParams).query;
        }
        final response = await http.get(Uri.parse(url), headers: headers);
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          return data.cast<Map<String, dynamic>>();
        } else {
          throw Exception('Failed to fetch attendance: \${response.statusCode} \${response.body}');
        }
      } catch (e) {
        throw Exception('Failed to fetch attendance: \$e');
      }
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
