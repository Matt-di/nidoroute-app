import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? labelColor;
  final Color? valueColor;
  final double? iconSize;
  final double? fontSize;

  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.labelColor,
    this.valueColor,
    this.iconSize,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppTheme.spacing8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radius8),
            border: Border.all(color: AppTheme.textSecondary.withOpacity(0.1)),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppTheme.textSecondary,
            size: iconSize ?? AppTheme.fontSize20,
          ),
        ),
        SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.labelMedium.copyWith(
                  color: labelColor ?? AppTheme.textSecondary,
                  fontSize: AppTheme.fontSize12,
                ),
              ),
              SizedBox(height: AppTheme.spacing4 / 2),
              Text(
                value,
                style: AppTheme.bodyMedium.copyWith(
                  color: valueColor ?? AppTheme.textPrimary,
                  fontSize: fontSize ?? AppTheme.fontSize14,
                  fontWeight: AppTheme.fontWeightMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
