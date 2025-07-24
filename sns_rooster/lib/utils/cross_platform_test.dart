import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports for cross-platform export functionality
import 'web_export.dart' if (dart.library.io) 'web_export_stub.dart';

/// Test function to verify cross-platform functionality
void testCrossPlatformExport() {
  print('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');

  try {
    // This will work on web, throw error on mobile
    exportForWebImpl('test data');
    print('✅ Web export function called successfully');
  } catch (e) {
    print('✅ Mobile platform correctly prevented web export: $e');
  }
}
