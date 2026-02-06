import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'speed': speed,
    'heading': heading,
    'accuracy': accuracy,
    'timestamp': timestamp.toIso8601String(),
  };

  factory LocationData.fromPosition(Position position) {
    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed,
      heading: position.heading,
      accuracy: position.accuracy,
      timestamp: position.timestamp ?? DateTime.now(),
    );
  }
}

class LocationManager {
  static final LocationManager _instance = LocationManager._internal();
  factory LocationManager() => _instance;
  LocationManager._internal();

  final ApiService _apiService = ApiService();

  // Settings for location tracking
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Update every 10 meters
  );

  StreamSubscription<Position>? _locationSubscription;
  Timer? _locationUpdateTimer;

  final StreamController<LocationData> _locationController = StreamController<LocationData>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  Stream<LocationData> get locationStream => _locationController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool _isTracking = false;
  String? _driverId;
  String? _tripId;
  LocationData? _lastSentLocation;

  // Configuration
  static const int updateIntervalSeconds = 10;
  static const double minimumDistanceFilter = 10.0; // meters

  bool get isTracking => _isTracking;

  Future<bool> initialize() async {
    try {
      // Request background location permission for continuous tracking
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorController.add('Location permission denied');
          return false;
        }
      }

      // For Android 10+, we need background permission for background tracking
      if (permission == LocationPermission.whileInUse) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _errorController.add('Location permission permanently denied. Please enable in settings.');
        return false;
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorController.add('Location services are disabled. Please enable GPS.');
        return false;
      }

      return true;
    } catch (e) {
      _errorController.add('Failed to initialize location services: $e');
      return false;
    }
  }

  Future<void> startTracking({
    required String driverId,
    String? tripId,
  }) async {
    if (_isTracking) {
      // Update IDs if changed
      _driverId = driverId;
      _tripId = tripId;
      return;
    }

    _driverId = driverId;
    _tripId = tripId;

    try {
      // Start location stream
      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: minimumDistanceFilter.toInt(),
      );

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onLocationUpdate,
        onError: (error) {
          _errorController.add('Location stream error: $error');
        },
      );

      // Also start periodic updates as backup
      _locationUpdateTimer = Timer.periodic(
        Duration(seconds: updateIntervalSeconds),
        (_) => _sendPeriodicUpdate(),
      );

      _isTracking = true;
      debugPrint('Location tracking started for driver: $driverId');
    } catch (e) {
      _errorController.add('Failed to start location tracking: $e');
    }
  }

  Future<void> stopTracking() async {
    _isTracking = false;

    _locationSubscription?.cancel();
    _locationSubscription = null;

    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;

    debugPrint('Location tracking stopped');
  }

  void _onLocationUpdate(Position position) {
    final locationData = LocationData.fromPosition(position);
    _locationController.add(locationData);

    // Send to backend via HTTP
    _sendLocationUpdate(locationData);
  }

  Future<void> _sendLocationUpdate(LocationData locationData) async {
    try {
      // Skip if location is same as last sent
      if (_lastSentLocation != null && 
          _lastSentLocation!.latitude == locationData.latitude && 
          _lastSentLocation!.longitude == locationData.longitude) {
        return;
      }

      final endpoint = AppConfig.driverLocationEndpoint.replaceAll('{driver}', _driverId!);
      await _apiService.post(
        endpoint,
        data: {
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
          'speed': (locationData.speed != null && locationData.speed! >= 0) ? locationData.speed : 0.0,
          'heading': (locationData.heading != null && locationData.heading! >= 0 && locationData.heading! <= 360) ? locationData.heading : 0.0,
          'accuracy': (locationData.accuracy != null && locationData.accuracy! >= 0) ? locationData.accuracy : 0.0,
        },
      );
      _lastSentLocation = locationData;
    } catch (e) {
      // Don't emit error for individual location updates
      debugPrint('Location update failed: $e');
    }
  }

  Future<void> _sendPeriodicUpdate() async {
    if (!_isTracking) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final locationData = LocationData.fromPosition(position);
      _locationController.add(locationData);
      await _sendLocationUpdate(locationData);
    } catch (e) {
      debugPrint('Periodic location update failed: $e');
    }
  }

  Future<LocationData?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LocationData.fromPosition(position);
    } catch (e) {
      _errorController.add('Failed to get current location: $e');
      return null;
    }
  }

  // Raw stream for UI or one-off listeners
  Stream<Position> getRawLocationStream() {
    return Geolocator.getPositionStream(locationSettings: _locationSettings);
  }

  // Calculate distance between two points in meters
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // Calculate bearing between two points
  double calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
  }

  // Open app settings for permission
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  void shutdown() {
    stopTracking();
    _locationController.close();
    _errorController.close();
  }
}
