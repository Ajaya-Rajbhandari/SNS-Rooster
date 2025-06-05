import 'package:sns_rooster/models/leave_request.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LeaveRequestLocalStorage {
  static const String _leaveRequestsKey = 'leave_requests';

  static Future<void> saveLeaveRequests(List<LeaveRequest> leaveRequests) async {
    final prefs = await SharedPreferences.getInstance();
    final leaveRequestsJson = jsonEncode(leaveRequests.map((e) => e.toJson()).toList());
    await prefs.setString(_leaveRequestsKey, leaveRequestsJson);
  }

  static Future<List<LeaveRequest>> getLeaveRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final leaveRequestsJson = prefs.getString(_leaveRequestsKey);
    if (leaveRequestsJson == null) return [];
    final List<dynamic> leaveRequestsList = jsonDecode(leaveRequestsJson);
    return leaveRequestsList.map((e) => LeaveRequest.fromJson(e)).toList();
  }

  static Future<void> clearLeaveRequests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_leaveRequestsKey);
  }
}