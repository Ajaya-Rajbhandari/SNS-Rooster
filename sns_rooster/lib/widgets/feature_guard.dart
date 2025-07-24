import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feature_provider.dart';

/// Widget that conditionally shows content based on feature availability
class FeatureGuard extends StatelessWidget {
  final String feature;
  final Widget child;
  final Widget? fallback;
  final bool showUpgradePrompt;
  final String? customTitle;
  final String? customDescription;

  const FeatureGuard({
    Key? key,
    required this.feature,
    required this.child,
    this.fallback,
    this.showUpgradePrompt = false,
    this.customTitle,
    this.customDescription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FeatureProvider>(
      builder: (context, featureProvider, _) {
        final isFeatureEnabled = featureProvider.isFeatureEnabled(feature);

        if (isFeatureEnabled) {
          return child;
        }

        if (fallback != null) {
          return fallback!;
        }

        if (showUpgradePrompt) {
          return _buildUpgradePrompt(context, featureProvider);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildUpgradePrompt(
      BuildContext context, FeatureProvider featureProvider) {
    final title = customTitle ?? _getFeatureTitle(feature);
    final description = customDescription ?? _getFeatureDescription(feature);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              color: Colors.orange.shade600,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              'Current Plan: ${featureProvider.subscriptionPlanName}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showUpgradeDialog(context, featureProvider),
              icon: const Icon(Icons.upgrade, size: 18),
              label: const Text('Upgrade Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(
      BuildContext context, FeatureProvider featureProvider) {
    final title = customTitle ?? _getFeatureTitle(feature);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upgrade, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Upgrade Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The "$title" feature is not available in your current plan (${featureProvider.subscriptionPlanName}).',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'To access this feature, please contact your administrator to upgrade your subscription plan.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Contact your administrator to upgrade your plan'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Contact Admin'),
          ),
        ],
      ),
    );
  }

  String _getFeatureTitle(String feature) {
    switch (feature) {
      case 'analytics':
        return 'Analytics Dashboard';
      case 'advancedReporting':
        return 'Advanced Reporting';
      case 'customBranding':
        return 'Custom Branding';
      case 'apiAccess':
        return 'API Access';
      case 'multiLocation':
        return 'Multi-Location Support';
      case 'expenseManagement':
        return 'Expense Management';
      case 'performanceReviews':
        return 'Performance Reviews';
      case 'trainingManagement':
        return 'Training Management';
      default:
        return 'Premium Feature';
    }
  }

  String _getFeatureDescription(String feature) {
    switch (feature) {
      case 'analytics':
        return 'This feature is not available in your current plan. Upgrade to access advanced analytics and insights.';
      case 'advancedReporting':
        return 'This feature is not available in your current plan. Upgrade to access custom reports and advanced data analysis.';
      case 'customBranding':
        return 'This feature is not available in your current plan. Upgrade to customize the app with your brand.';
      case 'apiAccess':
        return 'This feature is not available in your current plan. Upgrade to access the REST API for integrations.';
      case 'multiLocation':
        return 'This feature is not available in your current plan. Upgrade to manage multiple office locations.';
      case 'expenseManagement':
        return 'This feature is not available in your current plan. Upgrade to track and manage employee expenses.';
      case 'performanceReviews':
        return 'This feature is not available in your current plan. Upgrade to conduct employee performance evaluations.';
      case 'trainingManagement':
        return 'This feature is not available in your current plan. Upgrade to manage employee training programs.';
      default:
        return 'This feature is not available in your current plan. Please upgrade to access this functionality.';
    }
  }
}

/// Widget that shows content only if usage is within limits
class UsageGuard extends StatelessWidget {
  final String limitKey;
  final Widget child;
  final Widget? fallback;
  final bool showWarning;

  const UsageGuard({
    Key? key,
    required this.limitKey,
    required this.child,
    this.fallback,
    this.showWarning = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FeatureProvider>(
      builder: (context, featureProvider, _) {
        final isWithinLimit = featureProvider.isWithinLimit(limitKey);
        final usagePercentage = featureProvider.getUsagePercentage(limitKey);
        final isWarning = usagePercentage > 80 && isWithinLimit;

        if (isWithinLimit && !isWarning) {
          return child;
        }

        if (fallback != null) {
          return fallback!;
        }

        if (showWarning && isWarning) {
          return _buildWarningWidget(context, featureProvider, limitKey);
        }

        if (!isWithinLimit) {
          return _buildLimitExceededWidget(context, featureProvider, limitKey);
        }

        return child;
      },
    );
  }

  Widget _buildWarningWidget(
      BuildContext context, FeatureProvider featureProvider, String limitKey) {
    final currentUsage = featureProvider.getCurrentUsage(limitKey);
    final limit = featureProvider.getLimit(limitKey);
    final percentage = featureProvider.getUsagePercentage(limitKey);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Usage Warning',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You are approaching your $limitKey limit ($currentUsage/$limit - $percentage%)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.orange.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitExceededWidget(
      BuildContext context, FeatureProvider featureProvider, String limitKey) {
    final currentUsage = featureProvider.getCurrentUsage(limitKey);
    final limit = featureProvider.getLimit(limitKey);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
          const SizedBox(height: 12),
          Text(
            'Limit Exceeded',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have exceeded your $limitKey limit ($currentUsage/$limit)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showUpgradeDialog(context, featureProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upgrade Plan'),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(
      BuildContext context, FeatureProvider featureProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upgrade, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Upgrade Required'),
          ],
        ),
        content: Text(
          'You have exceeded your $limitKey limit. Please upgrade your plan to continue using this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Contact your administrator to upgrade your plan'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Contact Admin'),
          ),
        ],
      ),
    );
  }
}

/// Widget that shows a usage indicator
class UsageIndicator extends StatelessWidget {
  final String limitKey;
  final String label;
  final IconData icon;

  const UsageIndicator({
    Key? key,
    required this.limitKey,
    required this.label,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FeatureProvider>(
      builder: (context, featureProvider, _) {
        final currentUsage = featureProvider.getCurrentUsage(limitKey);
        final limit = featureProvider.getLimit(limitKey);
        final percentage = featureProvider.getUsagePercentage(limitKey);
        final isExceeded = !featureProvider.isWithinLimit(limitKey);
        final isWarning = percentage > 80 && !isExceeded;

        Color progressColor;
        if (isExceeded) {
          progressColor = Colors.red;
        } else if (isWarning) {
          progressColor = Colors.orange;
        } else {
          progressColor = Colors.green;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: progressColor),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$currentUsage${limit > 0 ? '/$limit' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: progressColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value:
                      limit > 0 ? (currentUsage / limit).clamp(0.0, 1.0) : 0.0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
                if (limit > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$percentage% used',
                    style: TextStyle(
                      fontSize: 11,
                      color: progressColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget that shows feature status
class FeatureStatus extends StatelessWidget {
  final String feature;
  final String label;
  final IconData icon;

  const FeatureStatus({
    Key? key,
    required this.feature,
    required this.label,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FeatureProvider>(
      builder: (context, featureProvider, _) {
        final isEnabled = featureProvider.isFeatureEnabled(feature);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isEnabled ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isEnabled ? Colors.black87 : Colors.grey,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? Colors.green.shade100
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isEnabled ? 'Available' : 'Not Available',
                    style: TextStyle(
                      fontSize: 11,
                      color: isEnabled
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
