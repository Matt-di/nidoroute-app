import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/trip.dart';
import '../models/trip_status_info.dart';

enum SimpleTripCardMode { driver, admin, guardian }

class SimpleTripCard extends StatelessWidget {
  final Trip trip;
  final SimpleTripCardMode mode;
  final VoidCallback? onTap;
  final VoidCallback? onPrimaryAction;
  final bool showActions;

  const SimpleTripCard({
    super.key,
    required this.trip,
    this.mode = SimpleTripCardMode.driver,
    this.onTap,
    this.onPrimaryAction,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getTripStatusInfo();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusInfo.color.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: statusInfo.color.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with gradient accent
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: statusInfo.color.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Status indicator with gradient
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              statusInfo.color,
                              statusInfo.color.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Route info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.route?.name ?? 'Unnamed Route',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTripDate(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(trip.scheduledStartTime),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Premium status badge
                      _buildPremiumStatusBadge(statusInfo),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Enhanced metrics row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPremiumMetric(
                        Icons.people_rounded,
                        'Passengers',
                        '${trip.metrics.actualPassengers}/${trip.metrics.plannedPassengers}',
                        statusInfo.color,
                      ),
                      _buildVerticalDivider(),
                      if (trip.metrics.actualDistance > 0) ...[
                        _buildPremiumMetric(
                          Icons.route_rounded,
                          'Distance',
                          '${trip.metrics.actualDistance.toStringAsFixed(1)}km',
                          statusInfo.color,
                        ),
                        _buildVerticalDivider(),
                      ],
                      _buildPremiumMetric(
                        Icons.speed_rounded,
                        'Duration',
                        _calculateDuration(),
                        statusInfo.color,
                      ),
                    ],
                  ),
                ),
                
                // Driver info for non-driver modes
                if (mode != SimpleTripCardMode.driver && trip.driver != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: statusInfo.color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusInfo.color.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusInfo.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: statusInfo.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Driver',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                trip.driver!.fullName ?? 'Unknown Driver',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Premium action button
                if (showActions) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusInfo.color,
                          statusInfo.color.withOpacity(0.8),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: statusInfo.color.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onPrimaryAction ?? onTap,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                statusInfo.icon,
                                size: 20,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getActionButtonText(statusInfo),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumStatusBadge(TripStatusInfo status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            status.color.withOpacity(0.15),
            status.color.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status.color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 12,
            color: status.color,
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumMetric(IconData icon, String label, String value, Color accentColor) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: accentColor,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.grey.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  String _calculateDuration() {
    // Simple duration calculation - you can enhance this based on your data
    if (trip.scheduledStartTime != null && trip.scheduledEndTime != null) {
      try {
        final start = DateTime.parse(trip.scheduledStartTime!);
        final end = DateTime.parse(trip.scheduledEndTime!);
        final duration = end.difference(start);
        
        if (duration.inHours > 0) {
          return '${duration.inHours}h ${duration.inMinutes % 60}m';
        } else {
          return '${duration.inMinutes}m';
        }
      } catch (e) {
        return '--';
      }
    }
    return '--';
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTripDate() {
    final now = DateTime.now();
    final tripDate = trip.tripDate;
    
    if (tripDate.year == now.year && tripDate.month == now.month && tripDate.day == now.day) {
      return 'Today';
    }
    
    final yesterday = now.subtract(const Duration(days: 1));
    if (tripDate.year == yesterday.year && tripDate.month == yesterday.month && tripDate.day == yesterday.day) {
      return 'Yesterday';
    }
    
    return DateFormat('MMM d, yyyy').format(tripDate);
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return '--:--';
    
    try {
      final dateTime = DateTime.tryParse(timeString);
      if (dateTime != null) {
        return DateFormat('h:mm a').format(dateTime);
      }
      
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
      
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  String _getActionButtonText(TripStatusInfo status) {
    switch (status.key) {
      case 'in_progress':
        return 'Live Tracking';
      case 'completed':
        return 'View Summary';
      case 'scheduled':
        return 'View Details';
      case 'cancelled':
        return 'View Details';
      default:
        return 'View Details';
    }
  }

  TripStatusInfo _getTripStatusInfo() {
    switch (trip.status.toLowerCase()) {
      case 'active':
      case 'in_progress':
        return TripStatusInfo(
          key: 'in_progress',
          label: 'IN PROGRESS',
          color: AppTheme.successColor,
          icon: Icons.gps_fixed,
        );
      case 'completed':
        return TripStatusInfo(
          key: 'completed',
          label: 'COMPLETED',
          color: Colors.green,
          icon: Icons.check_circle,
        );
      case 'scheduled':
        return TripStatusInfo(
          key: 'scheduled',
          label: 'SCHEDULED',
          color: AppTheme.warningColor,
          icon: Icons.schedule,
        );
      case 'cancelled':
        return TripStatusInfo(
          key: 'cancelled',
          label: 'CANCELLED',
          color: AppTheme.errorColor,
          icon: Icons.cancel,
        );
      default:
        return TripStatusInfo(
          key: 'unknown',
          label: trip.status.toUpperCase(),
          color: Colors.grey,
          icon: Icons.help_outline,
        );
    }
  }
}
