Future<String> requestWebNotificationPermission() async {
  // No-op for non-web platforms
  return 'denied';
}
