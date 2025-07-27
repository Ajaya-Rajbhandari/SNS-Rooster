import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Cache Service for Flutter App
/// Provides intelligent caching to reduce API calls and improve performance

class CacheItem<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;
  final String key;

  CacheItem({
    required this.data,
    required this.timestamp,
    required this.ttl,
    required this.key,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl.inMilliseconds,
      'key': key,
    };
  }

  factory CacheItem.fromJson(
      Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return CacheItem<T>(
      data: fromJson(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      ttl: Duration(milliseconds: json['ttl']),
      key: json['key'],
    );
  }
}

class CacheService {
  static const String _cachePrefix = 'app_cache_';
  static const String _statsKey = 'cache_stats';

  // Cache configurations
  static const Duration shortTTL = Duration(seconds: 30);
  static const Duration mediumTTL = Duration(minutes: 5);
  static const Duration longTTL = Duration(minutes: 30);
  static const Duration staticTTL = Duration(hours: 24);

  // Cache statistics
  int _hits = 0;
  int _misses = 0;
  int _sets = 0;

  /// Set an item in cache
  Future<void> set<T>(
    String key,
    T data,
    Duration ttl, {
    T Function(dynamic)? fromJson,
    dynamic Function(T)? toJson,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(key);

      final item = CacheItem<T>(
        data: data,
        timestamp: DateTime.now(),
        ttl: ttl,
        key: key,
      );

      String jsonString;
      if (toJson != null) {
        jsonString = jsonEncode({
          'data': toJson(data),
          'timestamp': item.timestamp.toIso8601String(),
          'ttl': item.ttl.inMilliseconds,
          'key': item.key,
        });
      } else {
        jsonString = jsonEncode(item.toJson());
      }

      await prefs.setString(cacheKey, jsonString);
      _sets++;
      _saveStats();

      if (kDebugMode) {
        print('Cache SET: $key (TTL: ${ttl.inSeconds}s)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cache SET error: $e');
      }
    }
  }

  /// Get an item from cache
  Future<T?> get<T>(
    String key, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(key);

      final jsonString = prefs.getString(cacheKey);
      if (jsonString == null) {
        _misses++;
        _saveStats();
        if (kDebugMode) {
          print('Cache MISS: $key');
        }
        return null;
      }

      final json = jsonDecode(jsonString);
      final item = CacheItem<T>.fromJson(json, fromJson ?? (data) => data as T);

      if (item.isExpired) {
        await prefs.remove(cacheKey);
        _misses++;
        _saveStats();
        if (kDebugMode) {
          print('Cache EXPIRED: $key');
        }
        return null;
      }

      _hits++;
      _saveStats();
      if (kDebugMode) {
        print('Cache HIT: $key');
      }
      return item.data;
    } catch (e) {
      if (kDebugMode) {
        print('Cache GET error: $e');
      }
      _misses++;
      _saveStats();
      return null;
    }
  }

  /// Check if a key exists and is not expired
  Future<bool> has(String key) async {
    final data = await get(key);
    return data != null;
  }

  /// Remove an item from cache
  Future<bool> delete(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(key);
      final removed = await prefs.remove(cacheKey);

      if (kDebugMode) {
        print('Cache DELETE: $key');
      }
      return removed;
    } catch (e) {
      if (kDebugMode) {
        print('Cache DELETE error: $e');
      }
      return false;
    }
  }

  /// Clear all cache
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }

      if (kDebugMode) {
        print('Cache CLEAR: All cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cache CLEAR error: $e');
      }
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final total = _hits + _misses;
    final hitRate = total > 0 ? (_hits / total * 100).round() : 0;

    return {
      'hits': _hits,
      'misses': _misses,
      'sets': _sets,
      'total': total,
      'hitRate': hitRate,
    };
  }

  /// Load cache statistics
  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_statsKey);

      if (statsJson != null) {
        final stats = jsonDecode(statsJson);
        _hits = stats['hits'] ?? 0;
        _misses = stats['misses'] ?? 0;
        _sets = stats['sets'] ?? 0;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cache stats load error: $e');
      }
    }
  }

  /// Save cache statistics
  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stats = getStats();
      await prefs.setString(_statsKey, jsonEncode(stats));
    } catch (e) {
      if (kDebugMode) {
        print('Cache stats save error: $e');
      }
    }
  }

  /// Get cache key with prefix
  String _getCacheKey(String key) {
    return '$_cachePrefix$key';
  }

  /// Initialize cache service
  Future<void> initialize() async {
    await _loadStats();
    if (kDebugMode) {
      print('CacheService initialized');
    }
  }

  /// Preload important data
  Future<void> preloadData() async {
    if (kDebugMode) {
      print('Preloading important data...');
    }

    // This will be implemented by specific services
    // that need to preload data
  }

  /// Invalidate cache by pattern
  Future<void> invalidatePattern(String pattern) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int invalidated = 0;
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) && key.contains(pattern)) {
          await prefs.remove(key);
          invalidated++;
        }
      }

      if (kDebugMode) {
        print(
            'Cache INVALIDATE: $invalidated items matching pattern "$pattern"');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cache INVALIDATE error: $e');
      }
    }
  }
}

// Global cache service instance
final cacheService = CacheService();

// Cache key generators
class CacheKeys {
  // Auth related
  static String userProfile(String userId) => 'user:profile:$userId';
  static const String authToken = 'auth:token';
  static const String userData = 'auth:user';

  // Company related
  static const String companyFeatures = 'company:features';
  static String companyDetails(String companyId) =>
      'company:details:$companyId';
  static const String companiesList = 'companies:list';

  // Attendance related
  static const String todayAttendance = 'attendance:today';
  static const String attendanceSummary = 'attendance:summary';
  static String attendanceRecords(String date) => 'attendance:records:$date';

  // Leave related
  static const String leaveInfo = 'leave:info';
  static const String leaveTypes = 'leave:types';
  static String leaveRecords(String year) => 'leave:records:$year';

  // Payroll related
  static const String payrollInfo = 'payroll:info';
  static String payrollRecords(String month) => 'payroll:records:$month';

  // Settings related
  static const String appSettings = 'settings:app';
  static const String companySettings = 'settings:company';

  // Notifications
  static const String notifications = 'notifications:list';

  // Analytics
  static String analytics(String period) => 'analytics:$period';
}
