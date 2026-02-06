import 'package:flutter/material.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../driver/presentation/screens/live_tracking_screen.dart';
import '../screens/modern_trip_detail_screen.dart';
import 'package:intl/intl.dart';

class EnhancedTripCard extends StatelessWidget {
  final Trip trip;
  final bool isActive;

  const EnhancedTripCard({
    super.key,
    required this.trip,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = trip.status.toLowerCase() == 'completed';
    final isInProgress = trip.status.toLowerCase() == 'in_progress' || trip.status.toLowerCase() == 'active';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: isActive ? Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 2) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Route and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.route?.name ?? 'Unnamed Route',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Route ID: ${trip.routeId}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _getStatusBadge(trip.status),
              ],
            ),

            const SizedBox(height: 16),

            // Driver Info
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trip.driver?.fullName ?? 'Unassigned Driver',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Time and Passengers
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trip.scheduledStartTime != null
                        ? _formatScheduledTime(trip.scheduledStartTime!)
                        : 'Time not set',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trip.metrics.actualPassengers}/${trip.metrics.plannedPassengers}',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                // Primary Action Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handlePrimaryAction(context),
                    icon: Icon(
                      isCompleted
                          ? Icons.description
                          : isInProgress
                              ? Icons.location_on
                              : Icons.info,
                      size: 18,
                    ),
                    label: Text(
                      isCompleted
                          ? 'View Details'
                          : isInProgress
                              ? 'Live Tracking'
                              : 'View Details',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted
                          ? Colors.green
                          : isInProgress
                              ? AppTheme.primaryColor
                              : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // Secondary Action (if applicable)
                if (trip.status.toLowerCase() == 'scheduled') ...[
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _handleDeleteAction(context),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handlePrimaryAction(BuildContext context) {
    final isCompleted = trip.status.toLowerCase() == 'completed';
    final isInProgress = trip.status.toLowerCase() == 'in_progress' || trip.status.toLowerCase() == 'active';

    if (isCompleted) {
      // Completed trips go to detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ModernTripDetailScreen(trip: trip),
        ),
      );
    } else if (isInProgress) {
      // Ongoing trips go to live tracking
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LiveTrackingScreen(trip: trip),
        ),
      );
    } else {
      // Other trips go to detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ModernTripDetailScreen(trip: trip),
        ),
      );
    }
  }

  void _handleDeleteAction(BuildContext context) {
    // This would typically use a BLoC event, but for now we'll show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delete functionality would be implemented here')),
    );
  }

  String _formatScheduledTime(String timeString) {
    try {
      // Try parsing as ISO 8601 first
      final dateTime = DateTime.tryParse(timeString);
      if (dateTime != null) {
        return DateFormat('MMM d, h:mm a').format(dateTime);
      }

      // If that fails, try parsing as time-only string (HH:mm:ss)
      if (timeString.contains(':')) {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          final now = DateTime.now();
          final time = DateTime(now.year, now.month, now.day, hour, minute);
          return DateFormat('h:mm a').format(time);
        }
      }

      // Fallback
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  Widget _getStatusBadge(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'in_progress':
        return AppBadge.info(label: 'ACTIVE');
      case 'completed':
        return AppBadge.success(label: 'COMPLETED');
      case 'scheduled':
        return AppBadge.warning(label: 'SCHEDULED');
      case 'cancelled':
        return AppBadge.error(label: 'CANCELLED');
      default:
        return AppBadge(label: status.toUpperCase());
    }
  }
}
