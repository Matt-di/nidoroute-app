import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nitoroute/core/models/trip.dart';
import 'package:nitoroute/core/models/delivery.dart';
import 'package:nitoroute/core/models/trip_status_info.dart';
import 'package:nitoroute/core/theme/app_theme.dart';
import 'package:nitoroute/core/widgets/app_button.dart';
import 'package:nitoroute/core/widgets/user_avatar.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum TripCardMode { driver, admin, guardian }

class UnifiedTripCard extends StatefulWidget {
  final Trip trip;
  final TripCardMode mode;
  final VoidCallback? onTap;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLiveTracking;
  final VoidCallback? onDetails;
  final bool isActive;
  final bool showActions;
  final bool isViewOnly;

  const UnifiedTripCard({
    super.key,
    required this.trip,
    this.mode = TripCardMode.driver,
    this.onTap,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.onEdit,
    this.onDelete,
    this.onLiveTracking,
    this.onDetails,
    this.isActive = false,
    this.showActions = true,
    this.isViewOnly = false,
  });

  @override
  State<UnifiedTripCard> createState() => _UnifiedTripCardState();
}

class _UnifiedTripCardState extends State<UnifiedTripCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isActive && widget.mode == TripCardMode.driver) {
      return _buildFeaturedCard(context);
    }
    return _buildStandardCard(context);
  }

  Widget _buildStandardCard(BuildContext context) {
    final tripStatus = _getTripStatusInfo();
    final progressPercentage = _getProgressPercentage();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _isPressed ? 0.15 : 0.08,
                    ),
                    blurRadius: _isPressed ? 20 : 12,
                    offset: Offset(0, _isPressed ? 8 : 4),
                  ),
                  if (widget.isActive)
                    BoxShadow(
                      color: tripStatus.color.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                ],
                border: Border.all(
                  color: widget.isActive
                      ? tripStatus.color.withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    // Status Header Bar
                    _buildStatusHeader(tripStatus),
                    
                    // Main Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Route and Time Section
                          _buildRouteSection(tripStatus),
                          const SizedBox(height: 16),
                          
                          // Driver and Progress Section
                          _buildDriverSection(progressPercentage, tripStatus),
                          const SizedBox(height: 16),
                          
                          // Passengers and Metrics
                          _buildMetricsSection(progressPercentage),
                          
                          // Guardian-specific next delivery info
                          if (widget.mode == TripCardMode.guardian && widget.trip.nextDelivery != null) ...[
                            const SizedBox(height: 16),
                            _buildNextDeliveryInfo(),
                          ],
                          
                          // Action Buttons
                          if (widget.showActions && !widget.isViewOnly) ...[
                            const SizedBox(height: 20),
                            _buildActionButtons(tripStatus),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
        );
      },
    );
  }

  Widget _buildFeaturedCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap ?? widget.onPrimaryAction,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ).animate(onPlay: (c) => c.repeat()).scale(duration: 1000.ms, curve: Curves.easeInOut),
                          const SizedBox(width: 8),
                          const Text(
                            'LIVE NOW',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  widget.trip.route?.name ?? 'Active Trip',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFeaturedInfo(Icons.people, '${widget.trip.metrics.plannedPassengers} Students'),
                    const SizedBox(width: 16),
                    _buildFeaturedInfo(Icons.schedule, widget.trip.scheduledStartTime ?? '--:--'),
                  ],
                ),
                const SizedBox(height: 20),
                _buildProgressBar(Colors.white.withOpacity(0.2), Colors.white),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildStatusHeader(TripStatusInfo status) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            status.color,
            status.color.withValues(alpha: 0.6),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSection(TripStatusInfo status) {
    return Row(
      children: [
        // Route Icon Container
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: status.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _getRouteIcon(),
            color: status.color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        
        // Route Information
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.trip.route?.name ?? 'Unnamed Route',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTripTime(),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusBadge(status),
                ],
              ),
            ],
          ),
        ),
        
        // Quick Actions for Admin
        if (widget.mode == TripCardMode.admin && widget.showActions && !widget.isViewOnly)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.textSecondary,
            ),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              if (widget.onEdit != null)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Trip'),
                    ],
                  ),
                ),
              if (widget.onDelete != null)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Trip', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDriverSection(double progress, TripStatusInfo status) {
    return Row(
      children: [
        // Driver Avatar
        UserAvatarWithBorder(
          imageUrl: widget.trip.driver?.avatar,
          name: widget.trip.driver?.fullName ?? 'Unassigned Driver',
          size: 40,
          borderColor: status.color.withValues(alpha: 0.1),
          borderWidth: 2,
        ),
        const SizedBox(width: 12),
        
        // Driver Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.trip.driver?.fullName ?? 'Unassigned Driver',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.trip.driver?.phone != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.trip.driver!.phone!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Progress Indicator for Active Trips
        if (status.key == 'in_progress' || status.key == 'active')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: status.color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetricsSection(double progress) {
    return Column(
      children: [
        // Progress Bar for Active Trips
        if (progress > 0) ...[
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Metrics Row
        Row(
          children: [
            _buildMetricItem(
              Icons.people_outline,
              '${widget.trip.metrics.actualPassengers}/${widget.trip.metrics.plannedPassengers}',
              'Passengers',
              AppTheme.primaryColor,
            ),
            const SizedBox(width: 16),
            _buildMetricItem(
              Icons.route_outlined,
              '${widget.trip.metrics.actualDistance.toStringAsFixed(1)}km',
              'Distance',
              Colors.green,
            ),
            const SizedBox(width: 16),
            _buildMetricItem(
              Icons.access_time,
              _formatDuration(),
              'Duration',
              Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNextDeliveryInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Stop',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.trip.nextDelivery!.passengerName,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(TripStatusInfo status) {
    final primaryAction = _getPrimaryAction(status);
    final secondaryAction = _getSecondaryAction(status);

    return Row(
      children: [
        // Primary Action
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: primaryAction.onPressed,
            icon: Icon(primaryAction.icon, size: 18),
            label: Text(primaryAction.label),
            style: ElevatedButton.styleFrom(
              backgroundColor: status.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        
        // Secondary Action
        if (secondaryAction != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: secondaryAction.onPressed,
              icon: Icon(secondaryAction.icon, size: 18),
              label: Text(secondaryAction.label),
              style: OutlinedButton.styleFrom(
                foregroundColor: status.color,
                side: BorderSide(color: status.color),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedInfo(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildProgressBar(Color bg, Color fg) {
    // Determine progress
    double progress = 0.0;
    if (widget.trip.metrics.plannedPassengers > 0) {
      progress = (widget.trip.metrics.actualPassengers / widget.trip.metrics.plannedPassengers).clamp(0.0, 1.0);
    }

    return Column(
      children: [
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(3))),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Trip Progress', style: TextStyle(color: fg.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w500)),
            Text('${(progress * 100).toInt()}%', style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(TripStatusInfo status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  TripStatusInfo _getTripStatusInfo() {
    switch (widget.trip.status.toLowerCase()) {
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
          label: widget.trip.status.toUpperCase(),
          color: Colors.grey,
          icon: Icons.help_outline,
        );
    }
  }

  double _getProgressPercentage() {
    if (widget.trip.progress != null) {
      return widget.trip.progress!.percentageComplete / 100.0;
    }
    
    // Fallback calculation based on passengers
    if (widget.trip.metrics.plannedPassengers > 0) {
      return (widget.trip.metrics.actualPassengers / widget.trip.metrics.plannedPassengers)
          .clamp(0.0, 1.0);
    }
    
    return 0.0;
  }

  IconData _getRouteIcon() {
    switch (widget.trip.status.toLowerCase()) {
      case 'active':
      case 'in_progress':
        return Icons.gps_fixed;
      case 'completed':
        return Icons.check_circle;
      case 'scheduled':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.directions_bus;
    }
  }

  String _getDriverInitials() {
    final driver = widget.trip.driver;
    if (driver?.fullName != null) {
      final names = driver!.fullName!.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else if (names.isNotEmpty) {
        return names[0][0].toUpperCase();
      }
    }
    return 'D';
  }

  String _formatTripTime() {
    if (widget.trip.scheduledStartTime != null) {
      return _formatTime(widget.trip.scheduledStartTime!);
    }
    if (widget.trip.actualStartTime != null) {
      return _formatTime(widget.trip.actualStartTime!.toIso8601String());
    }
    return 'Time not set';
  }

  String _formatTime(String timeString) {
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

  String _formatDuration() {
    final duration = widget.trip.metrics.actualDuration > 0
        ? widget.trip.metrics.actualDuration
        : widget.trip.metrics.plannedDuration;
    
    if (duration > 0) {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m';
      }
    }
    return '--';
  }

  TripAction _getPrimaryAction(TripStatusInfo status) {
    switch (status.key) {
      case 'in_progress':
        return TripAction(
          label: 'Live Tracking',
          icon: Icons.location_on,
          onPressed: widget.onLiveTracking ?? widget.onPrimaryAction ?? () {},
        );
      case 'completed':
        return TripAction(
          label: 'View Summary',
          icon: Icons.summarize,
          onPressed: widget.onDetails ?? widget.onPrimaryAction ?? () {},
        );
      case 'scheduled':
        return TripAction(
          label: 'View Details',
          icon: Icons.info_outline,
          onPressed: widget.onDetails ?? widget.onPrimaryAction ?? () {},
        );
      case 'cancelled':
        return TripAction(
          label: 'View Details',
          icon: Icons.info_outline,
          onPressed: widget.onDetails ?? widget.onPrimaryAction ?? () {},
        );
      default:
        return TripAction(
          label: 'View Details',
          icon: Icons.info_outline,
          onPressed: widget.onDetails ?? widget.onPrimaryAction ?? () {},
        );
    }
  }

  TripAction? _getSecondaryAction(TripStatusInfo status) {
    switch (status.key) {
      case 'in_progress':
        return TripAction(
          label: 'Details',
          icon: Icons.info_outline,
          onPressed: widget.onDetails ?? widget.onSecondaryAction ?? () {},
        );
      case 'scheduled':
        return TripAction(
          label: 'Edit',
          icon: Icons.edit,
          onPressed: widget.onEdit ?? widget.onSecondaryAction ?? () {},
        );
      default:
        return null;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        widget.onEdit?.call();
        break;
      case 'delete':
        widget.onDelete?.call();
        break;
    }
  }
}

class TripAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  TripAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}
