// Conditional import for platform-specific hash fragment handling
export 'hash_fragment_web.dart' if (dart.library.io) 'hash_fragment_io.dart';
