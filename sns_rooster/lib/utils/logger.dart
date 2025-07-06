import 'package:flutter/foundation.dart';

/// Use log(message) instead of print(message). Emits only in debug mode.
void log(Object? message) {
  if (kDebugMode) {
    debugPrint(message.toString());
  }
}

class Logger {
  static void info(Object? message) => log('[INFO] $message');
  static void warning(Object? message) => log('[WARNING] $message');
  static void error(Object? message) => log('[ERROR] $message');
}
