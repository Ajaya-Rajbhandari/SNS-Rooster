import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'package:sns_rooster/providers/auth_provider.dart';

class NotificationService {
  final AuthProvider authProvider;
  NotificationService(this.authProvider);

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/notifications/simple'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authProvider.token}',
        'x-company-id': authProvider.user?['companyId'] ?? '',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['notifications']);
    } else {
      throw Exception('Failed to fetch notifications');
    }
  }

  Future<int> getUnreadCount() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/notifications/simple/unread-count'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authProvider.token}',
        'x-company-id': authProvider.user?['companyId'] ?? '',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    } else {
      throw Exception('Failed to fetch unread count');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/notifications/$notificationId/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authProvider.token}',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }
}
