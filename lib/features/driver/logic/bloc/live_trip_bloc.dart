import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'live_trip_event.dart';
import 'live_trip_state.dart';
import '../../../../core/repositories/trip_repository.dart';
import '../../../../core/services/trip_tracking_service.dart';
import '../../../../core/services/icon_cache_service.dart';
import '../../../../core/services/location_manager.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/delivery.dart';
import '../../../../core/utils/map_utils.dart';

class LiveTripBloc extends Bloc<LiveTripEvent, LiveTripState> {
  final TripRepository _tripRepository;
  final TripTrackingService _tripTrackingService;
  final LocationManager _locationManager;
  final IconCacheService _iconCache;

  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<TripTrackingEvent>? _trackingSubscription;

  LiveTripBloc({
    required TripRepository tripRepository,
    required TripTrackingService tripTrackingService,
    required LocationManager locationManager,
    required IconCacheService iconCache,
  })  : _tripRepository = tripRepository,
        _tripTrackingService = tripTrackingService,
        _locationManager = locationManager,
        _iconCache = iconCache,
        super(LiveTripInitial()) {
    on<LiveTripStarted>(_onStarted);
    on<LiveTripLocationUpdated>(_onLocationUpdated);
    on<LiveTripStartRequested>(_onStartRequested);
    on<LiveTripStopArrivalRequested>(_onStopArrivalRequested);
    on<LiveTripPickupRequested>(_onPickupRequested);
    on<LiveTripDropoffRequested>(_onDropoffRequested);
    on<LiveTripNoShowRequested>(_onNoShowRequested);
    on<LiveTripCompleteRequested>(_onCompleteRequested);
    on<LiveTripDeliveryStatusUpdated>(_onDeliveryStatusUpdated);
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _trackingSubscription?.cancel();
    _tripTrackingService.stopTracking();
    return super.close();
  }

  Future<void> _onStarted(LiveTripStarted event, Emitter<LiveTripState> emit) async {
    emit(LiveTripLoading());

    try {
      if (!_iconCache.isReady) {
        await _iconCache.initialize();
      }

      final trip = event.trip;
      final stops = trip.deliveries ?? [];
      
      final markers = _generateMarkers(stops, null, trip.tripType);
      final polylines = _generatePolylines(trip.polyline);

      final currentLocation = await _locationManager.getCurrentLocation();
      final initialPosition = currentLocation != null 
          ? LatLng(currentLocation.latitude, currentLocation.longitude)
          : const LatLng(0, 0);

      emit(LiveTripReady(
        trip: trip,
        currentPosition: initialPosition,
        bearing: currentLocation?.heading ?? 0.0,
        stops: stops,
        markers: markers,
        polylines: polylines,
      ));

      _tripTrackingService.startTracking(trip.id);
      
      _trackingSubscription?.cancel();
      _trackingSubscription = _tripTrackingService.events.listen((tevent) {
        if (tevent is DeliveryStatusUpdated) {
          add(LiveTripDeliveryStatusUpdated(
            deliveryId: tevent.deliveryId,
            status: tevent.status,
          ));
        }
      });

      _locationSubscription?.cancel();
      _locationSubscription = _locationManager.locationStream.listen((data) {
        add(LiveTripLocationUpdated(
          position: LatLng(data.latitude, data.longitude),
          bearing: data.heading ?? 0.0,
        ));
        
        _tripRepository.updateLocation(trip.driverId ?? '', data.latitude, data.longitude);
      });
      
    } catch (e) {
      emit(LiveTripError('Failed to initialize trip: $e'));
    }
  }

  void _onLocationUpdated(LiveTripLocationUpdated event, Emitter<LiveTripState> emit) {
    if (state is LiveTripReady) {
      final currentState = state as LiveTripReady;
      final updatedMarkers = _generateMarkers(currentState.stops, event.position, currentState.trip.tripType);

      emit(currentState.copyWith(
        currentPosition: event.position,
        bearing: event.bearing,
        markers: updatedMarkers,
      ));
    }
  }

  Future<void> _onStartRequested(LiveTripStartRequested event, Emitter<LiveTripState> emit) async {
    if (state is! LiveTripReady) return;
    final currentState = state as LiveTripReady;
    emit(currentState.copyWith(isSubmitting: true));

    try {
      final updatedTrip = await _tripRepository.startTrip(currentState.trip.id);
      emit(currentState.copyWith(
        trip: updatedTrip,
        isSubmitting: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        errorMessage: 'Failed to start trip: $e',
        isSubmitting: false,
      ));
    }
  }

  Future<void> _onStopArrivalRequested(LiveTripStopArrivalRequested event, Emitter<LiveTripState> emit) async {
  }

