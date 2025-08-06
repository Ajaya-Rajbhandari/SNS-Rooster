import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Banner widget that shows network connectivity status at the top of the app
class NetworkStatusBanner extends StatefulWidget {
  final Widget child;
  final bool showWhenConnected;

  const NetworkStatusBanner({
    Key? key,
    required this.child,
    this.showWhenConnected = false,
  }) : super(key: key);

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner> {
  final ConnectivityService _connectivityService = ConnectivityService();
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  bool _isBackendReachable = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
  }

  Future<void> _initializeConnectivity() async {
    try {
      // Listen to connectivity changes
      _connectivityService.statusStream.listen((status) {
        setState(() {
          _currentStatus = status;
          _updateVisibility();
        });
      });

      // Get initial status
      final info = await _connectivityService.getConnectivityInfo();
      setState(() {
        _currentStatus = info.networkStatus;
        _isBackendReachable = info.backendReachable;
        _updateVisibility();
      });
    } catch (e) {
      // Handle initialization error silently
    }
  }

  void _updateVisibility() {
    final shouldShow = _shouldShowBanner();
    if (shouldShow != _isVisible) {
      setState(() {
        _isVisible = shouldShow;
      });
    }
  }

  bool _shouldShowBanner() {
    // Show when offline
    if (_currentStatus == ConnectivityStatus.none) {
      return true;
    }

    // Show when backend is unreachable
    if (!_isBackendReachable) {
      return true;
    }

    // Show when connected (if enabled)
    if (widget.showWhenConnected &&
        _currentStatus != ConnectivityStatus.unknown) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isVisible) _buildBanner(),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildBanner() {
    final theme = Theme.of(context);
    final isOffline = _currentStatus == ConnectivityStatus.none;
    final isServerUnavailable =
        !_isBackendReachable && _currentStatus != ConnectivityStatus.none;

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    if (isOffline) {
      backgroundColor = Colors.red;
      textColor = Colors.white;
      icon = Icons.wifi_off;
      message = 'No internet connection';
    } else if (isServerUnavailable) {
      backgroundColor = Colors.orange;
      textColor = Colors.white;
      icon = Icons.cloud_off;
      message = 'Server temporarily unavailable';
    } else {
      backgroundColor = Colors.green;
      textColor = Colors.white;
      icon = Icons.wifi;
      message = 'Connected';
    }

    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isOffline || isServerUnavailable)
            GestureDetector(
              onTap: _retryConnection,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Retry',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _retryConnection() async {
    try {
      await _connectivityService.checkBackendConnectivity();
      final info = await _connectivityService.getConnectivityInfo();
      setState(() {
        _isBackendReachable = info.backendReachable;
        _updateVisibility();
      });
    } catch (e) {
      // Handle retry error silently
    }
  }
}
