import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feature_provider.dart';
import 'feature_guard.dart';

class FeatureDashboard extends StatelessWidget {
  const FeatureDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FeatureProvider>(
      builder: (context, featureProvider, _) {
        if (featureProvider.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (featureProvider.error != null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade600, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Error Loading Features',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    featureProvider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => featureProvider.refreshFeatures(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company and Plan Info
            _buildCompanyInfo(context, featureProvider),
            const SizedBox(height: 16),

            // Usage Indicators
            _buildUsageSection(context, featureProvider),
            const SizedBox(height: 16),

            // Feature Status
            _buildFeatureSection(context, featureProvider),
            const SizedBox(height: 16),

            // Warnings and Alerts
            _buildWarningsSection(context, featureProvider),
          ],
        );
      },
    );
  }

  Widget _buildCompanyInfo(
      BuildContext context, FeatureProvider featureProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business,
                  color: featureProvider.isCompanyActive
                      ? Colors.green
                      : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        featureProvider.companyName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${featureProvider.companyDomain}.${featureProvider.companySubdomain}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: featureProvider.isCompanyActive
                        ? Colors.green.shade100
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    featureProvider.isCompanyActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: featureProvider.isCompanyActive
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.card_membership,
                    color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Current Plan:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  featureProvider.subscriptionPlanName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (featureProvider.subscriptionPlanPrice != null) ...[
                  Text(
                    '\$${featureProvider.subscriptionPlanPrice!['monthly']}/month',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageSection(
      BuildContext context, FeatureProvider featureProvider) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usage & Limits',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        UsageIndicator(
          limitKey: 'maxEmployees',
          label: 'Employees',
          icon: Icons.people,
        ),
        SizedBox(height: 8),
        UsageIndicator(
          limitKey: 'maxStorageGB',
          label: 'Storage',
          icon: Icons.storage,
        ),
        SizedBox(height: 8),
        UsageIndicator(
          limitKey: 'maxApiCallsPerDay',
          label: 'API Calls',
          icon: Icons.api,
        ),
      ],
    );
  }

  Widget _buildFeatureSection(
      BuildContext context, FeatureProvider featureProvider) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Features',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        FeatureStatus(
          feature: 'attendance',
          label: 'Attendance Tracking',
          icon: Icons.access_time,
        ),
        SizedBox(height: 8),
        FeatureStatus(
          feature: 'payroll',
          label: 'Payroll Management',
          icon: Icons.payment,
        ),
        SizedBox(height: 8),
        FeatureStatus(
          feature: 'leaveManagement',
          label: 'Leave Management',
          icon: Icons.event_note,
        ),
        SizedBox(height: 8),
        FeatureStatus(
          feature: 'analytics',
          label: 'Analytics & Reports',
          icon: Icons.analytics,
        ),
        SizedBox(height: 8),
        FeatureStatus(
          feature: 'documentManagement',
          label: 'Document Management',
          icon: Icons.folder,
        ),
        SizedBox(height: 8),
        FeatureStatus(
          feature: 'customBranding',
          label: 'Custom Branding',
          icon: Icons.palette,
        ),
        SizedBox(height: 8),
        FeatureStatus(
          feature: 'apiAccess',
          label: 'API Access',
          icon: Icons.code,
        ),
        SizedBox(height: 8),
        FeatureStatus(
          feature: 'advancedReporting',
          label: 'Advanced Reporting',
          icon: Icons.assessment,
        ),
      ],
    );
  }

  Widget _buildWarningsSection(
      BuildContext context, FeatureProvider featureProvider) {
    final warnings = <Widget>[];

    // Check for exceeded limits
    if (featureProvider.hasExceededLimits) {
      warnings.add(
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border.all(color: Colors.red.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Usage limits exceeded: ${featureProvider.exceededLimits.join(', ')}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Check for usage warnings
    if (featureProvider.usageWarnings.isNotEmpty) {
      warnings.add(
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border.all(color: Colors.orange.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'High usage warning: ${featureProvider.usageWarnings.join(', ')}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Check if company is inactive
    if (!featureProvider.isCompanyActive) {
      warnings.add(
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border.all(color: Colors.red.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.block, color: Colors.red.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Company account is inactive. Contact your administrator.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (warnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alerts & Warnings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...warnings,
      ],
    );
  }
}
