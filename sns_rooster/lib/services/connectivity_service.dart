import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/logger.dart';

/// Comprehensive connectivity service that monitors network status
/// and provides detailed error information to users
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  Timer? _healthCheckTimer;
  bool _isBackendReachable = false;
  String _lastBackendError = '';
  DateTime? _lastBackendCheck;

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Whether backend is reachable
  bool get isBackendReachable => _isBackendReachable;

  /// Last backend error message
  String get lastBackendError => _lastBackendError;

  /// Last backend check time
  DateTime? get lastBackendCheck => _lastBackendCheck;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Listen to connectivity changes
      _connectivity.onConnectivityChanged
          .listen((List<ConnectivityResult> results) {
        if (results.isNotEmpty) {
          _handleConnectivityChange(results.first);
        }
      });

      // Get initial status
      final results = await _connectivity.checkConnectivity();
      if (results.isNotEmpty) {
        await _handleConnectivityChange(results.first);
      }

      // Start periodic backend health checks
      _startHealthCheckTimer();

      Logger.info('ConnectivityService: Initialized successfully');
    } catch (e, stackTrace) {
      Logger.error('ConnectivityService: Initialization failed', stackTrace);
    }
  }

  /// Handle connectivity changes
  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    ConnectivityStatus newStatus;

    switch (result) {
      case ConnectivityResult.wifi:
        newStatus = ConnectivityStatus.wifi;
        break;
      case ConnectivityResult.mobile:
        newStatus = ConnectivityStatus.mobile;
        break;
      case ConnectivityResult.ethernet:
        newStatus = ConnectivityStatus.ethernet;
        break;
      case ConnectivityResult.vpn:
        newStatus = ConnectivityStatus.vpn;
        break;
      case ConnectivityResult.bluetooth:
        newStatus = ConnectivityStatus.bluetooth;
        break;
      case ConnectivityResult.other:
        newStatus = ConnectivityStatus.other;
        break;
      case ConnectivityResult.none:
        newStatus = ConnectivityStatus.none;
        break;
      default:
        newStatus = ConnectivityStatus.unknown;
    }

    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);

      Logger.info('ConnectivityService: Status changed to $_currentStatus');

      // Check backend connectivity when network becomes available
      if (_currentStatus != ConnectivityStatus.none &&
          _currentStatus != ConnectivityStatus.unknown) {
        await checkBackendConnectivity();
      } else {
        _isBackendReachable = false;
        _lastBackendError = 'No internet connection available';
      }
    }
  }

  /// Check if backend is reachable
  Future<bool> checkBackendConnectivity() async {
    try {
      _lastBackendCheck = DateTime.now();

      // Try to reach the health endpoint
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl.replaceAll('/api', '')}/health'),
        headers: {'User-Agent': 'SNS-Rooster-Connectivity-Check'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _isBackendReachable = true;
        _lastBackendError = '';
        Logger.info('ConnectivityService: Backend is reachable');
        return true;
      } else {
        _isBackendReachable = false;
        _lastBackendError =
            'Backend server returned status ${response.statusCode}';
        Logger.warning(
            'ConnectivityService: Backend returned status ${response.statusCode}');
        return false;
      }
    } on SocketException catch (e) {
      _isBackendReachable = false;
      _lastBackendError = _getSocketExceptionMessage(e);
      Logger.warning(
          'ConnectivityService: Socket exception - $_lastBackendError');
      return false;
    } on TimeoutException catch (e) {
      _isBackendReachable = false;
      _lastBackendError = 'Backend server is not responding (timeout)';
      Logger.warning(
          'ConnectivityService: Timeout exception - $_lastBackendError');
      return false;
    } catch (e) {
      _isBackendReachable = false;
      _lastBackendError =
          'Unable to connect to backend server: ${e.toString()}';
      Logger.error(
          'ConnectivityService: Unexpected error during connectivity check',
          StackTrace.current);
      return false;
    }
  }

  /// Get user-friendly message for socket exceptions
  String _getSocketExceptionMessage(SocketException e) {
    if (e.message.contains('Failed host lookup')) {
      return 'Cannot resolve server address. Please check your internet connection.';
    } else if (e.message.contains('Connection refused')) {
      return 'Backend server is currently unavailable. Please try again later.';
    } else if (e.message.contains('Network is unreachable')) {
      return 'Network is unreachable. Please check your internet connection.';
    } else if (e.message.contains('No route to host')) {
      return 'Cannot reach the server. Please check your internet connection.';
    } else {
      return 'Network connection error: ${e.message}';
    }
  }

  /// Start periodic health check timer
  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_currentStatus != ConnectivityStatus.none) {
        checkBackendConnectivity();
      }
    });
  }

  /// Get detailed connectivity information
  Future<ConnectivityInfo> getConnectivityInfo() async {
    final backendReachable = await checkBackendConnectivity();

    return ConnectivityInfo(
      networkStatus: _currentStatus,
      backendReachable: backendReachable,
      lastBackendError: _lastBackendError,
      lastCheck: _lastBackendCheck,
      isOnline: _currentStatus != ConnectivityStatus.none,
    );
  }

  /// Get user-friendly error message
  String getUserFriendlyError() {
    if (_currentStatus == ConnectivityStatus.none) {
      return 'No internet connection available. Please check your Wi-Fi or mobile data.';
    }

    if (!_isBackendReachable) {
      if (_lastBackendError.contains('timeout')) {
        return 'Server is taking too long to respond. Please try again in a moment.';
      } else if (_lastBackendError.contains('unavailable')) {
        return 'Our servers are temporarily unavailable. Please try again later.';
      } else if (_lastBackendError.contains('resolve')) {
        return 'Cannot connect to our servers. Please check your internet connection.';
      } else {
        return 'Unable to connect to our servers. Please try again later.';
      }
    }

    return 'Connection is working properly.';
  }

  /// Check if app can function normally
  bool get canFunctionNormally {
    return _currentStatus != ConnectivityStatus.none && _isBackendReachable;
  }

  /// Dispose resources
  void dispose() {
    _healthCheckTimer?.cancel();
    _statusController.close();
  }
}

/// Connectivity status enum
enum ConnectivityStatus {
  wifi,
  mobile,
  ethernet,
  vpn,
  bluetooth,
  other,
  none,
  unknown,
}

/// Detailed connectivity information
class ConnectivityInfo {
  final ConnectivityStatus networkStatus;
  final bool backendReachable;
  final String lastBackendError;
  final DateTime? lastCheck;
  final bool isOnline;

  ConnectivityInfo({
    required this.networkStatus,
    required this.backendReachable,
    required this.lastBackendError,
    this.lastCheck,
    required this.isOnline,
  });

  bool get canConnectToBackend => isOnline && backendReachable;

  String get statusDescription {
    if (!isOnline) return 'Offline';
    if (!backendReachable) return 'Online but server unavailable';
    return 'Fully connected';
  }
}
