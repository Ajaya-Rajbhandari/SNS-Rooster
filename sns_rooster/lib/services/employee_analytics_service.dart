import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class EmployeeAnalyticsService {
  static Future<Map<String, dynamic>> fetchLateCheckins(
      String userId, String token) async {
    final url =
        '${ApiConfig.baseUrl}/attendance/analytics/late-checkins/$userId';
    final response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load late check-ins');
    }
  }

  static Future<Map<String, dynamic>> fetchAvgCheckout(
      String userId, String token) async {
    final url =
        '${ApiConfig.baseUrl}/attendance/analytics/avg-checkout/$userId';
    final response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load average check-out time');
    }
  }

  static Future<List<dynamic>> fetchRecentActivity(
      String userId, String token) async {
    final url =
        '${ApiConfig.baseUrl}/attendance/analytics/recent-activity/$userId';
    final response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      return json.decode(response.body)['recentActivity'];
    } else {
      throw Exception('Failed to load recent activity');
    }
  }
}
