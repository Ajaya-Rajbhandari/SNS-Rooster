import 'package:flutter/foundation.dart';

/// Use log(message) instead of print(message). Emits only in debug mode.
void log(Object? message) {
  if (kDebugMode) {
    debugPrint(message.toString());
  }
}
