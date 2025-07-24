import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feature_provider.dart';

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
          margin: const EdgeInsets.only(bottom: 16),
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
