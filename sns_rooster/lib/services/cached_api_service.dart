import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'cache_service.dart';
import '../config/api_config.dart';

/// Cached API Service for Flutter App
/// Wraps the existing API service with intelligent caching

class CachedApiService {
  final ApiService _apiService;
  final CacheService _cacheService;

  CachedApiService({
    ApiService? apiService,
    CacheService? cacheService,
  })  : _apiService = apiService ?? ApiService(baseUrl: ApiConfig.baseUrl),
        _cacheService = cacheService ?? CacheService();

  // Cache strategies for different endpoints
  static const Map<String, Duration> _cacheStrategies = {
    // Auth - short cache for security
    '/auth/validate': CacheService.shortTTL,
    '/auth/login': Duration.zero, // No cache for login

    // Company - medium cache
    '/companies': CacheService.mediumTTL,
    '/companies/features': CacheService.longTTL,

    // Attendance - short cache (frequently updated)
    '/attendance/today': CacheService.shortTTL,
    '/attendance/summary': CacheService.shortTTL,
    '/attendance/records': CacheService.mediumTTL,

    // Leave - medium cache
    '/leave/info': CacheService.mediumTTL,
    '/leave/types': CacheService.longTTL,
    '/leave/records': CacheService.mediumTTL,

    // Payroll - medium cache
    '/payroll/info': CacheService.mediumTTL,
    '/payroll/records': CacheService.mediumTTL,

    // Settings - long cache
    '/settings': CacheService.longTTL,
    '/admin/settings': CacheService.longTTL,

    // Notifications - short cache
    '/notifications': CacheService.shortTTL,

    // Analytics - medium cache
    '/analytics': CacheService.mediumTTL,
  };

  /// Get cache strategy for URL
  Duration _getCacheStrategy(String url) {
    for (final entry in _cacheStrategies.entries) {
      if (url.contains(entry.key)) {
        return entry.value;
      }
    }
    return Duration.zero; // No cache by default
  }

  /// Generate cache key
  String _generateCacheKey(String method, String url,
      [Map<String, dynamic>? data]) {
    final baseKey = '${method.toUpperCase()}:$url';

    if (data != null &&
        ['POST', 'PUT', 'PATCH'].contains(method.toUpperCase())) {
      final dataHash = jsonEncode(data).substring(0, 100); // Limit hash length
      return '$baseKey:$dataHash';
    }

    return baseKey;
  }

  /// GET with caching
  Future<ApiResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final cacheStrategy = _getCacheStrategy(url);
    final cacheKey = _generateCacheKey('GET', url);

    // Check cache first
    if (cacheStrategy > Duration.zero) {
      final cached = await _cacheService.get<ApiResponse>(cacheKey);
      if (cached != null) {
        if (kDebugMode) {
          print('Cache HIT: $url');
        }
        return cached;
      }
    }

    // Fetch from API
    if (kDebugMode) {
      print('Cache MISS: $url');
    }

    final response = await _apiService.get(url);

    // Store in cache
    if (cacheStrategy > Duration.zero && response.success) {
      await _cacheService.set(cacheKey, response, cacheStrategy);
    }

    return response;
  }

  /// POST without caching (mutations)
  Future<ApiResponse> post(
    String url, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    final result = await _apiService.post(url, data ?? {});

    // Invalidate related caches after mutations
    await _invalidateRelatedCaches(url, data);

    return result;
  }

  /// PUT without caching (mutations)
  Future<ApiResponse> put(
    String url, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    final result = await _apiService.put(url, data);

    // Invalidate related caches after mutations
    await _invalidateRelatedCaches(url, data);

    return result;
  }

  /// PATCH without caching (mutations)
  Future<ApiResponse> patch(
    String url, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    final result = await _apiService.patch(url, data ?? {});

    // Invalidate related caches after mutations
    await _invalidateRelatedCaches(url, data);

    return result;
  }

  /// DELETE without caching (mutations)
  Future<ApiResponse> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    final result = await _apiService.delete(url);

    // Invalidate related caches after mutations
    await _invalidateRelatedCaches(url);

    return result;
  }

  /// Upload without caching
  /// Note: Upload functionality not implemented in base ApiService
  /// Use direct HTTP client for file uploads
  Future<ApiResponse> upload(
    String url, {
    required Map<String, dynamic> formData,
    Map<String, String>? headers,
  }) async {
    // TODO: Implement upload functionality or use direct HTTP client
    throw UnimplementedError(
        'Upload method not implemented in base ApiService');
  }

  /// Invalidate related caches based on URL patterns
  Future<void> _invalidateRelatedCaches(String url,
      [Map<String, dynamic>? data]) async {
    // Invalidate based on URL patterns
    if (url.contains('/attendance')) {
      await _cacheService.delete(CacheKeys.todayAttendance);
      await _cacheService.delete(CacheKeys.attendanceSummary);
      if (kDebugMode) {
        print('Invalidated attendance cache');
      }
    }

    if (url.contains('/leave')) {
      await _cacheService.delete(CacheKeys.leaveInfo);
      if (kDebugMode) {
        print('Invalidated leave cache');
      }
    }

    if (url.contains('/payroll')) {
      await _cacheService.delete(CacheKeys.payrollInfo);
      if (kDebugMode) {
        print('Invalidated payroll cache');
      }
    }

    if (url.contains('/settings')) {
      await _cacheService.delete(CacheKeys.appSettings);
      await _cacheService.delete(CacheKeys.companySettings);
      if (kDebugMode) {
        print('Invalidated settings cache');
      }
    }

    if (url.contains('/companies')) {
      await _cacheService.delete(CacheKeys.companiesList);
      await _cacheService.delete(CacheKeys.companyFeatures);
      if (kDebugMode) {
        print('Invalidated companies cache');
      }
    }

    if (url.contains('/notifications')) {
      await _cacheService.delete(CacheKeys.notifications);
      if (kDebugMode) {
        print('Invalidated notifications cache');
      }
    }

    if (url.contains('/analytics')) {
      await _cacheService.invalidatePattern('analytics');
      if (kDebugMode) {
        print('Invalidated analytics cache');
      }
    }
  }

  /// Manual cache invalidation
  Future<void> invalidateCache(String pattern) async {
    await _cacheService.invalidatePattern(pattern);
    if (kDebugMode) {
      print('Manually invalidated cache pattern: $pattern');
    }
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    await _cacheService.clear();
    if (kDebugMode) {
      print('All caches cleared');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _cacheService.getStats();
  }

  /// Preload important data
  Future<void> preloadData() async {
    try {
      if (kDebugMode) {
        print('Preloading important data...');
      }

      // Preload company features
      await get('/companies/features');

      // Preload leave types
      await get('/leave/types');

      // Preload app settings
      await get('/settings');

      if (kDebugMode) {
        print('Data preloading completed');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Data preloading failed: $error');
      }
    }
  }

  /// Initialize cache service
  Future<void> initialize() async {
    await _cacheService.initialize();
    await preloadData();
  }
}

// Global cached API service instance
final cachedApiService = CachedApiService();
