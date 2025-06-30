import 'package:flutter/material.dart';
import '../services/dynamic_api_service.dart';

/// Widget that displays current network status and detected IP address
class NetworkStatusWidget extends StatefulWidget {
  const NetworkStatusWidget({Key? key}) : super(key: key);

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  bool _isLoading = true;
  bool _isConnected = false;
  String _detectedIP = '';
  String _baseUrl = '';
  String _error = '';

  @override
  void initState() {
    super(initState());
    _loadNetworkInfo();
  }

  Future<void> _loadNetworkInfo() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final service = DynamicApiService.instance;

      // Get network information
      final networkInfo = await service.getNetworkInfo();

      setState(() {
        _detectedIP = networkInfo['detectedLocalIP'] ?? 'Unknown';
        _baseUrl = networkInfo['serviceBaseUrl'] ?? 'Unknown';
        _isConnected = networkInfo['connectivityTest'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.network_check,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Network Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Text('Detecting network...')
            else if (_error.isNotEmpty)
              Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Detected IP', _detectedIP),
                  const SizedBox(height: 4),
                  _buildInfoRow('Base URL', _baseUrl),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    'Connection',
                    _isConnected ? 'Connected ✅' : 'Disconnected ❌',
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loadNetworkInfo,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            DynamicApiService.instance.clearCache();
                            _loadNetworkInfo();
                          },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear Cache'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
