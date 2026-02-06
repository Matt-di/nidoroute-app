import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../trip/logic/bloc/trip_detail_bloc.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/bloc/trip_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/live_tracker_map.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/passenger.dart';
import '../../../../core/models/delivery.dart';
import '../widgets/location_row.dart';
import '../../../../core/utils/map_utils.dart';
import '../../../../core/repositories/trip_repository.dart';
import '../../../../core/services/trip_tracking_service.dart';
import '../widgets/guardian_status_card.dart';
import '../widgets/journey_status_card.dart';

class GuardianTrackingScreen extends StatelessWidget {
  final Trip trip;
  final Passenger focusPassenger;
  final List<Passenger> allPassengers;

  const GuardianTrackingScreen({
    super.key,
    required this.trip,
    required this.focusPassenger,
    List<Passenger>? allPassengers,
  }) : allPassengers = allPassengers ?? const [];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TripDetailBloc(
        tripRepository: context.read<TripRepository>(),
      )..loadTripDetails(trip.id),
      child: _GuardianTrackingContent(
        trip: trip,
        focusPassenger: focusPassenger,
        allPassengers: allPassengers,
      ),
    );
  }
}

class _GuardianTrackingContent extends StatefulWidget {
  final Trip trip;
  final Passenger focusPassenger;
  final List<Passenger> allPassengers;

  const _GuardianTrackingContent({
    required this.trip,
    required this.focusPassenger,
    required this.allPassengers,
  });

  @override
  State<_GuardianTrackingContent> createState() => _GuardianTrackingContentState();
}

