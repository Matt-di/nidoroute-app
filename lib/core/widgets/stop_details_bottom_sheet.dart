import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/trip.dart';
import '../models/delivery.dart';
import 'detail_row.dart';

class StopDetailsBottomSheet extends StatelessWidget {
  final Delivery delivery;
  final Trip trip;
  final Color? primaryColor;

  const StopDetailsBottomSheet({
    super.key,
    required this.delivery,
    required this.trip,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? AppTheme.primaryColor;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        children: [
          // Header with drag indicator
          Container(
            padding: EdgeInsets.symmetric(vertical: AppTheme.spacing12),
            child: Center(
              child: Container(
                width: AppTheme.spacing32 + AppTheme.spacing8,
                height: AppTheme.spacing4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppTheme.spacing4 / 2),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacing24,
                0,
                AppTheme.spacing24,
                AppTheme.spacing24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Passenger Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppTheme.spacing16),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radius16),
                        ),
                        child: Icon(
                          Icons.person,
                          color: primary,
                          size: AppTheme.fontSize20 + AppTheme.spacing8,
                        ),
                      ),
                      SizedBox(width: AppTheme.spacing16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              delivery.passengerName ?? 'Unknown Passenger',
                              style: AppTheme.displayMedium.copyWith(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontSize20,
                              ),
                            ),
                            SizedBox(height: AppTheme.spacing4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing12,
                                vertical: AppTheme.spacing4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.getStatusColor(delivery.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radius12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    AppTheme.getStatusIcon(delivery.status),
                                    color: AppTheme.getStatusColor(delivery.status),
                                    size: AppTheme.fontSize14,
                                  ),
                                  SizedBox(width: AppTheme.spacing4),
                                  Text(
                                    AppTheme.formatStatus(delivery.status),
                                    style: AppTheme.labelSmall.copyWith(
                                      color: AppTheme.getStatusColor(delivery.status),
                                      fontSize: AppTheme.fontSize11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: AppTheme.textSecondary.withOpacity(0.4),
                          size: AppTheme.fontSize24,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppTheme.spacing32),

                  // Trip Details Card
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacing20),
                    decoration: AppTheme.infoCardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: primary,
                              size: AppTheme.fontSize20,
                            ),
                            SizedBox(width: AppTheme.spacing8),
                            Text(
                              'Trip Details',
                              style: AppTheme.headlineMedium.copyWith(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontSize16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacing16),

                        // Scheduled Pickup Time
                        DetailRow(
                          icon: Icons.schedule,
                          label: 'Scheduled Time',
                          value: delivery.scheduledPickupTime != null
                              ? DateFormat('MMM dd, yyyy • h:mm a').format(delivery.scheduledPickupTime!)
                              : 'Not scheduled',
                        ),
                        SizedBox(height: AppTheme.spacing12),

                        // Pickup Location
                        if (delivery.pickupLat != null && delivery.pickupLng != null)
                          DetailRow(
                            icon: Icons.my_location,
                            label: 'Pickup Location',
                            value: '${delivery.pickupLat!.toStringAsFixed(4)}, ${delivery.pickupLng!.toStringAsFixed(4)}',
                          ),

                        // Drop-off Location (if available from trip data)
                        if (trip.endLat != null && trip.endLng != null)
                          Column(
                            children: [
                              SizedBox(height: AppTheme.spacing12),
                              DetailRow(
                                icon: Icons.location_on,
                                label: 'Drop-off Location',
                                value: '${trip.endLat!.toStringAsFixed(4)}, ${trip.endLng!.toStringAsFixed(4)}',
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppTheme.spacing20),

                  // Trip Information Card
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacing20),
                    decoration: AppTheme.infoCardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.directions_bus,
                              color: primary,
                              size: AppTheme.fontSize20,
                            ),
                            SizedBox(width: AppTheme.spacing8),
                            Text(
                              'Trip Information',
                              style: AppTheme.headlineMedium.copyWith(
                                color: AppTheme.textPrimary,
                                fontSize: AppTheme.fontSize16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacing16),

                        // Route
                        if (trip.route?.name != null)
                          DetailRow(
                            icon: Icons.route,
                            label: 'Route',
                            value: trip.route!.name!,
                          ),

                        if (trip.route?.name != null) SizedBox(height: AppTheme.spacing12),

                        // Trip Date
                        DetailRow(
                          icon: Icons.calendar_today,
                          label: 'Date',
                          value: DateFormat('EEEE, MMMM dd, yyyy').format(trip.tripDate),
                        ),
                        SizedBox(height: AppTheme.spacing12),

                        // Trip Type
                        DetailRow(
                          icon: Icons.swap_calls,
                          label: 'Type',
                          value: trip.tripType.toUpperCase(),
                        ),

                        // Vehicle
                        if (trip.car != null)
                          Column(
                            children: [
                              SizedBox(height: AppTheme.spacing12),
                              DetailRow(
                                icon: Icons.directions_bus,
                                label: 'Vehicle',
                                value: trip.car!.displayName,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppTheme.spacing32),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: AppTheme.textWhite,
                        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Close',
                        style: AppTheme.labelLarge.copyWith(
                          color: AppTheme.textWhite,
                          fontSize: AppTheme.fontSize16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
