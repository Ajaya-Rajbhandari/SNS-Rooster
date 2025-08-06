import 'package:flutter/material.dart';
import '../../widgets/network_error_widget.dart';
import '../../widgets/network_status_banner.dart';

/// Example screen showing how to implement network error handling
class ExampleNetworkErrorScreen extends StatefulWidget {
  const ExampleNetworkErrorScreen({Key? key}) : super(key: key);

  @override
  State<ExampleNetworkErrorScreen> createState() =>
      _ExampleNetworkErrorScreenState();
}

class _ExampleNetworkErrorScreenState extends State<ExampleNetworkErrorScreen> {
  bool _isLoading = false;
  String? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _data = 'Data loaded successfully!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _data = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Error Example'),
      ),
      body: NetworkStatusBanner(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading data...'),
          ],
        ),
      );
    }

    if (_data == null) {
      return NetworkErrorWidget(
        customMessage:
            'Failed to load data. Please check your connection and try again.',
        onRetry: _loadData,
        showRetryButton: true,
        showDetails: true,
        child: _buildContent(),
      );
    }

    return _buildContent();
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Network Error Handling',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This screen demonstrates how to handle network errors:',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem('Network Status Banner',
                      'Shows at the top when offline or server is down'),
                  _buildFeatureItem(
                      'Network Error Widget', 'Displays when API calls fail'),
                  _buildFeatureItem(
                      'Automatic Retry', 'Users can retry failed operations'),
                  _buildFeatureItem('Detailed Error Info',
                      'Shows technical details for debugging'),
                  const SizedBox(height: 16),
                  if (_data != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _data!,
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to Use',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildCodeExample(
                    'NetworkStatusBanner',
                    'Wrap your main content to show connectivity status',
                  ),
                  _buildCodeExample(
                    'NetworkErrorWidget',
                    'Use when API calls fail to show user-friendly errors',
                  ),
                  _buildCodeExample(
                    'ConnectivityService',
                    'Monitor network status and backend connectivity',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeExample(String widget, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
