import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TripSuccessHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<PerformanceStat> stats;
  final Color? backgroundColor;
  final Color? textColor;

  const TripSuccessHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.stats,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppTheme.primaryColor;
    final txtColor = textColor ?? AppTheme.textWhite;

    return Container(
      decoration: AppTheme.successHeaderDecoration.copyWith(color: bgColor),
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        AppTheme.spacing16,
        AppTheme.spacing16,
        AppTheme.spacing32,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.spacing24),
            decoration: BoxDecoration(
              color: txtColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radius24),
              border: Border.all(color: txtColor.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.check_circle,
              color: txtColor,
              size: AppTheme.fontSize24 * 2.5, // 60
            ),
          ),
          SizedBox(height: AppTheme.spacing16),
          Text(
            title,
            style: AppTheme.displayMedium.copyWith(
              color: txtColor,
              fontSize: AppTheme.fontSize24,
            ),
          ),
          SizedBox(height: AppTheme.spacing4),
          Text(
            subtitle,
            style: AppTheme.bodyMedium.copyWith(
              color: txtColor.withOpacity(0.8),
              fontSize: AppTheme.fontSize14,
            ),
          ),
          SizedBox(height: AppTheme.spacing24),
          // Performance Stats Grid
          Row(
            children: stats.map((stat) => Expanded(
              child: _buildPerformanceStat(stat, txtColor),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStat(PerformanceStat stat, Color textColor) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppTheme.spacing4),
      padding: EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(color: textColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.label.toUpperCase(),
            style: AppTheme.labelSmall.copyWith(
              color: textColor.withOpacity(0.7),
              fontSize: AppTheme.fontSize10,
            ),
          ),
          SizedBox(height: AppTheme.spacing4),
          Text(
            stat.value,
            style: AppTheme.displayLarge.copyWith(
              color: textColor,
              fontSize: AppTheme.fontSize24,
            ),
          ),
          SizedBox(height: AppTheme.spacing4),
          if (stat.trend != null && stat.trendColor != null)
            Row(
              children: [
                Icon(stat.icon, color: stat.trendColor, size: AppTheme.fontSize12),
                SizedBox(width: AppTheme.spacing4),
                Text(
                  stat.trend!,
                  style: AppTheme.labelSmall.copyWith(
                    color: stat.trendColor,
                    fontSize: AppTheme.fontSize10,
                  ),
                ),
              ],
            )
          else if (stat.subtitle != null)
            Row(
              children: [
                Icon(stat.icon, color: textColor.withOpacity(0.5), size: AppTheme.fontSize12),
                SizedBox(width: AppTheme.spacing4),
                Text(
                  stat.subtitle!,
                  style: AppTheme.labelSmall.copyWith(
                    color: textColor.withOpacity(0.5),
                    fontSize: AppTheme.fontSize10,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class PerformanceStat {
  final String label;
  final String value;
  final IconData icon;
  final String? trend;
  final Color? trendColor;
  final String? subtitle;

  const PerformanceStat({
    required this.label,
    required this.value,
    required this.icon,
    this.trend,
    this.trendColor,
    this.subtitle,
  });
}
