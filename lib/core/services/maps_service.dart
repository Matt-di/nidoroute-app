import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/app_config.dart';
import '../utils/map_utils.dart';
import '../models/delivery.dart';
import '../../core/utils/map_utils.dart';

class MapsService {
  static final MapsService _instance = MapsService._internal();

  factory MapsService() => _instance;

  late final Dio _dio;
  
  // Add caching for API responses
  final Map<String, GoogleDistanceResult> _distanceCache = {};
  final Map<String, List<GoogleDistanceResult?>> _routeDistanceCache = {};
  static const Duration _cacheTimeout = Duration(minutes: 2); // Cache for 2 minutes

  MapsService._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    
    // Clean cache periodically
    Timer.periodic(const Duration(minutes: 5), (_) => _cleanExpiredCache());
  }

  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  
  static String? get _apiKey {
    try {
      return dotenv.env['GOOGLE_MAPS_API_KEY'];
    } catch (e) {
      return null;
    }
  }

  /// Calculates distance and duration between two points using Distance Matrix API.
  Future<GoogleDistanceResult?> calculateDistance({
    required LatLng origin,
    required LatLng destination,
    TravelMode travelMode = TravelMode.driving,
    TrafficModel trafficModel = TrafficModel.bestGuess,
  }) async {
    // Safety check: Don't call Google API with uninitialized (0,0) coordinates
    if (origin.latitude == 0 && origin.longitude == 0) return null;
    if (destination.latitude == 0 && destination.longitude == 0) return null;

    final apiKey = _apiKey;
    if (apiKey == null) {
      return null;
    }
    
    // Check cache first
    final cacheKey = _generateDistanceCacheKey(origin, destination, travelMode, trafficModel);
    final cachedResult = _distanceCache[cacheKey];
    if (cachedResult != null) {
      return cachedResult;
    }
    
    final url = '$_baseUrl/distancematrix/json';
    final queryParams = {
      'origins': '${origin.latitude},${origin.longitude}',
      'destinations': '${destination.latitude},${destination.longitude}',
      'mode': travelMode.name,
      'traffic_model': trafficModel.name.toLowerCase(),
      'key': apiKey,
    };
    
    try {
      final response = await _dio.get(url, queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['status'] == 'OK' && 
            data['rows'] != null && 
            (data['rows'] as List).isNotEmpty && 
            data['rows'][0]['elements'] != null &&
            (data['rows'][0]['elements'] as List).isNotEmpty) {
          
          final element = data['rows'][0]['elements'][0];
          
          if (element['status'] == 'OK') {
            final result = GoogleDistanceResult.fromJson(element);
            // Cache the result
            _distanceCache[cacheKey] = result;
            return result;
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  String _generateDistanceCacheKey(LatLng origin, LatLng destination, TravelMode travelMode, TrafficModel trafficModel) {
    return '${origin.latitude},${origin.longitude}_${destination.latitude},${destination.longitude}_${travelMode.name}_${trafficModel.name}';
  }

  void _cleanExpiredCache() {
    // Simple cache cleanup - in production you'd want timestamp-based expiration
    if (_distanceCache.length > 100) {
      _distanceCache.clear();
    }
    if (_routeDistanceCache.length > 50) {
      _routeDistanceCache.clear();
    }
  }

  /// Calculates distances for a list of deliveries (batch processing).
  Future<List<GoogleDistanceResult?>> calculateRouteDistance({
    required LatLng origin,
    required List<Delivery> destinations,
    TravelMode travelMode = TravelMode.driving,
    TrafficModel trafficModel = TrafficModel.bestGuess,
  }) async {
    final apiKey = _apiKey;
    if (apiKey == null) {
      return List.filled(destinations.length, null);
    }

    // Safety check: Don't call Google API with uninitialized (0,0) coordinates
    if (origin.latitude == 0 && origin.longitude == 0) {
      return List.filled(destinations.length, null);
    }

    if (destinations.isEmpty) return [];

    final destinationCoords = destinations.map((delivery) {
      final lat = delivery.isPickedUp ? (delivery.dropoffLat ?? 0) : (delivery.pickupLat ?? 0);
      final lng = delivery.isPickedUp ? (delivery.dropoffLng ?? 0) : (delivery.pickupLng ?? 0);
      return lat != 0 && lng != 0 ? '$lat,$lng' : null;
    }).where((coord) => coord != null).cast<String>().toList();

    if (destinationCoords.isEmpty) return List.filled(destinations.length, null);

    final url = '$_baseUrl/distancematrix/json';
    final queryParams = {
      'origins': '${origin.latitude},${origin.longitude}',
      'destinations': destinationCoords.join('|'),
      'mode': travelMode.name,
      'traffic_model': trafficModel.name.toLowerCase(),
      'key': apiKey,
    };
    
    try {
      final response = await _dio.get(url, queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['status'] == 'OK' && 
            data['rows'] != null && 
            (data['rows'] as List).isNotEmpty && 
            data['rows'][0]['elements'] != null) {
          
          final elements = data['rows'][0]['elements'] as List;
          final results = <GoogleDistanceResult?>[];
          
          int destIndex = 0;
          for (var delivery in destinations) {
            final lat = delivery.isPickedUp ? (delivery.dropoffLat ?? 0) : (delivery.pickupLat ?? 0);
            final lng = delivery.isPickedUp ? (delivery.dropoffLng ?? 0) : (delivery.pickupLng ?? 0);
            
            if (lat != 0 && lng != 0 && destIndex < elements.length) {
              final element = elements[destIndex];
              if (element['status'] == 'OK') {
                results.add(GoogleDistanceResult.fromJson(element));
              } else {
                results.add(null);
              }
              destIndex++;
            } else {
              results.add(null);
            }
          }
          
          return results;
        } else {
          return List.filled(destinations.length, null);
        }
      } else {
        return List.filled(destinations.length, null);
      }
    } catch (e) {
      return List.filled(destinations.length, null);
    }
  }

  /// Calculates total distance and duration for a multi-stop route.
  Future<GoogleDistanceResult?> calculateMultiStopRoute({
    required List<LatLng> waypoints,
    TravelMode travelMode = TravelMode.driving,
    TrafficModel trafficModel = TrafficModel.bestGuess,
  }) async {
    if (waypoints.length < 2) return null;

    double totalDistance = 0;
    int totalDuration = 0;

    // Google Distance Matrix API limits the number of elements per request.
    // For a simple multi-stop calculation, we can iterate pairwise or use Directions API.
    // Here we iterate pairwise using calculateDistance for accuracy.
    // Note: Directions API would be more efficient for many stops and provides polylines too.
    
    for (int i = 0; i < waypoints.length - 1; i++) {
      final result = await calculateDistance(
        origin: waypoints[i],
        destination: waypoints[i + 1],
        travelMode: travelMode,
        trafficModel: trafficModel,
      );

      if (result != null) {
        totalDistance += result.distanceMeters;
        totalDuration += result.durationSeconds;
      } else {
        return null; // If any segment fails, return null
      }
    }

    return GoogleDistanceResult(
      distanceMeters: totalDistance.round(),
      distanceText: totalDistance >= 1000 
          ? '${(totalDistance / 1000).toStringAsFixed(1)} km'
          : '${totalDistance.round()} m',
      durationSeconds: totalDuration,
      durationText: _formatDuration(totalDuration),
      status: 'OK',
    );
  }

  // --- Smart/Hybrid Calculation Methods (Consolidated from DistanceETAService) ---

  /// Calculates distance and ETA between two points, automatically falling back to local
  /// calculation if Google API fails or is disabled.
  Future<DistanceETAResult> getSmartDistanceETA({
    required LatLng origin,
    required LatLng destination,
    double? currentSpeed,
    bool useGoogleAPI = true,
  }) async {
    if (origin.latitude == 0 || destination.latitude == 0) {
      return DistanceETAResult.empty();
    }

    if (useGoogleAPI) {
      try {
        final googleResult = await calculateDistance(
          origin: origin,
          destination: destination,
        );

        if (googleResult != null) {
          return DistanceETAResult(
            distance: googleResult.distanceMeters.toDouble(),
            etaMinutes: googleResult.effectiveDurationSeconds / 60.0,
            etaText: _formatGoogleDuration(googleResult.effectiveDurationText),
            distanceText: googleResult.distanceText,
            isArriving: googleResult.effectiveDurationSeconds < 60,
          );
        }
      } catch (e) {
        debugPrint('Google Maps API failed, falling back to local calculation: $e');
      }
    }

    return _calculateLocalDistanceETA(origin, destination, currentSpeed);
  }

  /// Calculates ETA for a multi-stop route.
  Future<List<DistanceETAResult>> getSmartRouteETA({
    required LatLng currentLocation,
    required List<Delivery> deliveries,
    double? currentSpeed,
    bool useGoogleAPI = true,
  }) async {
    if (deliveries.isEmpty) return [];

    if (useGoogleAPI) {
      try {
        final googleResults = await calculateRouteDistance(
          origin: currentLocation,
          destinations: deliveries,
        );

        if (googleResults.isNotEmpty && googleResults.every((r) => r != null)) {
          return googleResults.map((result) {
            return DistanceETAResult(
              distance: result!.distanceMeters.toDouble(),
              etaMinutes: result.effectiveDurationSeconds / 60.0,
              etaText: _formatGoogleDuration(result.effectiveDurationText),
              distanceText: result.distanceText,
              isArriving: result.effectiveDurationSeconds < 60,
            );
          }).toList();
        }
      } catch (e) {
        debugPrint('Google Maps batch API failed, falling back to local calculation: $e');
      }
    }

    return _calculateLocalRouteETA(currentLocation, deliveries, currentSpeed);
  }

  /// Calculates total route distance using the best available method.
  Future<double> getSmartTotalRouteDistance({
    required LatLng currentLocation,
    required List<Delivery> deliveries,
    bool useGoogleAPI = true,
  }) async {
    if (deliveries.isEmpty) return 0;

    if (useGoogleAPI) {
      try {
        final waypoints = <LatLng>[currentLocation];
        final sorted = List<Delivery>.from(deliveries)
          ..sort((a, b) => (a.sequence ?? 0).compareTo(b.sequence ?? 0));

        for (var d in sorted) {
          final lat = d.isPickedUp ? (d.dropoffLat ?? 0) : (d.pickupLat ?? 0);
          final lng = d.isPickedUp ? (d.dropoffLng ?? 0) : (d.pickupLng ?? 0);
          if (lat != 0) waypoints.add(LatLng(lat, lng));
        }

        if (waypoints.length > 1) {
          final result = await calculateMultiStopRoute(waypoints: waypoints);
          if (result != null) return result.distanceMeters.toDouble();
        }
      } catch (e) {
        debugPrint('Google Maps multi-stop API failed, falling back to local calculation: $e');
      }
    }

    return _calculateLocalTotalDistance(currentLocation, deliveries);
  }

  // --- Local Fallback Logic ---

  static const double _averageSpeedKmh = 30.0;
  static const double _walkingSpeedMs = 1.4;
  static const double _trafficFactor = 1.3;

  DistanceETAResult _calculateLocalDistanceETA(
    LatLng start,
    LatLng end,
    double? speed,
  ) {
    final straightLineDistance = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );

    final roadDistance = straightLineDistance * 1.4; // Average road winding factor

    double etaMinutes;
    if (speed != null && speed > 0) {
      etaMinutes = (roadDistance / speed) / 60;
    } else {
      if (roadDistance < 200) {
        etaMinutes = roadDistance / _walkingSpeedMs / 60;
      } else {
        etaMinutes = (roadDistance / 1000) / (_averageSpeedKmh / 60) * _trafficFactor;
      }
    }

    return DistanceETAResult(
      distance: roadDistance,
      etaMinutes: etaMinutes,
      etaText: _formatLocalETA(etaMinutes),
      distanceText: roadDistance >= 1000 
          ? '${(roadDistance / 1000).toStringAsFixed(1)} km'
          : '${roadDistance.round()} m',
      isArriving: etaMinutes < 1,
    );
  }

  List<DistanceETAResult> _calculateLocalRouteETA(
    LatLng current,
    List<Delivery> deliveries,
    double? speed,
  ) {
    final results = <DistanceETAResult>[];
    LatLng prevPos = current;
    double cumulativeTime = 0;

    final sorted = List<Delivery>.from(deliveries)
      ..sort((a, b) => (a.sequence ?? 0).compareTo(b.sequence ?? 0));

    for (var delivery in sorted) {
      final targetLat = delivery.isPickedUp ? (delivery.dropoffLat ?? 0) : (delivery.pickupLat ?? 0);
      final targetLng = delivery.isPickedUp ? (delivery.dropoffLng ?? 0) : (delivery.pickupLng ?? 0);
      
      if (targetLat == 0) {
        results.add(DistanceETAResult.empty());
        continue;
      }

      final nextPos = LatLng(targetLat, targetLng);
      final res = _calculateLocalDistanceETA(prevPos, nextPos, speed);
      
      cumulativeTime += res.etaMinutes;
      results.add(DistanceETAResult(
        distance: res.distance,
        etaMinutes: cumulativeTime,
        etaText: _formatLocalETA(cumulativeTime),
        distanceText: res.distanceText,
        isArriving: cumulativeTime < 1,
      ));
      
      prevPos = nextPos;
    }

    return results;
  }

  double _calculateLocalTotalDistance(LatLng start, List<Delivery> deliveries) {
    double total = 0;
    LatLng current = start;
    final sorted = List<Delivery>.from(deliveries)
      ..sort((a, b) => (a.sequence ?? 0).compareTo(b.sequence ?? 0));

    for (var d in sorted) {
      final lat = d.isPickedUp ? (d.dropoffLat ?? 0) : (d.pickupLat ?? 0);
      final lng = d.isPickedUp ? (d.dropoffLng ?? 0) : (d.pickupLng ?? 0);
      if (lat == 0) continue;
      
      total += Geolocator.distanceBetween(current.latitude, current.longitude, lat, lng) * 1.4;
      current = LatLng(lat, lng);
    }
    return total;
  }

  String _formatLocalETA(double minutes) {
    if (minutes < 1) return 'Arriving';
    if (minutes < 60) return '${minutes.ceil()} min';
    final h = minutes ~/ 60;
    final m = (minutes % 60).ceil();
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  String _formatGoogleDuration(String googleDuration) {
    return googleDuration
        .replaceAll('hours', 'h')
        .replaceAll('hour', 'h')
        .replaceAll('mins', 'min')
        .replaceAll('min', 'min');
  }

  /// Gets polyline points for a route using Directions API.
  Future<List<LatLng>> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
    TravelMode travelMode = TravelMode.driving,
    bool avoidTolls = false,
    bool avoidHighways = false,
  }) async {
    final apiKey = _apiKey;
    if (apiKey == null) return [];

    try {
      final queryParams = <String, String>{
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': travelMode.name,
        'key': apiKey,
      };

      if (avoidTolls) queryParams['avoid'] = 'tolls';
      if (avoidHighways) queryParams['avoid'] = 'highways';

      if (waypoints != null && waypoints.isNotEmpty) {
        final waypointStr = waypoints
            .map((p) => '${p.latitude},${p.longitude}')
            .join('|');
        queryParams['waypoints'] = waypointStr;
      }

      final url = '$_baseUrl/directions/json';
      
      final response = await _dio.get(url, queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final route = routes.first;
            final legs = route['legs'] as List;
            final points = <LatLng>[];
            
            for (var leg in legs) {
              final steps = leg['steps'] as List;
              for (var step in steps) {
                final polyline = step['polyline']['points'] as String;
                final stepPoints = MapUtils.decodePolyline(polyline);
                points.addAll(stepPoints);
              }
            }
            
            return points;
          }
        } else {
          throw Exception('Directions API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
    }
    
    return [];
  }

  static String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).round();
      return '$minutes min';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = ((seconds % 3600) / 60).round();
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }
}

