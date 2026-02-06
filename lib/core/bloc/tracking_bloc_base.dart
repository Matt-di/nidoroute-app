import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'base_bloc.dart';
import 'base_state.dart';
import 'bloc_exceptions.dart';
import '../services/trip_tracking_service.dart';
import '../services/icon_cache_service.dart';
import '../services/location_manager.dart';

/// Base class for tracking-related BLoCs (LiveTripBloc, GuardianTrackingBloc)
abstract class TrackingBlocBase<Event, State extends BlocState> extends BaseBloc<Event, State>
    with BlocMixin<Event, State> {
  final TripTrackingService _tripTrackingService;
  final IconCacheService _iconCache;
  final LocationManager _locationManager;
  
  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<dynamic>? _trackingSubscription;

  TrackingBlocBase({
    required TripTrackingService tripTrackingService,
    required IconCacheService iconCache,
    required LocationManager locationManager,
    required State initialState,
  })  : _tripTrackingService = tripTrackingService,
        _iconCache = iconCache,
        _locationManager = locationManager,
        super(initialState);

  /// Initialize tracking for a trip
  Future<void> initializeTracking({
    required String tripId,
    required String? passengerId,
  }) async {
    await executeWithLoading<void>(
      operation: () async {
        // Initialize icon cache if not ready
        if (!_iconCache.isReady) {
          await _iconCache.initialize();
        }
        
        // Start tracking
        _tripTrackingService.startTracking(tripId);
        
        // Set up subscriptions
        _setupTrackingSubscriptions(tripId, passengerId);
        
        return;
      },
      onSuccess: (_) {
        // Handle successful initialization
      },
      onError: (error) {
        // Handle initialization error
      },
    );
  }

  /// Set up tracking subscriptions
  void _setupTrackingSubscriptions(String tripId, String? passengerId) {
    // Location subscription
    _locationSubscription = _locationManager.locationStream.listen(
      (locationData) {
        onLocationUpdated(locationData);
      },
      onError: (error) {
        onLocationError(error);
      },
    );

    // Trip tracking subscription
    _trackingSubscription = _tripTrackingService.events.listen(
      (trackingEvent) {
        onTrackingEvent(trackingEvent);
      },
      onError: (error) {
        onTrackingError(error);
      },
    );
  }

  /// Stop tracking
  Future<void> stopTracking() async {
    await executeSilent<void>(
      operation: () async {
        await _locationSubscription?.cancel();
        await _trackingSubscription?.cancel();
        _tripTrackingService.stopTracking();
        _locationSubscription = null;
        _trackingSubscription = null;
        return;
      },
      onSuccess: (_) {
        // Handle successful stop
      },
    );
  }

  /// Update trip location
  Future<void> updateLocation(String tripId, double latitude, double longitude) async {
    await executeSilent<void>(
      operation: () async {
        // Note: TripTrackingService doesn't have updateLocation method
        // This would need to be implemented in the service
        // For now, we'll use the location manager directly
        return;
      },
      onSuccess: (_) {
        // Handle successful update
      },
    );
  }

  /// Get current location
  Future<LocationData?> getCurrentLocation() async {
    try {
      return await _locationManager.getCurrentLocation();
    } catch (e) {
      throw LocationBlocException(
        message: 'Failed to get current location',
        originalError: e,
      );
    }
  }

  /// Abstract methods to be implemented by concrete BLoCs
  void onLocationUpdated(LocationData locationData);
  void onLocationError(dynamic error);
  void onTrackingEvent(dynamic trackingEvent);
  void onTrackingError(dynamic error);

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _trackingSubscription?.cancel();
    _tripTrackingService.stopTracking();
    return super.close();
  }
}

/// Location-specific exception
class LocationBlocException extends BlocException {
  const LocationBlocException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}

/// Tracking-specific exception
class TrackingBlocException extends BlocException {
  const TrackingBlocException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}
