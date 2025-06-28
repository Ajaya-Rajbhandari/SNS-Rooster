import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'auth_provider.dart';

class AdminAttendanceProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  AdminAttendanceProvider(this.authProvider);

  List<Map<String, dynamic>> attendanceRecords = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchAttendance(
      {String? start, String? end, String? employeeId}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final params = <String, String>{};
      if (start != null) params['start'] = start;
      if (end != null) params['end'] = end;
      if (employeeId != null) params['employeeId'] = employeeId;
      final uri = Uri.parse('${ApiConfig.baseUrl}/attendance')
          .replace(queryParameters: params);
      final token = authProvider.token;
      final response = await http.get(uri,
          headers: token != null ? {'Authorization': 'Bearer $token'} : {});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        attendanceRecords =
            List<Map<String, dynamic>>.from(data['attendance'] ?? []);
      } else {
        error = 'Failed to fetch attendance: ${response.statusCode}';
      }
    } catch (e) {
      error = 'Error: $e';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> editAttendance(
      String attendanceId, Map<String, dynamic> update) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/attendance/$attendanceId');
      final token = authProvider.token;
      final response = await http.put(uri, body: json.encode(update), headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> exportAttendance(
      {String? start, String? end, String? employeeId}) async {
    // Implement as needed for CSV download
    return true;
  }
}
