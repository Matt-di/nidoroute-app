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
import '../../../../core/models/passenger.dart';
import '../../../../core/models/delivery.dart';
import '../../../../core/utils/map_utils.dart';
import '../../../../core/widgets/user_avatar.dart';

class GuardianCompletedTripScreen extends StatefulWidget {
  final Trip trip;
  final Passenger passenger;

  const GuardianCompletedTripScreen({
    super.key,
    required this.trip,
    required this.passenger,
  });

  @override
  State<GuardianCompletedTripScreen> createState() =>
      _GuardianCompletedTripScreenState();
}

class _GuardianCompletedTripScreenState
    extends State<GuardianCompletedTripScreen> {
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Delivery? _passengerDelivery;

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
    if (tripDetailData?.trip.id != widget.trip.id) return;

    // Find the passenger's delivery
    _passengerDelivery = tripDetailData!.deliveries?.firstWhere(
      (d) => d.passengerId == widget.passenger.id,
      orElse: () => tripDetailData!.deliveries!.first,
    );

    // Create map markers and polylines for completed trip
    await _createCompletedTripMap();
  }

  Future<void> _createCompletedTripMap() async {
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    // Add route polyline if available
    if (widget.trip.polyline != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('completed_route'),
          points: MapUtils.decodePolyline(widget.trip.polyline!),
          color: Colors.green,
          width: 4,
          jointType: JointType.round,
        ),
      );
    }

    // Add completed stops markers
    if (widget.trip.deliveries != null) {
      for (final delivery in widget.trip.deliveries!) {
        final isPassengerDelivery = delivery.passengerId == widget.passenger.id;

        // Pickup marker
        if (delivery.pickupLat != null && delivery.pickupLng != null) {
          markers.add(
            Marker(
              markerId: MarkerId('pickup_${delivery.id}'),
              position: LatLng(delivery.pickupLat!, delivery.pickupLng!),
              icon: isPassengerDelivery
                  ? await MapUtils.createCustomMarker(
                      delivery.isPickedUp ? Icons.check_circle : Icons.home,
                      delivery.isPickedUp ? Colors.green : Colors.orange,
                      baseSize: 45,
                    )
                  : BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange,
                    ),
              infoWindow: InfoWindow(
                title: isPassengerDelivery
                    ? 'Your Pickup'
                    : 'Pickup: ${delivery.passengerName}',
                snippet: delivery.isPickedUp ? 'Completed' : 'Scheduled',
              ),
            ),
          );
        }

        // Dropoff marker
        if (delivery.dropoffLat != null && delivery.dropoffLng != null) {
          markers.add(
            Marker(
              markerId: MarkerId('dropoff_${delivery.id}'),
              position: LatLng(delivery.dropoffLat!, delivery.dropoffLng!),
              icon: isPassengerDelivery
                  ? await MapUtils.createCustomMarker(
                      delivery.isDelivered ? Icons.check_circle : Icons.school,
                      delivery.isDelivered ? Colors.green : Colors.blue,
                      baseSize: 45,
                    )
                  : BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue,
                    ),
              infoWindow: InfoWindow(
                title: isPassengerDelivery
                    ? 'Your Dropoff'
                    : 'Dropoff: ${delivery.passengerName}',
                snippet: delivery.isDelivered ? 'Completed' : 'Scheduled',
              ),
            ),
          );
        }
      }
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

  LatLng _getMapCenter() {
    if (_passengerDelivery?.pickupLat != null &&
        _passengerDelivery?.pickupLng != null) {
      return LatLng(
        _passengerDelivery!.pickupLat!,
        _passengerDelivery!.pickupLng!,
      );
    }
    return const LatLng(9.1450, 38.7428); // Addis Ababa fallback
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<TripDetailBloc, BlocState<dynamic>>(
          listener: (context, state) => _updateMapElements(state),
          builder: (context, state) {
            // Handle loading state
            if (state.isLoading || state.isInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            // Handle error state
            if (state.isError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading trip details',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage ?? 'Unknown error occurred',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _loadTripDetails(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Handle success state
            if (state.isSuccess && state.data != null) {
              final tripDetailData = state.data as TripDetailData;
              final trip = tripDetailData.trip;
              final deliveries = tripDetailData.deliveries ?? [];

              return Column(
                children: [
                  DashboardHeader(
                    title: 'Trip Completed',
                    showBackButton: true,
                    subtitle: DateFormat(
                      'MMM dd, yyyy',
                    ).format(widget.trip.tripDate),
                    actions: [
                      HeaderAction(
                        icon: Icons.refresh,
                        onPressed: _loadTripDetails,
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Map Section
                          Container(
                            height: 300,
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: LiveTrackerMap(
                                initialPosition: _getMapCenter(),
                                markers: _markers,
                                polylines: _polylines,
                                followTarget: false,
                              ),
                            ),
                          ),

                          // Trip Summary Card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Trip Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Route Info
                                if (widget.trip.route != null) ...[
                                  _buildInfoRow(
                                    Icons.route,
                                    'Route',
                                    widget.trip.route!.name,
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Driver Info
                                if (widget.trip.driver != null) ...[
                                  _buildInfoRow(
                                    Icons.person,
                                    'Driver',
                                    widget.trip.driver!.fullName ??
                                        widget.trip.driver!.firstName,
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Vehicle Info
                                if (widget.trip.car != null) ...[
                                  _buildInfoRow(
                                    Icons.directions_car,
                                    'Vehicle',
                                    '${widget.trip.car!.make} ${widget.trip.car!.model}',
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Time Info
                                _buildInfoRow(
                                  Icons.access_time,
                                  'Scheduled Time',
                                  '${widget.trip.scheduledStartTime ?? 'N/A'} - ${widget.trip.scheduledEndTime ?? 'N/A'}',
                                ),
                                const SizedBox(height: 12),

                                // Status
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Completed',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // All Trip Deliveries
                          if (widget.trip.deliveries != null &&
                              widget.trip.deliveries!.isNotEmpty) ...[
                            Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.group,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Your Passengers ',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // List all deliveries
                                  ...widget.trip.deliveries!.map((delivery) {
                                    final isGuardianPassenger =
                                        delivery.passengerId ==
                                        widget.passenger.id;
                                    return isGuardianPassenger
                                        ? Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: isGuardianPassenger
                                                  ? AppTheme.primaryColor
                                                        .withOpacity(0.05)
                                                  : Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isGuardianPassenger
                                                    ? AppTheme.primaryColor
                                                          .withOpacity(0.2)
                                                    : Colors.grey.shade200,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    UserAvatar(
                                                      imageUrl: delivery.passenger?.image,
                                                      name: delivery.passengerName ?? 'Unknown Passenger',
                                                      size: 32,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                delivery.passengerName ??
                                                                    'Unknown Passenger',
                                                                style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      isGuardianPassenger
                                                                      ? FontWeight
                                                                            .bold
                                                                      : FontWeight
                                                                            .w500,
                                                                  color:
                                                                      isGuardianPassenger
                                                                      ? AppTheme
                                                                            .primaryColor
                                                                      : AppTheme
                                                                            .textPrimary,
                                                                ),
                                                              ),
                                                              if (isGuardianPassenger) ...[
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            6,
                                                                        vertical:
                                                                            2,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color: AppTheme
                                                                        .primaryColor,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                  ),
                                                                  child: const Text(
                                                                    'You',
                                                                    style: TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          10,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                          Text(
                                                            'Grade ${delivery.schoolClass ?? 'Unknown'}',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey
                                                                  .shade600,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),

                                                // Pickup Status
                                                _buildDeliveryStatus(
                                                  'Pickup',
                                                  delivery.isPickedUp,
                                                  delivery.actualPickupTime,
                                                  Icons.home,
                                                  Colors.orange,
                                                ),
                                                const SizedBox(height: 12),

                                                // Dropoff Status
                                                _buildDeliveryStatus(
                                                  'Dropoff',
                                                  delivery.isDelivered,
                                                  delivery.actualDropoffTime,
                                                  Icons.school,
                                                  Colors.blue,
                                                ),
                                              ],
                                            ),
                                          )
                                        : SizedBox.shrink();
                                  }).toList(),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 100), // Space for bottom
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // Default return for any other state
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

Widget _buildInfoRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 20, color: Colors.grey.shade600),
      const SizedBox(width: 12),
      Text(
        '$label:',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          textAlign: TextAlign.right,
        ),
      ),
    ],
  );
}

Widget _buildDeliveryStatus(
  String type,
  bool isCompleted,
  DateTime? actualTime,
  IconData icon,
  Color color,
) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isCompleted
              ? Colors.green.withOpacity(0.1)
              : color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isCompleted ? Icons.check_circle : icon,
          color: isCompleted ? Colors.green : color,
          size: 20,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              isCompleted && actualTime != null
                  ? 'Completed at ${DateFormat('hh:mm a').format(actualTime)}'
                  : 'Not completed',
              style: TextStyle(
                fontSize: 12,
                color: isCompleted ? Colors.green : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      if (isCompleted)
        const Icon(Icons.check_circle, color: Colors.green, size: 20),
    ],
  );
}