class _GuardianTrackingContentState extends State<_GuardianTrackingContent> {
  StreamSubscription? _trackingSubscription;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _startTracking();
    // Initialize page based on focusPassenger
    final index = widget.allPassengers.indexWhere((p) => p.id == widget.focusPassenger.id);
    if (index != -1) {
      _currentPage = index;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(index);
        }
      });
    }
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTracking() {
    final trackingService = context.read<TripTrackingService>();
    trackingService.startTracking(widget.trip.id);
    
    _trackingSubscription = trackingService.events.listen((event) {
      if (event is DriverLocationUpdated) {
        if (mounted) {
            print('GuardianTrackingScreen: Received DriverLocationUpdated: ${event.location}');
            context.read<TripDetailBloc>().add(TripDriverLocationUpdated(
                latitude: event.location.latitude,
                longitude: event.location.longitude,
            ));
        }
      } else if (event is DeliveryStatusUpdated) {
        if (mounted) {
             print('GuardianTrackingScreen: Received DeliveryStatusUpdated: ${event.deliveryId} -> ${event.status}');
             context.read<TripDetailBloc>().add(TripDeliveryStatusUpdated(
                 deliveryId: event.deliveryId,
                 status: event.status,
                 timestamp: DateTime.now(),
             ));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<TripDetailBloc, BlocState<dynamic>>(
          builder: (context, state) {
            Trip? trip;
            List<Delivery> deliveries = [];
            
            if (state.isSuccess && state.data != null) {
              trip = state.data is TripDetailData ? (state.data as TripDetailData).trip : null;
              deliveries = state.data is TripDetailData ? ((state.data as TripDetailData).deliveries ?? []) : [];
            }

            // Filter allPassengers to only include those that have a delivery on this trip
            final passengersOnTrip = widget.allPassengers.where((p) {
               // Always include focusPassenger to be safe, or just check existence in deliveries
               return p.id == widget.focusPassenger.id || 
                      deliveries.any((d) => d.passengerId == p.id);
            }).toList();

            // Determine active/viewed passenger
            final currentPassenger = passengersOnTrip.isNotEmpty
                ? passengersOnTrip[_currentPage.clamp(0, passengersOnTrip.length - 1)]
                : widget.focusPassenger;

            Delivery? currentDelivery;
             try {
                currentDelivery = deliveries.firstWhere(
                  (d) => d.passengerId == currentPassenger.id
                );
              } catch (e) {
                // Not found
              }

            final String status = currentDelivery?.isDelivered == true
                ? 'Arrived'
                : (currentDelivery?.isPickedUp == true
                      ? 'On Bus'
                      : 'Incoming');

            // --- Map Data Preparation ---
            Set<Marker> markers = {};
            Set<Polyline> polylines = {};
            LatLng initialPosition = const LatLng(9.03, 38.74); 
            LatLng? driverPosition;

            if (trip != null) {
                // 1. Driver Marker
                if (trip.driverLocation != null && trip.driverLocation!.latitude != 0) {
                     driverPosition = LatLng(trip.driverLocation!.latitude, trip.driverLocation!.longitude);
                     markers.add(Marker(
                         markerId: const MarkerId('driver'),
                         position: driverPosition,
                         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                         infoWindow: InfoWindow(title: 'Driver: ${trip.driver?.firstName ?? 'Bus'}'),
                         zIndex: 2,
                     ));
                     initialPosition = driverPosition;
                } else if (trip.startLat != null && trip.startLng != null) {
                     initialPosition = LatLng(trip.startLat!, trip.startLng!);
                }

                // 2. Child Markers (For filtered passengers)
                for (final p in passengersOnTrip) {
                    final d = deliveries.firstWhere((del) => del.passengerId == p.id, orElse: () => Delivery(id: 'dummy', tripId: '', passengerId: '', status: ''));
                    if (d.id == 'dummy') continue;

                    final target = d.targetLocation(trip.tripType);
                    if (target != null) {
                        final isSelected = p.id == currentPassenger.id;
                        markers.add(Marker(
                            markerId: MarkerId('stop_${p.id}'),
                            position: LatLng(target.latitude, target.longitude),
                            icon: BitmapDescriptor.defaultMarkerWithHue(isSelected ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange),
                            infoWindow: InfoWindow(title: '${p.displayName}\'s Stop'),
                           // alpha: isSelected ? 1.0 : 0.6, // Maybe fade out others?
                        ));
                    }
                }

                // 3. Route
                if (trip.polyline != null && trip.polyline!.isNotEmpty) {
                    polylines.add(Polyline(
                        polylineId: const PolylineId('trip_route'),
                        points: MapUtils.decodePolyline(trip.polyline!),
                        color: AppTheme.primaryColor,
                        width: 5,
                    ));
                }
            }

            // --- ETA Calculation ---
             String etaDisplay = '--';
             if (driverPosition != null && currentDelivery != null && !currentDelivery.isDelivered) {
                 LatLng? target;
                 if (currentDelivery.isPickedUp) {
                     final loc = currentPassenger.dropoffLocation;
                     if (loc != null && loc.coordinates != null) {
                         target = LatLng(loc.coordinates!['latitude']!, loc.coordinates!['longitude']!);
                     } else if (trip?.endLocation != null) {
                         target = LatLng(trip!.endLocation!.latitude, trip.endLocation!.longitude);
                     }
                 } else {
                      final loc = currentDelivery.targetLocation(trip?.tripType ?? 'pickup');
                      if (loc != null) target = LatLng(loc.latitude, loc.longitude);
                 }

                 if (target != null) {
                     final double distMeters = MapUtils.calculateDistance(driverPosition, target);
                     final int mins = (distMeters / 400).ceil();
                     if (mins < 1) etaDisplay = '< 1 min';
                     else if (mins > 60) etaDisplay = '> 1 hr';
                     else etaDisplay = '$mins min';
                 }
             }

            return Column(
              children: [
                DashboardHeader(
                  title: 'Trip Tracking',
                  showBackButton: true,
                  subtitle: passengersOnTrip.length > 1 
                      ? '${passengersOnTrip.length} Children'
                      : '${widget.focusPassenger.displayName.split(' ')[0]}\'s Route',
                  actions: [
                    HeaderAction(
                      icon: Icons.refresh,
                      onPressed: () => context.read<TripDetailBloc>().refreshTripDetails(widget.trip.id),
                    ),
                  ],
                ),
                Expanded(
                  child: Stack(
                    children: [
                       // Map widget
                      LiveTrackerMap(
                          initialPosition: initialPosition,
                          markers: markers,
                          polylines: polylines,
                          showUserLocation: true,
                          followTarget: true,
                          targetPosition: driverPosition,
                          zoom: 14,
                      ),

                      // Status Overlay
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: GuardianStatusCard(
                          status: status,
                          eta: etaDisplay,
                          isDelivered: currentDelivery?.isDelivered ?? false,
                          isPickedUp: currentDelivery?.isPickedUp ?? false,
                        ),
                      ),

                      // Child Info Panel (Swipeable for multiple children)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 400, // Increased height
                        child: passengersOnTrip.length > 1
                            ? PageView.builder(
                                controller: _pageController,
                                onPageChanged: (index) {
                                  setState(() => _currentPage = index);
                                },
                                itemCount: passengersOnTrip.length,
                                itemBuilder: (context, index) {
                                  final p = passengersOnTrip[index];
                                  final d = deliveries.firstWhere(
                                      (del) => del.passengerId == p.id,
                                      orElse: () => Delivery(id: 'dummy', tripId: '', passengerId: '', status: ''));
                                  
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: _buildInfoPanel(d.id == 'dummy' ? null : d, p),
                                  );
                                },
                              )
                            : _buildInfoPanel(currentDelivery, currentPassenger),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoPanel(Delivery? passengerDelivery, Passenger currentPassenger) {
    final isDelivered = passengerDelivery?.isDelivered ?? false;
    final isPickedUp = passengerDelivery?.isPickedUp ?? false;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50.withOpacity(0.8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header with Passenger Info and Actions
          Row(
            children: [
              // Passenger Avatar with Gradient
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    currentPassenger.displayName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Passenger Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentPassenger.displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Grade ${currentPassenger.schoolClass?.name ?? 'Unknown'}',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Row(
                children: [
                  // Contact Button
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.phone_outlined,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Emergency Button (only show if not delivered)
                  if (!isDelivered)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red, Colors.red.shade600],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emergency_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Journey Status Cards
          Row(
            children: [
              Expanded(
                child: JourneyStatusCard(
                  title: 'Pickup',
                  isCompleted: isPickedUp,
                  timestamp: passengerDelivery?.actualPickupTime,
                  icon: Icons.home,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: JourneyStatusCard(
                  title: 'Dropoff',
                  isCompleted: isDelivered,
                  timestamp: passengerDelivery?.actualDropoffTime,
                  icon: Icons.school,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Location Details
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                LocationRow(
                  icon: Icons.home_outlined,
                  label: 'Home Pickup',
                  address:
                      currentPassenger.pickupLocation?.address ??
                      'No address set',
                  iconColor: isPickedUp
                      ? AppTheme.warningColor
                      : Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 16),
                LocationRow(
                  icon: Icons.school_outlined,
                  label: 'School Dropoff',
                  address:
                      currentPassenger.dropoffLocation?.address ??
                      'No address set',
                  iconColor: isDelivered
                      ? AppTheme.successColor
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ),

          // Trip Progress Indicator (only show if trip is active)
          if (!isDelivered) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_bus,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bus is ${isPickedUp ? 'heading to school' : 'on the way for pickup'}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}
