import 'package:sns_rooster/services/api_service.dart';

class EmployeeAnalyticsService {
  final ApiService apiService;
  EmployeeAnalyticsService(this.apiService);

  Future<Map<String, dynamic>> fetchLateCheckins(String userId) async {
    final response = await apiService.get(
        '/attendance/analytics/late-checkins/$userId');
    if (response.success && response.data is Map<String, dynamic>) {
      return response.data;
    } else {
      throw Exception('Failed to load late check-ins: \\${response.message}');
    }
  }

  Future<Map<String, dynamic>> fetchAvgCheckout(String userId) async {
    final response = await apiService.get(
        '/attendance/analytics/avg-checkout/$userId');
    if (response.success && response.data is Map<String, dynamic>) {
      return response.data;
    } else {
      throw Exception('Failed to load average check-out time: \\${response.message}');
    }
  }

  Future<List<dynamic>> fetchRecentActivity(String userId) async {
    final response = await apiService.get(
        '/attendance/analytics/recent-activity/$userId');
    if (response.success &&
        response.data is Map<String, dynamic> &&
        response.data['recentActivity'] != null) {
      return List<dynamic>.from(response.data['recentActivity']);
    } else {
      throw Exception('Failed to load recent activity: \\${response.message}');
    }
  }
}
