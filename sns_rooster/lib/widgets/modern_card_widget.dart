import 'package:flutter/material.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final double elevation;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool showBackgroundPattern;
  final VoidCallback? onTap;

  const ModernCard({
    super.key,
    required this.child,
    this.accentColor,
    this.elevation = 6,
    this.padding,
    this.borderRadius,
    this.showBackgroundPattern = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;
    final defaultPadding = padding ?? const EdgeInsets.all(16);
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(20);

    Widget cardContent = Container(
      decoration: BoxDecoration(
        borderRadius: defaultBorderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.05),
            accent.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          if (showBackgroundPattern)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Padding(
            padding: defaultPadding,
            child: child,
          ),
        ],
      ),
    );

    return Card(
      elevation: elevation,
      shadowColor: accent.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: defaultBorderRadius),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: defaultBorderRadius,
              child: cardContent,
            )
          : cardContent,
    );
  }
}

// Specialized card for KPI-style content
class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool hasData;
  final VoidCallback? onTap;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.hasData = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ModernCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and title row
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: color,
                ),
              ),
              const Spacer(),
              if (!hasData)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'No Data',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Value
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: hasData ? theme.colorScheme.onSurface : Colors.grey[400],
              fontSize: hasData ? 18 : 16,
            ),
          ),
          const SizedBox(height: 4),
          // Title
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// Specialized card for settings/action items
class SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? accentColor;

  const SettingsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;

    return ModernCard(
      accentColor: accent,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(actionText!),
            ),
          ],
        ],
      ),
    );
  }
}
