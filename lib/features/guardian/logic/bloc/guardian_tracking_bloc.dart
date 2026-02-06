import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'guardian_tracking_event.dart';
import 'guardian_tracking_state.dart';
import '../../../../core/services/trip_service.dart';
import '../../../../core/services/trip_tracking_service.dart';
import '../../../../core/services/icon_cache_service.dart';
import '../../../../core/services/location_manager.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/delivery.dart';
import '../../../../core/utils/map_utils.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class GuardianTrackingBloc extends Bloc<GuardianTrackingEvent, GuardianTrackingState> {
  final TripService _tripService;
  final TripTrackingService _tripTrackingService;
  final IconCacheService _iconCache;
  final LocationManager _locationManager = LocationManager();
  
  StreamSubscription<TripTrackingEvent>? _trackingSubscription;

  GuardianTrackingBloc({
    required TripService tripService,
    required TripTrackingService tripTrackingService,
    required IconCacheService iconCache,
  })  : _tripService = tripService,
        _tripTrackingService = tripTrackingService,
        _iconCache = iconCache,
        super(GuardianTrackingInitial()) {
    on<GuardianTrackingStarted>(_onStarted);
    on<GuardianTrackingLocationUpdated>(_onLocationUpdated);
    on<GuardianTrackingRefreshRequested>(_onRefreshRequested);
  }

  @override
  Future<void> close() {
    _trackingSubscription?.cancel();
    _tripTrackingService.stopTracking();
    return super.close();
  }

  Future<void> _onStarted(GuardianTrackingStarted event, Emitter<GuardianTrackingState> emit) async {
    emit(GuardianTrackingLoading());

    try {
      if (!_iconCache.isReady) {
        await _iconCache.initialize();
      }

      final trip = await _tripService.getTripById(event.trip.id);
      final stops = trip.deliveries ?? [];
      
      Delivery? passengerDelivery;
      try {
        passengerDelivery = stops.firstWhere((s) => s.passengerId == event.passenger.id);
      } catch (_) {}

      final driverPos = trip.driverLocation != null 
          ? LatLng(trip.driverLocation!.latitude, trip.driverLocation!.longitude)
          : const LatLng(0, 0);

      final markers = _generateMarkers(stops, driverPos, event.passenger.id);
      final polylines = _generatePolylines(trip.polyline);

      emit(GuardianTrackingReady(
        trip: trip,
        passenger: event.passenger,
        passengerDelivery: passengerDelivery,
        driverPosition: driverPos,
        bearing: 0.0,
        markers: markers,
        polylines: polylines,
        eta: 'Calculating...',
        distanceLabel: 'Calculating...',
      ));

      // Start Webcasting Tracking
      _tripTrackingService.startTracking(trip.id);
      
      _trackingSubscription?.cancel();
      _trackingSubscription = _tripTrackingService.events.listen((tevent) {
        if (tevent is DriverLocationUpdated) {
          add(GuardianTrackingLocationUpdated(
            driverPosition: tevent.location,
            bearing: tevent.bearing,
          ));
        } else if (tevent is TripStatusUpdated || tevent is DeliveryStatusUpdated) {
          add(GuardianTrackingRefreshRequested());
        }
      });

      // Initial manual refresh to get calculated ETA
      await _refreshData(trip.id, event.passenger.id, emit);
    } catch (e) {
      emit(GuardianTrackingError('Failed to start tracking: $e'));
    }
  }

  Future<void> _onRefreshRequested(GuardianTrackingRefreshRequested event, Emitter<GuardianTrackingState> emit) async {
    if (state is! GuardianTrackingReady) return;
    final currentState = state as GuardianTrackingReady;
    
    try {
      await _refreshData(currentState.trip.id, currentState.passenger.id, emit);
    } catch (e) {
      debugPrint('Refresh failed: $e');
    }
  }

  Future<void> _refreshData(String tripId, String passengerId, Emitter<GuardianTrackingState> emit) async {
    final trip = await _tripService.getTripById(tripId);
    final stops = trip.deliveries ?? [];
    
    Delivery? passengerDelivery;
    try {
      passengerDelivery = stops.firstWhere((s) => s.passengerId == passengerId);
    } catch (_) {}

    final driverPos = trip.driverLocation != null 
        ? LatLng(trip.driverLocation!.latitude, trip.driverLocation!.longitude)
        : const LatLng(0, 0);

    String eta = 'Calculating...';
    String distanceLabel = 'Calculating...';

    if (passengerDelivery != null && trip.driverLocation != null) {
      final stopPos = LatLng(
        passengerDelivery.pickupLocation?.latitude ?? 0,
        passengerDelivery.pickupLocation?.longitude ?? 0,
      );
      
      final distance = _locationManager.calculateDistance(
        trip.driverLocation!.latitude,
        trip.driverLocation!.longitude,
        stopPos.latitude,
        stopPos.longitude,
      );

      distanceLabel = '${(distance / 1000).toStringAsFixed(1)} km';
      final minutes = (distance / (30 * 1000 / 60)).round();
      eta = minutes < 1 ? 'Arriving' : '$minutes min';
    }

    final markers = _generateMarkers(stops, driverPos, passengerId);
    final polylines = _generatePolylines(trip.polyline);

    if (state is GuardianTrackingReady) {
      emit((state as GuardianTrackingReady).copyWith(
        trip: trip,
        passengerDelivery: passengerDelivery,
        driverPosition: driverPos,
        markers: markers,
        polylines: polylines,
        eta: eta,
        distanceLabel: distanceLabel,
      ));
    }
  }

  void _onLocationUpdated(GuardianTrackingLocationUpdated event, Emitter<GuardianTrackingState> emit) {
    if (state is GuardianTrackingReady) {
      final currentState = state as GuardianTrackingReady;
      
      // Recalculate ETA and Distance based on new location
      String eta = currentState.eta;
      String distanceLabel = currentState.distanceLabel;

      if (currentState.passengerDelivery != null) {
        final stopPos = LatLng(
          currentState.passengerDelivery!.pickupLocation?.latitude ?? 0,
          currentState.passengerDelivery!.pickupLocation?.longitude ?? 0,
        );
        
        final distance = _locationManager.calculateDistance(
          event.driverPosition.latitude,
          event.driverPosition.longitude,
          stopPos.latitude,
          stopPos.longitude,
        );

        distanceLabel = '${(distance / 1000).toStringAsFixed(1)} km';
        final minutes = (distance / (30 * 1000 / 60)).round();
        eta = minutes < 1 ? 'Arriving' : '$minutes min';
      }

      emit(currentState.copyWith(
        driverPosition: event.driverPosition,
        bearing: event.bearing,
        eta: eta,
        distanceLabel: distanceLabel,
        markers: _generateMarkers(currentState.trip.deliveries ?? [], event.driverPosition, currentState.passenger.id),
      ));
    }
  }

  Set<Marker> _generateMarkers(List<Delivery> stops, LatLng driverPos, String passengerId) {
    final markers = <Marker>{};
    final icons = _iconCache.icons;

    for (final stop in stops) {
      final isMyPassenger = stop.passengerId == passengerId;
      if (!isMyPassenger && stop.status != 'pending') continue;

      final pos = LatLng(
        stop.pickupLocation?.latitude ?? 0,
        stop.pickupLocation?.longitude ?? 0,
      );

      BitmapDescriptor? icon;
      if (stop.status == 'picked_up' || stop.status == 'dropped_off' || stop.status == 'completed') {
         icon = icons.completed;
      } else {
         icon = stop.type == 'pickup' ? icons.pickup : icons.dropoff;
      }

      markers.add(Marker(
        markerId: MarkerId('stop_${stop.id}'),
        position: pos,
        icon: icon ?? BitmapDescriptor.defaultMarker,
        alpha: isMyPassenger ? 1.0 : 0.5,
        infoWindow: InfoWindow(title: isMyPassenger ? 'Your Child' : 'Bus Stop'),
      ));
    }

    markers.add(Marker(
      markerId: const MarkerId('driver'),
      position: driverPos,
      icon: icons.bus ?? BitmapDescriptor.defaultMarker,
      anchor: Offset(0.5, 0.5),
      zIndex: 100,
    ));

    return markers;
  }

  Set<Polyline> _generatePolylines(String? encodedPolyline) {
    if (encodedPolyline == null || encodedPolyline.isEmpty) return {};
    
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: MapUtils.decodePolyline(encodedPolyline),
        color: AppTheme.primaryColor.withOpacity(0.6),
        width: 4,
      )
    };
  }
}
