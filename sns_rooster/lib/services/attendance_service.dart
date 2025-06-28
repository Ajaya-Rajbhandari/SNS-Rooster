import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sns_rooster/providers/auth_provider.dart';
import '../config/api_config.dart';

class AttendanceService {
  final AuthProvider authProvider;

  AttendanceService(this.authProvider);

  Future<Map<String, dynamic>> checkIn(String userId, {String? notes}) async {
    final token = authProvider.token;
    if (token == null) {
      throw Exception('No valid token found');
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final url = '${ApiConfig.baseUrl}/attendance/check-in';
    final body = json.encode({
      'userId': userId,
      if (notes != null) 'notes': notes,
    });
    print('DEBUG: Sending userId in checkIn API call: $userId');
    print('DEBUG: Authorization header for API call: Bearer $token');
    final response =
        await http.post(Uri.parse(url), headers: headers, body: body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to check in: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map<String, dynamic>> checkOut(String userId, {String? notes}) async {
    final token = authProvider.token;
    if (token == null) {
      throw Exception('No valid token found');
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final url = '${ApiConfig.baseUrl}/attendance/check-out';
    final body = json.encode({
      'userId': userId,
      if (notes != null) 'notes': notes,
    });
    print('DEBUG: Sending userId in checkOut API call: $userId');
    print('DEBUG: Authorization header for API call: Bearer $token');
    final response =
        await http.patch(Uri.parse(url), headers: headers, body: body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to check out: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(String userId,
      {DateTime? startDate, DateTime? endDate}) async {
    final token = authProvider.token;
    if (token == null) {
      throw Exception('No valid token found');
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    String url = '${ApiConfig.baseUrl}/attendance/my-attendance';
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
    if (queryParams.isNotEmpty) {
      url += '?${Uri(queryParameters: queryParams).query}';
    }

    print('DEBUG: Calling attendance API: $url');
    final response = await http.get(Uri.parse(url), headers: headers);
    print('DEBUG: Attendance API response status: ${response.statusCode}');
    print('DEBUG: Attendance API response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> attendanceList = data['attendance'] ?? [];
      print('DEBUG: Parsed attendance list length: ${attendanceList.length}');
      if (attendanceList.isNotEmpty) {
        print('DEBUG: First attendance record: ${attendanceList.first}');
      }
      return attendanceList.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
          'Failed to fetch attendance: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map<String, dynamic>?> getCurrentAttendance(String userId) async {
    final token = authProvider.token;
    if (token == null) {
      throw Exception('No valid token found');
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final url = '${ApiConfig.baseUrl}/attendance/status/$userId';
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception(
          'Failed to fetch current attendance: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getAttendanceSummary(String userId,
      {DateTime? startDate, DateTime? endDate}) async {
    final token = authProvider.token;
    if (token == null) {
      throw Exception('No valid token found');
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    String url = '${ApiConfig.baseUrl}/attendance/summary/$userId';
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end'] = endDate.toIso8601String();
    if (queryParams.isNotEmpty) {
      url += '?${Uri(queryParameters: queryParams).query}';
    }
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to fetch attendance summary: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> startBreakWithType(
      String userId, Map<String, dynamic> breakType) async {
    final token = authProvider.token;
    if (token == null) {
      throw Exception('No valid token found');
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final url = '${ApiConfig.baseUrl}/attendance/start-break';
    final body = json.encode({
      'userId': userId,
      'breakTypeId': breakType['_id'],
    });
    print(
        'DEBUG: Sending break start API call for userId: $userId with breakTypeId: ${breakType['_id']}');
    final response =
        await http.post(Uri.parse(url), headers: headers, body: body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Failed to start break: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> endBreak(String userId) async {
    final token = authProvider.token;
    if (token == null) {
      throw Exception('No valid token found');
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final url = '${ApiConfig.baseUrl}/attendance/end-break';
    final body = json.encode({
      'userId': userId,
    });
    print('DEBUG: Sending break end API call for userId: $userId');
    final response =
        await http.patch(Uri.parse(url), headers: headers, body: body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Failed to end break: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> getAttendanceStatus(String userId) async {
    final token = authProvider.token;
    if (token == null) {
      throw Exception('No valid token found');
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final url = '${ApiConfig.baseUrl}/attendance/status/$userId';
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      print(
          'DEBUG: Raw response body from getAttendanceStatus: ${response.body}');
      final Map<String, dynamic> data = json.decode(response.body);
      return data['status'] as String;
    } else if (response.statusCode == 404) {
      return 'No current attendance';
    } else {
      throw Exception(
          'Failed to fetch attendance status: ${response.statusCode} ${response.body}');
    }
  }

  // New method to get both status and attendance data
  Future<Map<String, dynamic>> getAttendanceStatusWithData(
      String userId) async {
    final token = authProvider.token;
    if (token == null) {
      throw Exception('No valid token found');
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final url = '${ApiConfig.baseUrl}/attendance/status/$userId';
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      print(
          'DEBUG: Raw response body from getAttendanceStatusWithData: ${response.body}');
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else if (response.statusCode == 404) {
      return {'status': 'No current attendance', 'attendance': null};
    } else {
      throw Exception(
          'Failed to fetch attendance status: ${response.statusCode} ${response.body}');
    }
  }
}
