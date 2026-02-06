import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../trip/logic/bloc/trip_detail_bloc.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/bloc/trip_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/live_tracker_map.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/delivery.dart';
import '../../../../core/utils/map_utils.dart';
import '../../../../core/widgets/user_avatar.dart';

class DriverCompletedTripScreen extends StatefulWidget {
  final Trip trip;

  const DriverCompletedTripScreen({
    super.key,
    required this.trip,
  });

  @override
  State<DriverCompletedTripScreen> createState() =>
      _DriverCompletedTripScreenState();
}

class _DriverCompletedTripScreenState
    extends State<DriverCompletedTripScreen> {
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<Delivery>? _deliveries;

  @override
  void initState() {
    super.initState();
    _loadTripDetails();
  }

  void _loadTripDetails() {
    context.read<TripDetailBloc>().loadTripDetails(widget.trip.id);
  }

  void _updateMapElements(BlocState<dynamic> state) async {
    if (!state.isSuccess || state.data == null) return;

    final tripDetailData = state.data as TripDetailData?;
    final trip = tripDetailData?.trip ?? widget.trip;
    final deliveries = tripDetailData?.deliveries ?? widget.trip.deliveries ?? [];
    
    setState(() {
      _deliveries = deliveries;
    });

    // Add markers for start, end, and delivery points
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    // Start location marker
    if (trip.startLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(trip.startLat!, trip.startLng!),
          icon: await MapUtils.createCustomMarker(
            Icons.play_arrow,
            Colors.green,
          ),
          infoWindow: const InfoWindow(title: 'Start Point'),
        ),
      );
    }

    // End location marker
    if (trip.endLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: LatLng(trip.endLat!, trip.endLng!),
          icon: await MapUtils.createCustomMarker(
            Icons.stop,
            Colors.red,
          ),
          infoWindow: const InfoWindow(title: 'End Point'),
        ),
      );
    }

    // Delivery location markers
    for (int i = 0; i < deliveries.length; i++) {
      final delivery = deliveries[i];
      if (delivery.pickupLocation != null) {
        markers.add(
          Marker(
            markerId: MarkerId('delivery_$i'),
            position: LatLng(
              delivery.pickupLat!,
              delivery.pickupLng!,
            ),
            icon: await MapUtils.createCustomMarker(
              Icons.person,
              AppTheme.primaryColor,
            ),
            infoWindow: InfoWindow(
              title: delivery.passengerName ?? 'Passenger',
              snippet: delivery.status ?? 'Unknown',
            ),
          ),
        );
      }
    }

    // Add route polyline if available
    if (trip.polyline != null && trip.polyline!.isNotEmpty) {
      final routeCoordinates = MapUtils.decodePolyline(trip.polyline!);
      if (routeCoordinates.isNotEmpty) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: AppTheme.primaryColor,
            width: 5,
            points: routeCoordinates,
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: BlocConsumer<TripDetailBloc, BlocState<dynamic>>(
                listener: (context, state) {
                  if (state.isSuccess) {
                    _updateMapElements(state);
                  }
                },
                builder: (context, state) {
                  return CustomScrollView(
                    slivers: [
                      // Map Section
                      SliverToBoxAdapter(
                        child: Container(
                          height: 300,
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: widget.trip.startLocation != null
                                    ? LatLng(
                                        widget.trip.startLat!,
                                        widget.trip.startLng!,
                                      )
                                    : const LatLng(0, 0),
                                zoom: 14,
                              ),
                              markers: _markers,
                              polylines: _polylines,
                              myLocationEnabled: false,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                            ),
                          ),
                        ),
                      ),
        
                      // Trip Summary Section
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Trip Summary',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSummaryRow(
                                'Route',
                                widget.trip.route?.name ?? 'Unknown Route',
                                Icons.route,
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                'Date',
                                DateFormat('MMM d, yyyy').format(widget.trip.tripDate),
                                Icons.calendar_today,
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                'Duration',
                                _formatDuration(widget.trip.metrics.actualDuration),
                                Icons.access_time,
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                'Distance',
                                '${widget.trip.metrics.actualDistance.toStringAsFixed(1)} km',
                                Icons.straighten,
                              ),
                            ],
                          ),
                        ),
                      ),
        
                      // Statistics Section
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Trip Statistics',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Passengers',
                                      '${widget.trip.metrics.actualPassengers}',
                                      Icons.people,
                                      AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Completed',
                                      '${_deliveries?.where((d) => d.status == 'completed').length ?? 0}',
                                      Icons.check_circle,
                                      Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
        
                      // Deliveries Section
                      if (_deliveries != null && _deliveries!.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Passengers',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ..._deliveries!.map((delivery) => _buildDeliveryItem(delivery)),
                              ],
                            ),
                          ),
                        ),
        
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return DashboardHeader(
      title: 'Completed Trip',
      subtitle: widget.trip.route?.name ?? 'Unknown Route',
      showBackButton: true,
      actions: [
        HeaderAction(
          icon: Icons.check_circle,
          onPressed: () {},
          badgeCount: null,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryItem(Delivery delivery) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          UserAvatar(
            imageUrl: delivery.passenger?.image,
            name: delivery.passengerName ?? 'Unknown Passenger',
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delivery.passengerName ?? 'Unknown Passenger',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  delivery.status ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12,
                    color: delivery.status == 'completed'
                        ? Colors.green
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (delivery.status == 'completed')
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes <= 0) return '--';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }
}
