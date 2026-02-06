import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/trip.dart';
import '../models/delivery.dart';

class StopTimelineItem extends StatelessWidget {
  final Delivery delivery;
  final bool isLastStop;
  final VoidCallback? onTap;
  final Color? primaryColor;

  const StopTimelineItem({
    super.key,
    required this.delivery,
    this.isLastStop = false,
    this.onTap,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSchool = (delivery.passengerName ?? '').toLowerCase().contains('school');
    final primary = primaryColor ?? AppTheme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing4,
        ),
        padding: EdgeInsets.all(AppTheme.spacing16),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Column(
              children: [
                Container(
                  width: AppTheme.spacing8,
                  height: AppTheme.spacing8,
                  decoration: BoxDecoration(
                    color: isSchool ? primary : primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLastStop)
                  Container(
                    width: 2,
                    height: AppTheme.spacing32,
                    color: AppTheme.textSecondary.withOpacity(0.2),
                  ),
              ],
            ),
            SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stop ${delivery.sequence}: ${delivery.passengerName ?? 'Unknown'}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.fontSize14,
                      fontWeight: AppTheme.fontWeightBold,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing4),
                  Text(
                    delivery.scheduledPickupTime != null
                        ? 'Arrived ${DateFormat('h:mm a').format(delivery.scheduledPickupTime!)}'
                        : 'Time not available',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontSize12,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                    vertical: AppTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.getStatusColor(delivery.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppTheme.getStatusIcon(delivery.status),
                        color: AppTheme.getStatusColor(delivery.status),
                        size: AppTheme.fontSize12,
                      ),
                      SizedBox(width: AppTheme.spacing4),
                      Text(
                        AppTheme.formatStatus(delivery.status),
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.getStatusColor(delivery.status),
                          fontSize: AppTheme.fontSize10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  SizedBox(width: AppTheme.spacing8),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary.withOpacity(0.4),
                    size: AppTheme.fontSize20,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
