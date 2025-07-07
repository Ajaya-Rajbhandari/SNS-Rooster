// Web-specific implementation
import 'dart:html' as html;

String getHashFragment() {
  try {
    final hash = html.window.location.hash;
    return hash.isNotEmpty ? hash.substring(1) : '';
  } catch (e) {
    print('Error getting hash fragment: $e');
    return '';
  }
}
