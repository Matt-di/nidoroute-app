import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/delivery.dart';
import '../../../../core/widgets/user_avatar.dart';

class PassengerCard extends StatelessWidget {
  final Delivery delivery;
  final bool isPickup;

  const PassengerCard({
    super.key,
    required this.delivery,
    required this.isPickup,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isPickup ? AppTheme.successColor : AppTheme.warningColor;
    final statusText = isPickup ? 'Pick-up' : 'Drop-off';
    final statusIcon = isPickup ? Icons.north : Icons.south;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radius8),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Avatar
          UserAvatarWithBorder(
            imageUrl: delivery.passenger?.image,
            name: delivery.passenger?.displayName ?? delivery.passengerName ?? 'Unknown Passenger',
            size: AppTheme.spacing10 * 2, // 20
            borderColor: AppTheme.surfaceColor,
            borderWidth: 2,
          ),
          SizedBox(width: AppTheme.spacing12),
          // Passenger info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delivery.passenger?.displayName ?? delivery.passengerName ?? 'Unknown Passenger',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: AppTheme.fontWeightSemiBold,
                  ),
                ),
                SizedBox(height: AppTheme.spacing4 / 2),
                Text(
                  'Stop ${delivery.sequence} • Bus Pass #${delivery.sequence}',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing8,
              vertical: AppTheme.spacing4 / 2,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radius20),
            ),
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  size: AppTheme.fontSize12,
                  color: statusColor,
                ),
                SizedBox(width: AppTheme.spacing4),
                Text(
                  statusText,
                  style: AppTheme.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: AppTheme.fontWeightBold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
