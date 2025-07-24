import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feature_provider.dart';
import '../config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CompanyInfoWidget extends StatefulWidget {
  final String companyId;

  const CompanyInfoWidget({
    Key? key,
    required this.companyId,
  }) : super(key: key);

  @override
  State<CompanyInfoWidget> createState() => _CompanyInfoWidgetState();
}

class _CompanyInfoWidgetState extends State<CompanyInfoWidget> {
  @override
  void initState() {
    super.initState();
    // Load features when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final featureProvider =
          Provider.of<FeatureProvider>(context, listen: false);
      featureProvider.loadFeatures();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeatureProvider>(
      builder: (context, featureProvider, _) {
        if (featureProvider.isLoading) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (featureProvider.error != null) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Company Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading status: ${featureProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Company Status Card
            Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Company Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: () =>
                              featureProvider.forceRefreshFeatures(),
                          tooltip: 'Refresh data',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatusRow(
                      'Status',
                      featureProvider.companyInfo['status']
                              ?.toString()
                              .toUpperCase() ??
                          'UNKNOWN',
                      _getStatusColor(featureProvider.companyInfo['status']),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      'Plan',
                      featureProvider.subscriptionPlanName,
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      'Support',
                      featureProvider.subscriptionPlan['features']
                                  ?['prioritySupport'] ==
                              true
                          ? 'Priority'
                          : 'Standard',
                      featureProvider.subscriptionPlan['features']
                                  ?['prioritySupport'] ==
                              true
                          ? Colors.purple
                          : Colors.orange,
                    ),
                  ],
                ),
              ),
            ),

            // Usage Statistics Card
            Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: Colors.green[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Usage Statistics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildUsageRow(
                      'Employees',
                      '${featureProvider.employeeCount} / ${featureProvider.maxEmployees}',
                      featureProvider.employeeUsagePercentage.toDouble(),
                    ),
                    const SizedBox(height: 8),
                    _buildUsageRow(
                      'Storage',
                      '${featureProvider.storageUsage}GB / ${featureProvider.maxStorage}GB',
                      featureProvider.storageUsagePercentage.toDouble(),
                    ),
                    const SizedBox(height: 8),
                    _buildUsageRow(
                      'API Calls',
                      '${featureProvider.apiCallCount} / ${featureProvider.maxApiCalls}',
                      featureProvider.apiCallUsagePercentage.toDouble(),
                    ),
                  ],
                ),
              ),
            ),

            // Available Features Card
            Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.featured_play_list,
                          color: Colors.purple[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Available Features',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFeaturesGrid(featureProvider.features),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUsageRow(String label, String value, double percentage) {
    Color percentageColor = Colors.green;
    if (percentage > 80) {
      percentageColor = Colors.orange;
    }
    if (percentage > 95) {
      percentageColor = Colors.red;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 8),
            Text(
              '(${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: percentageColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFeaturesGrid(Map<String, dynamic>? features) {
    if (features == null || features.isEmpty) {
      return const Text(
        'No features available.',
        style: TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final List<Widget> featureWidgets = [];
    final Map<String, String> featureLabels = {
      'attendance': 'Attendance Tracking',
      'payroll': 'Payroll Management',
      'leaveManagement': 'Leave Management',
      'analytics': 'Analytics',
      'documentManagement': 'Document Management',
      'notifications': 'Notifications',
      'customBranding': 'Custom Branding',
      'apiAccess': 'API Access',
      'multiLocation': 'Multi-Location',
      'advancedReporting': 'Advanced Reporting',
      'timeTracking': 'Time Tracking',
      'expenseManagement': 'Expense Management',
      'performanceReviews': 'Performance Reviews',
      'trainingManagement': 'Training Management',
    };

    features.forEach((key, value) {
      if (value == true) {
        featureWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    featureLabels[key] ?? key,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    if (featureWidgets.isEmpty) {
      return const Text(
        'No features enabled.',
        style: TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: featureWidgets,
    );
  }
}
