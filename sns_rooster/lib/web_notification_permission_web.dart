import 'dart:html' as html;

Future<String> requestWebNotificationPermission() async {
  return await html.Notification.requestPermission();
}
