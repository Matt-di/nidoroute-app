import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class AppBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  factory AppBadge.success({required String label}) {
    return AppBadge(
      label: label,
      backgroundColor: AppTheme.successColor.withValues(alpha: 0.1),
      textColor: AppTheme.successColor,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  factory AppBadge.error({required String label}) {
    return AppBadge(
      label: label,
      backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
      textColor: AppTheme.errorColor,
      icon: Icons.error_outline_rounded,
    );
  }

  factory AppBadge.warning({required String label}) {
    return AppBadge(
      label: label,
      backgroundColor: AppTheme.warningColor.withValues(alpha: 0.1),
      textColor: AppTheme.warningColor,
      icon: Icons.warning_amber_rounded,
    );
  }

  factory AppBadge.info({required String label}) {
    return AppBadge(
      label: label,
      backgroundColor: AppTheme.infoColor.withValues(alpha: 0.1),
      textColor: AppTheme.infoColor,
      icon: Icons.info_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = textColor == AppTheme.errorColor || textColor == AppTheme.warningColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor ?? AppTheme.textPrimary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor ?? AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    )
    .animate(onPlay: (controller) => isCritical ? controller.repeat(reverse: true) : null)
    .fadeIn(duration: 400.ms)
    .scaleXY(begin: 0.9, end: 1.0, duration: 400.ms, curve: Curves.easeOutBack)
    .shimmer(
      delay: 1.seconds,
      duration: 1500.ms,
      color: Colors.white.withOpacity(0.2),
    );
  }
}
