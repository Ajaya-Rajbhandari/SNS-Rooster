import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../utils/logger.dart';

/// Widget that displays network connectivity errors and provides retry options
class NetworkErrorWidget extends StatefulWidget {
  final String? customMessage;
  final VoidCallback? onRetry;
  final bool showRetryButton;
  final bool showDetails;
  final Widget? child;

  const NetworkErrorWidget({
    Key? key,
    this.customMessage,
    this.onRetry,
    this.showRetryButton = true,
    this.showDetails = false,
    this.child,
  }) : super(key: key);

  @override
  State<NetworkErrorWidget> createState() => _NetworkErrorWidgetState();
}

class _NetworkErrorWidgetState extends State<NetworkErrorWidget> {
  final ConnectivityService _connectivityService = ConnectivityService();
  ConnectivityInfo? _connectivityInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConnectivityInfo();
  }

  Future<void> _loadConnectivityInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final info = await _connectivityService.getConnectivityInfo();
      setState(() {
        _connectivityInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Failed to load connectivity info', StackTrace.current);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _retryConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _connectivityService.checkBackendConnectivity();
      await _loadConnectivityInfo();

      if (widget.onRetry != null) {
        widget.onRetry!();
      }
    } catch (e) {
      Logger.error('Retry connection failed', StackTrace.current);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return _buildLoadingWidget(theme);
    }

    if (_connectivityInfo == null) {
      return _buildErrorWidget(theme, 'Unable to check connection status');
    }

    if (_connectivityInfo!.canConnectToBackend) {
      return widget.child ?? const SizedBox.shrink();
    }

    return _buildNetworkErrorWidget(theme);
  }

  Widget _buildLoadingWidget(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Checking connection...',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkErrorWidget(ThemeData theme) {
    final errorMessage = widget.customMessage ?? _getErrorMessage();
    final isOffline =
        _connectivityInfo!.networkStatus == ConnectivityStatus.none;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error Icon
          Icon(
            isOffline ? Icons.wifi_off : Icons.cloud_off,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),

          // Error Title
          Text(
            isOffline ? 'No Internet Connection' : 'Server Unavailable',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Error Message
          Text(
            errorMessage,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Retry Button
          if (widget.showRetryButton)
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _retryConnection,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isLoading ? 'Checking...' : 'Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),

          // Details Section
          if (widget.showDetails && _connectivityInfo != null) ...[
            const SizedBox(height: 16),
            _buildDetailsSection(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Connection Error',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(ThemeData theme) {
    return ExpansionTile(
      title: Text(
        'Connection Details',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Network Status', _getNetworkStatusText()),
              _buildDetailRow('Backend Reachable',
                  _connectivityInfo!.backendReachable ? 'Yes' : 'No'),
              if (_connectivityInfo!.lastCheck != null)
                _buildDetailRow('Last Check',
                    _formatDateTime(_connectivityInfo!.lastCheck!)),
              if (_connectivityInfo!.lastBackendError.isNotEmpty)
                _buildDetailRow('Error', _connectivityInfo!.lastBackendError),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage() {
    if (_connectivityInfo == null) {
      return 'Unable to check connection status';
    }

    if (_connectivityInfo!.networkStatus == ConnectivityStatus.none) {
      return 'Please check your Wi-Fi or mobile data connection and try again.';
    }

    return _connectivityService.getUserFriendlyError();
  }

  String _getNetworkStatusText() {
    switch (_connectivityInfo?.networkStatus) {
      case ConnectivityStatus.wifi:
        return 'Wi-Fi';
      case ConnectivityStatus.mobile:
        return 'Mobile Data';
      case ConnectivityStatus.ethernet:
        return 'Ethernet';
      case ConnectivityStatus.vpn:
        return 'VPN';
      case ConnectivityStatus.bluetooth:
        return 'Bluetooth';
      case ConnectivityStatus.other:
        return 'Other';
      case ConnectivityStatus.none:
        return 'No Connection';
      case ConnectivityStatus.unknown:
        return 'Unknown';
      default:
        return 'Unknown';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
