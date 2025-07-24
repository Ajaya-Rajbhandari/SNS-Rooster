import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feature_provider.dart';

/// Widget that shows a locked feature with upgrade prompt
class FeatureLockWidget extends StatelessWidget {
  final String featureName;
  final String title;
  final String description;
  final IconData icon;
  final Widget? preview;
  final VoidCallback? onUpgradePressed;

  const FeatureLockWidget({
    Key? key,
    required this.featureName,
    required this.title,
    required this.description,
    required this.icon,
    this.preview,
    this.onUpgradePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FeatureProvider>(
      builder: (context, featureProvider, _) {
        final isFeatureEnabled = featureProvider.isFeatureEnabled(featureName);

        if (isFeatureEnabled) {
          return const SizedBox.shrink(); // Don't show if feature is enabled
        }

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Preview area (if provided)
              if (preview != null) ...[
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Stack(
                    children: [
                      preview!,
                      // Overlay with blur effect
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          backgroundBlendMode: BlendMode.darken,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Lock content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Lock icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        color: Colors.orange.shade600,
                        size: 24,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Description
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Current plan info
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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

                    // Upgrade button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onUpgradePressed ??
                            () {
                              _showUpgradeDialog(context, featureProvider);
                            },
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
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUpgradeDialog(
      BuildContext context, FeatureProvider featureProvider) {
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
              // TODO: Navigate to upgrade page or contact admin
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
}

/// Widget that shows a feature comparison between plans
class FeatureComparisonWidget extends StatelessWidget {
  final String featureName;
  final String title;
  final IconData icon;
  final List<String> availablePlans;

  const FeatureComparisonWidget({
    Key? key,
    required this.featureName,
    required this.title,
    required this.icon,
    required this.availablePlans,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FeatureProvider>(
      builder: (context, featureProvider, _) {
        final isFeatureEnabled = featureProvider.isFeatureEnabled(featureName);
        final currentPlan = featureProvider.subscriptionPlanName;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: Icon(
              icon,
              color: isFeatureEnabled
                  ? Colors.green.shade600
                  : Colors.grey.shade400,
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isFeatureEnabled ? Colors.black : Colors.grey.shade600,
              ),
            ),
            subtitle: Text(
              isFeatureEnabled
                  ? 'Available in your plan'
                  : 'Available in: ${availablePlans.join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: isFeatureEnabled
                    ? Colors.green.shade600
                    : Colors.grey.shade500,
              ),
            ),
            trailing: isFeatureEnabled
                ? Icon(Icons.check_circle, color: Colors.green.shade600)
                : Icon(Icons.lock_outline, color: Colors.grey.shade400),
          ),
        );
      },
    );
  }
}

/// Widget that shows usage limits and warnings
class UsageLimitWidget extends StatelessWidget {
  final String limitKey;
  final String title;
  final IconData icon;
  final String unit;

  const UsageLimitWidget({
    Key? key,
    required this.limitKey,
    required this.title,
    required this.icon,
    required this.unit,
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

        if (limit == 0) return const SizedBox.shrink(); // Unlimited

        Color getColor() {
          if (isExceeded) return Colors.red;
          if (isWarning) return Colors.orange;
          return Colors.green;
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: getColor()),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (isExceeded)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Limit Exceeded',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Progress bar
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(getColor()),
                ),

                const SizedBox(height: 8),

                // Usage text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$currentUsage / $limit $unit',
                      style: TextStyle(
                        color: getColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        color: getColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                if (isExceeded || isWarning) ...[
                  const SizedBox(height: 8),
                  Text(
                    isExceeded
                        ? 'You have exceeded your limit. Please upgrade your plan.'
                        : 'You are approaching your limit. Consider upgrading.',
                    style: TextStyle(
                      color: getColor(),
                      fontSize: 12,
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
