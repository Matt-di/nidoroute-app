import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'reverb_service.dart';
import 'location_manager.dart';
import 'api_service.dart';
import '../config/app_config.dart';

// Events for real-time trip tracking
abstract class TripTrackingEvent {
  final String tripId;
  
  const TripTrackingEvent({required this.tripId});
}

class DriverLocationUpdated extends TripTrackingEvent {
  final LatLng location;
  final double bearing;
  final double speed;
  final DateTime timestamp;

  const DriverLocationUpdated({
    required String tripId,
    required this.location,
    required this.bearing,
    required this.speed,
    required this.timestamp,
  }) : super(tripId: tripId);

  factory DriverLocationUpdated.fromJson(Map<String, dynamic> json) {
    final locationData = json['location'] as Map<String, dynamic>? ?? json;
    return DriverLocationUpdated(
      tripId: json['trip_id']?.toString() ?? '',
      location: LatLng(
        ((locationData['lat'] ?? locationData['latitude']) as num).toDouble(),
        ((locationData['lng'] ?? locationData['longitude']) as num).toDouble(),
      ),
      bearing: (locationData['heading'] ?? locationData['bearing'] as num?)?.toDouble() ?? 0.0,
      speed: (locationData['speed'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

class TripStatusUpdated extends TripTrackingEvent {
  final String status;
  final Map<String, dynamic>? data;

  const TripStatusUpdated({
    required String tripId,
    required this.status,
    this.data,
  }) : super(tripId: tripId);

  factory TripStatusUpdated.fromJson(Map<String, dynamic> json) {
    return TripStatusUpdated(
      tripId: json['trip_id']?.toString() ?? '',
      status: (json['new_status'] ?? json['status']) as String,
      data: json, // Pass entire body as data for flexibility
    );
  }
}

class DeliveryStatusUpdated extends TripTrackingEvent {
  final String deliveryId;
  final String status;
  final Map<String, dynamic>? data;

  const DeliveryStatusUpdated({
    required String tripId,
    required this.deliveryId,
    required this.status,
    this.data,
  }) : super(tripId: tripId);

  factory DeliveryStatusUpdated.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusUpdated(
      tripId: json['trip_id']?.toString() ?? '',
      deliveryId: json['delivery_id']?.toString() ?? '',
      status: (json['new_status'] ?? json['status']) as String,
      data: json,
    );
  }
}

class ProximityAlertTriggered extends TripTrackingEvent {
  final String deliveryId;
  final String deliveryType;
  final double distance;
  final String passengerName;

  const ProximityAlertTriggered({
    required String tripId,
    required this.deliveryId,
    required this.deliveryType,
    required this.distance,
    required this.passengerName,
  }) : super(tripId: tripId);

  factory ProximityAlertTriggered.fromJson(Map<String, dynamic> json) {
    return ProximityAlertTriggered(
      tripId: json['trip_id']?.toString() ?? '',
      deliveryId: json['delivery_id']?.toString() ?? '',
      deliveryType: json['delivery_type'] as String,
      distance: (json['distance'] as num).toDouble(),
      passengerName: json['passenger_name'] as String,
    );
  }
}

class TripTrackingError extends TripTrackingEvent {
  final String message;

  const TripTrackingError({
    required String tripId,
    required this.message,
  }) : super(tripId: tripId);
}

class TripTrackingService {
  static final TripTrackingService _instance = TripTrackingService._internal();
  
  factory TripTrackingService() => _instance;
  TripTrackingService._internal();

  final ReverbService _echoService = ReverbService();
  final LocationManager _locationService = LocationManager();
  
  final StreamController<TripTrackingEvent> _eventController = 
      StreamController<TripTrackingEvent>.broadcast();
  
  String? _currentTripId;
  String? _currentDriverId;
  bool _isTracking = false;

  Stream<TripTrackingEvent> get events => _eventController.stream;
  bool get isTracking => _isTracking;

  void startTracking(String tripId) {
    if (_currentTripId == tripId && _isTracking) {
      return;
    }
    
    stopTracking();
    
    _currentTripId = tripId;
    _isTracking = true;
    
    _listenToTripEvents(tripId);
  }

  void stopTracking() {
    if (!_isTracking) return;
    
    if (_currentTripId != null) {
      _echoService.leave('trip.${_currentTripId}');
    }
    
    _isTracking = false;
    _currentTripId = null;
    _currentDriverId = null;
  }

  void _listenToTripEvents(String tripId) {
    final channelName = 'trip.$tripId';

    try {
      _echoService.private(channelName, SocketEvents.tripLocationUpdated, (data) {
        final event = DriverLocationUpdated.fromJson(Map<String, dynamic>.from(data));
        if (!_eventController.isClosed) {
          _eventController.add(event);
        }
      });

      _echoService.private(channelName, SocketEvents.tripStatusUpdated, (data) {
        final event = TripStatusUpdated.fromJson(Map<String, dynamic>.from(data));
        if (!_eventController.isClosed) {
          _eventController.add(event);
        }
      });

      _echoService.private(channelName, SocketEvents.deliveryStatusUpdated, (data) {
        try {
          final event = DeliveryStatusUpdated.fromJson(Map<String, dynamic>.from(data));
          if (!_eventController.isClosed) {
            _eventController.add(event);
          }
        } catch (_) {}
      });

      _echoService.private(channelName, SocketEvents.routeStatusUpdated, (data) {
      });

    } catch (e) {
      _eventController.add(TripTrackingError(
        message: 'Failed to setup Echo event listeners: $e',
        tripId: tripId,
      ));
    }
  }

  void shutdown() {
    stopTracking();
  }
}