enum TravelMode {
  driving,
  walking,
  bicycling,
  transit,
}

enum TrafficModel {
  bestGuess,
  pessimistic,
  optimistic,
}

class GoogleDistanceResult {
  final int distanceMeters;
  final String distanceText;
  final int durationSeconds;
  final String durationText;
  final String? durationInTrafficSeconds;
  final String? durationInTrafficText;
  final String status;

  const GoogleDistanceResult({
    required this.distanceMeters,
    required this.distanceText,
    required this.durationSeconds,
    required this.durationText,
    this.durationInTrafficSeconds,
    this.durationInTrafficText,
    required this.status,
  });

  factory GoogleDistanceResult.fromJson(Map<String, dynamic> json) {
    return GoogleDistanceResult(
      distanceMeters: json['distance']['value'] as int,
      distanceText: json['distance']['text'] as String,
      durationSeconds: json['duration']['value'] as int,
      durationText: json['duration']['text'] as String,
      durationInTrafficSeconds: json['duration_in_traffic']?['value']?.toString(),
      durationInTrafficText: json['duration_in_traffic']?['text'],
      status: json['status'] as String,
    );
  }

  int get effectiveDurationSeconds {
    if (durationInTrafficSeconds != null) {
      return int.tryParse(durationInTrafficSeconds!) ?? durationSeconds;
    }
    return durationSeconds;
  }

  String get effectiveDurationText {
    return durationInTrafficText ?? durationText;
  }

  @override
  String toString() {
    return 'GoogleDistanceResult(distance: $distanceText, duration: $effectiveDurationText, status: $status)';
  }
}

class DistanceETAResult {
  final double distance; // in meters
  final double etaMinutes; // in minutes
  final String etaText;
  final String distanceText;
  final bool isArriving;

  const DistanceETAResult({
    required this.distance,
    required this.etaMinutes,
    required this.etaText,
    required this.distanceText,
    required this.isArriving,
  });

  factory DistanceETAResult.empty() => const DistanceETAResult(
    distance: 0,
    etaMinutes: 0,
    etaText: 'Unknown',
    distanceText: 'Unknown',
    isArriving: false,
  );

  @override
  String toString() {
    return 'DistanceETAResult(distance: $distance, eta: $etaText, isArriving: $isArriving)';
  }
}