  Future<void> _onPickupRequested(LiveTripPickupRequested event, Emitter<LiveTripState> emit) async {
    if (state is! LiveTripReady) return;
    final currentState = state as LiveTripReady;
    emit(currentState.copyWith(isSubmitting: true));

    try {
      final updatedDelivery = await _tripRepository.markAsPickedUp(event.stop.id);
      final updatedStops = currentState.stops.map((s) => s.id == updatedDelivery.id ? updatedDelivery : s).toList();
      
      emit(currentState.copyWith(
        stops: updatedStops,
        markers: _generateMarkers(updatedStops, currentState.currentPosition, currentState.trip.tripType),
        isSubmitting: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        errorMessage: 'Failed to pick up: $e',
        isSubmitting: false,
      ));
    }
  }

  Future<void> _onDropoffRequested(LiveTripDropoffRequested event, Emitter<LiveTripState> emit) async {
    if (state is! LiveTripReady) return;
    final currentState = state as LiveTripReady;
    emit(currentState.copyWith(isSubmitting: true));

    try {
      final updatedDelivery = await _tripRepository.markAsDelivered(event.stop.id);
      final updatedStops = currentState.stops.map((s) => s.id == updatedDelivery.id ? updatedDelivery : s).toList();
      
      emit(currentState.copyWith(
        stops: updatedStops,
        markers: _generateMarkers(updatedStops, currentState.currentPosition, currentState.trip.tripType),
        isSubmitting: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        errorMessage: 'Failed to drop off: $e',
        isSubmitting: false,
      ));
    }
  }

  Future<void> _onNoShowRequested(LiveTripNoShowRequested event, Emitter<LiveTripState> emit) async {
    if (state is! LiveTripReady) return;
    final currentState = state as LiveTripReady;
    emit(currentState.copyWith(isSubmitting: true));

    try {
      final updatedDelivery = await _tripRepository.markAsNoShow(event.stop.id);
      final updatedStops = currentState.stops.map((s) => s.id == updatedDelivery.id ? updatedDelivery : s).toList();
      
      emit(currentState.copyWith(
        stops: updatedStops,
        markers: _generateMarkers(updatedStops, currentState.currentPosition, currentState.trip.tripType),
        isSubmitting: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        errorMessage: 'Failed to mark no-show: $e',
        isSubmitting: false,
      ));
    }
  }

  Future<void> _onCompleteRequested(LiveTripCompleteRequested event, Emitter<LiveTripState> emit) async {
    if (state is! LiveTripReady) return;
    final currentState = state as LiveTripReady;
    emit(currentState.copyWith(isSubmitting: true));

    try {
      await _tripRepository.completeTrip(currentState.trip.id);
      emit(LiveTripCompleted());
    } catch (e) {
      emit(currentState.copyWith(
        errorMessage: 'Failed to complete trip: $e',
        isSubmitting: false,
      ));
    }
  }

  void _onDeliveryStatusUpdated(LiveTripDeliveryStatusUpdated event, Emitter<LiveTripState> emit) {
    if (state is! LiveTripReady) return;
    final currentState = state as LiveTripReady;

    final index = currentState.stops.indexWhere((s) => s.id == event.deliveryId);
    if (index != -1) {
      final updatedStops = List<Delivery>.from(currentState.stops);
      updatedStops[index] = updatedStops[index].copyWith(status: event.status);

      emit(currentState.copyWith(
        stops: updatedStops,
        markers: _generateMarkers(updatedStops, currentState.currentPosition, currentState.trip.tripType),
      ));
    }
  }

  Set<Marker> _generateMarkers(List<Delivery> stops, LatLng? driverPos, String tripType) {
    final markers = <Marker>{};
    final icons = _iconCache.icons;

    for (final stop in stops) {
      final targetLoc = stop.targetLocation(tripType);
      final pos = LatLng(
        targetLoc?.latitude ?? 0,
        targetLoc?.longitude ?? 0,
      );

      BitmapDescriptor? icon;
      if (stop.status == 'picked_up' || stop.status == 'dropped_off' || stop.status == 'completed') {
         icon = icons.completed;
      } else {
         // Show pickup icon if it's a morning trip, or dropoff icon if it's an afternoon trip
         icon = tripType == 'pickup' ? icons.pickup : icons.dropoff;
      }

      markers.add(Marker(
        markerId: MarkerId('stop_${stop.id}'),
        position: pos,
        icon: icon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: stop.passengerName),
      ));
    }

    if (driverPos != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: driverPos,
        icon: icons.bus ?? BitmapDescriptor.defaultMarker,
        anchor: Offset(0.5, 0.5),
        zIndex: 100,
      ));
    }

    return markers;
  }

  Set<Polyline> _generatePolylines(String? encodedPolyline) {
    if (encodedPolyline == null || encodedPolyline.isEmpty) return {};
    
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: MapUtils.decodePolyline(encodedPolyline),
        color: Color(0xFF2196F3),
        width: 5,
      )
    };
  }
}
