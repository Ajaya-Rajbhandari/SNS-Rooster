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
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 24,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: effectiveFg,
                    strokeWidth: 2.5,
                  ),
                )
              else
                Icon(icon, color: effectiveFg, size: 40),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: effectiveFg,
                      fontSize: 16,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
