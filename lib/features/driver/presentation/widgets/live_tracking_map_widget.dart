import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../trip/logic/bloc/trip_detail_bloc.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/bloc/trip_bloc.dart';
import '../../../../core/services/location_manager.dart';
import '../../../../core/services/icon_cache_service.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/utils/map_utils.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/delivery.dart';

class LiveTrackingMapWidget extends StatefulWidget {
  const LiveTrackingMapWidget({super.key});

  @override
  State<LiveTrackingMapWidget> createState() => _LiveTrackingMapWidgetState();
}

class _LiveTrackingMapWidgetState extends State<LiveTrackingMapWidget> {
  final LocationManager _locationManager = LocationManager();
  final IconCacheService _iconCache = IconCacheService();
  
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  double _currentBearing = 0.0;
  bool _iconsLoaded = false;
  bool _routeFetchAttempted = false;
  int? _lastDeliveryHash;
  bool _isNavigatingToStart = false;
  StreamSubscription<LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeIcons();
    _listenToLocation();
  }

  Future<void> _initializeIcons() async {
    if (!_iconCache.isReady) {
      await _iconCache.initialize();
    }
    if (mounted) {
      setState(() {
        _iconsLoaded = true;
      });
    }
  }

  Future<void> _listenToLocation() async {
    final hasPermission = await _locationManager.initialize();
    if (!hasPermission) {
      debugPrint('Location permission not granted');
      return;
    }

    _locationSubscription = _locationManager.locationStream.listen((locationData) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(locationData.latitude, locationData.longitude);
          _currentBearing = locationData.heading ?? 0.0;
        });
        
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentPosition!,
              zoom: 15,
              bearing: _currentBearing,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_iconsLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return BlocConsumer<TripDetailBloc, BlocState<dynamic>>(
      listener: (context, state) {
        if (state.isSuccess && state.data != null) {
          final tripDetailData = state.data as TripDetailData;
          final trip = tripDetailData.trip;
          final deliveries = tripDetailData.deliveries ?? [];
             
          // Calculate delivery hash to detect changes (completed stops, etc.)
          final currentDeliveryHash = deliveries.map((d) => '${d.id}_${d.status}').join().hashCode;
          
          // Update route if not attempted yet OR if deliveries changed
          if (!_routeFetchAttempted || currentDeliveryHash != _lastDeliveryHash) {
              _lastDeliveryHash = currentDeliveryHash;
              _updateRoute(trip, deliveries);
          }
             
             // Ensure location tracking is active if trip is in progress
             if (trip.status == 'in_progress' && trip.driverId != null) {
                _locationManager.startTracking(
                  driverId: trip.driverId!, 
                  tripId: trip.id
                );
             }
        }
      },
      builder: (context, state) {
        Set<Marker> markers = {};
        Set<Polyline> polylines = {};
        LatLng? initialPosition = _currentPosition;

        if (state.isSuccess && state.data != null) {
          final tripDetailData = state.data as TripDetailData;
          final trip = tripDetailData.trip;
          final deliveries = tripDetailData.deliveries ?? [];

          // Generate markers for deliveries
          for (final delivery in deliveries) {
            final targetLoc = delivery.targetLocation(trip.tripType);
            if (targetLoc == null) continue;

            final pos = LatLng(targetLoc.latitude, targetLoc.longitude);
            BitmapDescriptor? icon;
            
            if (delivery.status == 'picked_up' || delivery.status == 'dropped_off' || delivery.status == 'completed') {
              icon = _iconCache.icons.completed;
            } else {
              icon = trip.tripType == 'pickup' ? _iconCache.icons.pickup : _iconCache.icons.dropoff;
            }

            markers.add(Marker(
              markerId: MarkerId('delivery_${delivery.id}'),
              position: pos,
              icon: icon ?? BitmapDescriptor.defaultMarker,
              infoWindow: InfoWindow(title: delivery.passengerName ?? 'Passenger'),
            ));
          }

          // Add driver marker
          if (_currentPosition != null) {
            markers.add(Marker(
              markerId: const MarkerId('driver'),
              position: _currentPosition!,
              icon: _iconCache.icons.bus ?? BitmapDescriptor.defaultMarker,
              anchor: Offset(0.5, 0.5),
              zIndex: 100,
            ));
          }

          // Add Trip Start Marker
          if (trip.startLat != null && trip.startLng != null && (trip.startLat != 0 || trip.startLng != 0)) {
             markers.add(Marker(
               markerId: const MarkerId('trip_start'),
               position: LatLng(trip.startLat!, trip.startLng!),
               icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
               infoWindow: const InfoWindow(title: 'Start Location'),
             ));
          }

          // Add Trip End Marker
          if (trip.endLat != null && trip.endLng != null && (trip.endLat != 0 || trip.endLng != 0)) {
             markers.add(Marker(
               markerId: const MarkerId('trip_end'),
               position: LatLng(trip.endLat!, trip.endLng!),
               icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
               infoWindow: const InfoWindow(title: 'End Location'),
             ));
          }

          // Generate polylines
          if (trip.polyline != null && trip.polyline!.isNotEmpty) {
            polylines.add(Polyline(
              polylineId: const PolylineId('route'),
              points: MapUtils.decodePolyline(trip.polyline!),
              color: Color(0xFF2196F3),
              width: 5,
            ));
          }

          // Set initial position: Trip Start > Current > First Delivery
          if (trip.startLat != null && trip.startLng != null && (trip.startLat != 0 || trip.startLng != 0)) {
             initialPosition = LatLng(trip.startLat!, trip.startLng!);
          } else if (initialPosition == null && deliveries.isNotEmpty) {
            final firstLoc = deliveries.first.targetLocation(trip.tripType);
            if (firstLoc != null) {
              initialPosition = LatLng(firstLoc.latitude, firstLoc.longitude);
            }
          }
        }

        // Use a default position (Addis Ababa center) if nothing else is available
        initialPosition ??= const LatLng(9.03, 38.74); // Fallback to avoid (0,0) in Atlantic


        // Check proximity for Navigation Button
        bool showNavButton = false;
        LatLng? navTarget;
        
        if (state.isSuccess && state.data != null) {
          final tripDetailData = state.data as TripDetailData;
          final trip = tripDetailData.trip;
          final deliveries = tripDetailData.deliveries ?? [];
          
          if (trip.startLat != null && trip.startLng != null && (trip.startLat != 0 || trip.startLng != 0)) {
            navTarget = LatLng(trip.startLat!, trip.startLng!);
          } else if (deliveries.isNotEmpty) {
            final firstLoc = deliveries.first.targetLocation(trip.tripType);
            if (firstLoc != null) {
              navTarget = LatLng(firstLoc.latitude, firstLoc.longitude);
                }
              }
        }

        if (_currentPosition != null && navTarget != null && !_isNavigatingToStart) {
             final dist = MapUtils.calculateDistance(_currentPosition!, navTarget);
             // Show if > 500 meters
             showNavButton = dist > 500;
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 15,
                bearing: _currentBearing,
              ),
              markers: markers,
              polylines: _routePolylines.union(polylines),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              compassEnabled: true,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
            if (showNavButton && _currentPosition != null && navTarget != null)
               Positioned(
                   bottom: 100, // Above bottom sheet
                   right: 16,
                   child: FloatingActionButton.extended(
                       onPressed: () => _navigateToStart(_currentPosition!, navTarget!),
                       label: const Text('Navigate to Start'),
                       icon: const Icon(Icons.navigation),
                       backgroundColor: Colors.green,
                   ),
               ),
            if (_isNavigatingToStart)
               Positioned(
                   top: 50, // Below header
                   right: 16,
                   child: FloatingActionButton.small(
                       onPressed: () {
                           // Cancel Navigation and Restore Full Route
                           setState(() {
                               _isNavigatingToStart = false;
                               _routePolylines = {}; // Clear nav route
                               // Trigger full route re-fetch
                               _routeFetchAttempted = false; 
                               _lastDeliveryHash = null; // Force update
                           });
                           
                           // Use the current state data to immediately re-fetch
                           if (state.isSuccess && state.data != null) {
                             final tripDetailData = state.data as TripDetailData;
                             final trip = tripDetailData.trip;
                             final deliveries = tripDetailData.deliveries ?? [];
                             _updateRoute(trip, deliveries);
                           }
                       },
                       backgroundColor: Colors.red,
                       child: const Icon(Icons.close),
                   ),
               ),
          ],
        );
      },
    );
  }

  Set<Polyline> _routePolylines = {};
  
  @override
  void didUpdateWidget(LiveTrackingMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger route update if needed when widget updates
  }

  Future<void> _updateRoute(Trip trip, List<Delivery> deliveries) async {
    _routeFetchAttempted = true; // Mark as attempted to prevent loops
    
    // Sort all deliveries by sequence (if available, or assumption) to ensure correct order
    final sortedDeliveries = List<Delivery>.from(deliveries)
      ..sort((a, b) => (a.sequence ?? 0).compareTo(b.sequence ?? 0));
        
    // Limit waypoints to avoid API limits (Google Maps allows 25 waypoints)
    // We prioritize the first 23 stops to ensure we fit in the limit (Origin + Dest + 23 = 25)
    final waypoints = <LatLng>[];
    for (var i = 0; i < sortedDeliveries.length && i < 23; i++) {
        final loc = sortedDeliveries[i].targetLocation(trip.tripType);
        if (loc != null && (loc.latitude != 0 || loc.longitude != 0)) {
            waypoints.add(LatLng(loc.latitude, loc.longitude));
        }
    }

    // Determine Origin: Trip Start (if valid) > First Delivery > Current Position
    LatLng? origin;
    if (trip.startLat != null && trip.startLng != null && (trip.startLat != 0 || trip.startLng != 0)) {
        origin = LatLng(trip.startLat!, trip.startLng!);
    } else if (waypoints.isNotEmpty) {
        origin = waypoints.first;
         // If we use the first waypoint as origin, we should remove it from waypoints to avoid duplication
         waypoints.removeAt(0);
        debugPrint('Trip Start invalid or (0,0), using First Delivery as Origin');
    } else {
        origin = _currentPosition;
    }

    // Determine Destination: Trip End (if valid) > Last Delivery
    LatLng? destination;
    if (trip.endLat != null && trip.endLng != null && (trip.endLat != 0 || trip.endLng != 0)) {
        destination = LatLng(trip.endLat!, trip.endLng!);
    } else if (waypoints.isNotEmpty) {
        destination = waypoints.last;
        waypoints.removeLast();
        debugPrint('Trip End invalid or (0,0), using Last Delivery as Destination');
    }
    
    // If still no destination and we have an origin, maybe using only origin is enough? No, need 2 points.
    
    if (origin == null || destination == null) {
        debugPrint('Cannot update route: Origin or Destination is null/invalid.');
        return;
    }
    
    // Validate coordinates are not 0,0 (Double check)
    if ((origin.latitude == 0 && origin.longitude == 0) || 
        (destination.latitude == 0 && destination.longitude == 0)) {
         debugPrint('Cannot update route: Origin or Destination is (0,0)');
         return;
    }

    debugPrint('Updating Route: Origin(${origin.latitude}, ${origin.longitude}) -> Dest(${destination.latitude}, ${destination.longitude}) with ${waypoints.length} waypoints');

    try {
        final points = await MapsService().getDirections(
            origin: origin,
            destination: destination,
            waypoints: waypoints,
        );

        if (mounted && points.isNotEmpty) {
            setState(() {
                _routePolylines = {
                    Polyline(
                        polylineId: const PolylineId('live_route'),
                        points: points,
                        color: Colors.blue,
                        width: 5,
                        jointType: JointType.round,
                        startCap: Cap.roundCap,
                        endCap: Cap.roundCap,
                    ),
                };
            });
            // Fit bounds to show the whole route
            _fitToRoute(points);
        } else {
             debugPrint('Directions API returned empty points');
        }
    } catch (e) {
        debugPrint('Error updating route: $e');
    }
  }

  void _fitToRoute(List<LatLng> points) {
     if (points.isEmpty || _mapController == null) return;

     double minLat = points.first.latitude;
     double maxLat = points.first.latitude;
     double minLng = points.first.longitude;
     double maxLng = points.first.longitude;

     for (var p in points) {
       if (p.latitude < minLat) minLat = p.latitude;
       if (p.latitude > maxLat) maxLat = p.latitude;
       if (p.longitude < minLng) minLng = p.longitude;
       if (p.longitude > maxLng) maxLng = p.longitude;
     }

     _mapController!.animateCamera(
       CameraUpdate.newLatLngBounds(
         LatLngBounds(
           southwest: LatLng(minLat, minLng),
           northeast: LatLng(maxLat, maxLng),
         ),
         50, // padding
       ),
     );
  }

  Future<void> _navigateToStart(LatLng currentPos, LatLng targetPos) async {
      setState(() {
          _isNavigatingToStart = true;
      });
      
      try {
          // Fetch direct route
          final points = await MapsService().getDirections(
              origin: currentPos,
              destination: targetPos,
              waypoints: [], // Direct route
          );
          
          if (mounted && points.isNotEmpty) {
              setState(() {
                  _routePolylines = { // Replace existing route with nav route
                      Polyline(
                          polylineId: const PolylineId('nav_route'),
                          points: points,
                          color: Colors.green, // Different color for navigation
                          width: 6,
                          jointType: JointType.round,
                          startCap: Cap.roundCap,
                          endCap: Cap.roundCap,
                      ),
                  };
              });
              _fitToRoute(points);
          }
      } catch (e) {
          debugPrint('Error navigating to start: $e');
          setState(() {
              _isNavigatingToStart = false; // Revert on error
          });
      }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
