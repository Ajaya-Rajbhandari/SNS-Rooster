import 'package:flutter/material.dart';

class DashboardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;
  final bool loading;
  final bool disabled;

  const DashboardActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.loading = false,
    this.disabled = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveBg = disabled ? Colors.grey.shade400 : backgroundColor;
    final Color effectiveFg = disabled ? Colors.grey.shade200 : foregroundColor;
    return Opacity(
      opacity: disabled ? 0.6 : 1.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: (loading || disabled) ? null : onPressed,
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: effectiveFg,
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(icon, color: effectiveFg, size: 32),
              const SizedBox(height: 8),
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold, color: effectiveFg)),
            ],
          ),
        ),
      ),
    );
  }
}
