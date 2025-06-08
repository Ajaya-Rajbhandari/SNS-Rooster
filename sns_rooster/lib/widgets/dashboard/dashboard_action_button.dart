import 'package:flutter/material.dart';

class DashboardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;
  final bool loading;

  const DashboardActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: loading ? null : onPressed,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: backgroundColor,
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
                  color: foregroundColor,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(icon, color: foregroundColor, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold, color: foregroundColor)),
          ],
        ),
      ),
    );
  }
}
