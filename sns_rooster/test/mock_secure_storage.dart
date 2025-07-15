import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {
  final Map<String, String?> _storage = {};

  @override
  Future<void> write({required String key, required String? value, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    return _storage[key];
  }

  @override
  Future<void> delete({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    _storage.clear();
  }

  @override
  Future<Map<String, String>> readAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    final result = <String, String>{};
    _storage.forEach((k, v) {
      if (v != null) result[k] = v;
    });
    return result;
  }
}

void setupMockSecureStorage() {
  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  FlutterSecureStorage.setMockInitialValues({});
}
