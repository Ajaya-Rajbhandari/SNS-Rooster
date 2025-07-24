import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feature_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/feature_dashboard.dart';
import '../../widgets/feature_guard.dart';

class FeatureSettingsScreen extends StatefulWidget {
  const FeatureSettingsScreen({Key? key}) : super(key: key);

  @override
  State<FeatureSettingsScreen> createState() => _FeatureSettingsScreenState();
}

class _FeatureSettingsScreenState extends State<FeatureSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load features when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeatureProvider>().loadFeatures();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<FeatureProvider>().refreshFeatures();
            },
          ),
        ],
      ),
      body: Consumer<FeatureProvider>(
        builder: (context, featureProvider, _) {
          if (featureProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (featureProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade600, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    featureProvider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => featureProvider.refreshFeatures(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Feature Dashboard
                const FeatureDashboard(),
                const SizedBox(height: 24),

                // Feature Examples
                _buildFeatureExamples(context, featureProvider),
                const SizedBox(height: 24),

                // Usage Examples
                _buildUsageExamples(context, featureProvider),
                const SizedBox(height: 24),

                // Plan Information
                _buildPlanInformation(context, featureProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureExamples(
      BuildContext context, FeatureProvider featureProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Feature Examples',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Analytics Feature Example
            FeatureGuard(
              feature: 'analytics',
              showUpgradePrompt: true,
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            'Analytics Dashboard',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This feature is available in your current plan! You can access advanced analytics and reporting.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Custom Branding Feature Example
            FeatureGuard(
              feature: 'customBranding',
              showUpgradePrompt: true,
              child: Card(
                color: Colors.purple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.palette, color: Colors.purple.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            'Custom Branding',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This feature is available in your current plan! You can customize the app with your company branding.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // API Access Feature Example
            FeatureGuard(
              feature: 'apiAccess',
              showUpgradePrompt: true,
              child: Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.code, color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            'API Access',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This feature is available in your current plan! You can integrate with external systems via API.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageExamples(
      BuildContext context, FeatureProvider featureProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usage Examples',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Employee Limit Example
            UsageGuard(
              limitKey: 'maxEmployees',
              showWarning: true,
              child: Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            'Add New Employee',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You can add new employees within your current limit.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Storage Limit Example
            UsageGuard(
              limitKey: 'maxStorageGB',
              showWarning: true,
              child: Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.storage, color: Colors.orange.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            'Upload Documents',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You can upload documents within your storage limit.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanInformation(
      BuildContext context, FeatureProvider featureProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Current Plan
            ListTile(
              leading: Icon(Icons.card_membership, color: Colors.blue.shade600),
              title: const Text('Current Plan'),
              subtitle: Text(featureProvider.subscriptionPlanName),
              trailing: featureProvider.subscriptionPlanPrice != null
                  ? Text(
                      '\$${featureProvider.subscriptionPlanPrice!['monthly']}/month',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                  : null,
            ),

            // Plan Features
            const SizedBox(height: 16),
            const Text(
              'Plan Features:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Show available features
            ...featureProvider.getAvailableFeatures().map((feature) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade600, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _getFeatureDisplayName(feature),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }).toList(),

            // Show unavailable features
            ...featureProvider.features.entries
                .where((entry) => entry.value == false)
                .map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.grey.shade400, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _getFeatureDisplayName(entry.key),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 16),

            // Upgrade Button
            if (!featureProvider.isEnterprisePlan)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Contact your administrator to upgrade your plan'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Upgrade Plan'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getFeatureDisplayName(String feature) {
    switch (feature) {
      case 'attendance':
        return 'Attendance Tracking';
      case 'payroll':
        return 'Payroll Management';
      case 'leaveManagement':
        return 'Leave Management';
      case 'analytics':
        return 'Analytics & Reports';
      case 'documentManagement':
        return 'Document Management';
      case 'notifications':
        return 'Notifications';
      case 'customBranding':
        return 'Custom Branding';
      case 'apiAccess':
        return 'API Access';
      case 'multiLocation':
        return 'Multi-Location Support';
      case 'advancedReporting':
        return 'Advanced Reporting';
      case 'timeTracking':
        return 'Time Tracking';
      case 'expenseManagement':
        return 'Expense Management';
      case 'performanceReviews':
        return 'Performance Reviews';
      case 'trainingManagement':
        return 'Training Management';
      default:
        return feature;
    }
  }
}
