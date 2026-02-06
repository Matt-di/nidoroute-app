import 'package:equatable/equatable.dart';
import 'base_models.dart';

class Route extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? startAddress;
  final String? endAddress;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final int? estimatedDuration;
  final RouteDriver? driver;
  final RouteCar? car;
  final List<RouteStop>? stops;
  final List<LocationCoordinates>? coordinates;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Route({
    required this.id,
    required this.name,
    this.description,
    this.startAddress,
    this.endAddress,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.estimatedDuration,
    this.driver,
    this.car,
    this.stops,
    this.coordinates,
    this.createdAt,
    this.updatedAt,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed Route',
      description: json['description'] as String?,
      startAddress: json['start_address'] as String?,
      endAddress: json['end_address'] as String?,
      startLat: json['start_location']?['lat'] != null ? double.tryParse(json['start_location']['lat'].toString()) : null,
      startLng: json['start_location']?['lng'] != null ? double.tryParse(json['start_location']['lng'].toString()) : null,
      endLat: json['end_location']?['lat'] != null ? double.tryParse(json['end_location']['lat'].toString()) : null,
      endLng: json['end_location']?['lng'] != null ? double.tryParse(json['end_location']['lng'].toString()) : null,
      estimatedDuration: json['estimated_duration'] != null ? int.tryParse(json['estimated_duration'].toString()) : null,
      driver: json['driver'] != null ? RouteDriver.fromJson(json['driver']) : null,
      car: json['car'] != null ? RouteCar.fromJson(json['car']) : null,
      stops: json['stops'] != null
          ? (json['stops'] as List)
              .map((e) => RouteStop.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      coordinates: json['coordinates'] != null
          ? (json['coordinates'] as List)
              .map((e) => LocationCoordinates.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  @override
  List<Object?> get props => [id, name, startAddress, endAddress];
}

class RouteDriver extends Equatable {
  final String id;
  final RouteDriverUser? user;

  const RouteDriver({
    required this.id,
    this.user,
  });

  factory RouteDriver.fromJson(Map<String, dynamic> json) {
    return RouteDriver(
      id: json['id'] as String,
      user: json['user'] != null ? RouteDriverUser.fromJson(json['user']) : null,
    );
  }

  @override
  List<Object?> get props => [id, user];
}

class RouteDriverUser extends Equatable {
  final String id;
  final String name;

  const RouteDriverUser({
    required this.id,
    required this.name,
  });

  factory RouteDriverUser.fromJson(Map<String, dynamic> json) {
    return RouteDriverUser(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unknown Driver',
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class RouteCar extends Equatable {
  final String id;
  final String model;
  final String plateNumber;

  const RouteCar({
    required this.id,
    required this.model,
    required this.plateNumber,
  });

  factory RouteCar.fromJson(Map<String, dynamic> json) {
    return RouteCar(
      id: json['id'] as String,
      model: json['model'] as String? ?? 'Unknown Model',
      plateNumber: json['plate_number'] as String? ?? 'Unknown',
    );
  }

  @override
  List<Object?> get props => [id, model, plateNumber];
}

class RouteStop extends Equatable {
  final String id;
  final RouteStopPassenger? passenger;
  final double lat;
  final double lng;
  final DateTime? stopTime;
  final String status;

  const RouteStop({
    required this.id,
    this.passenger,
    required this.lat,
    required this.lng,
    this.stopTime,
    required this.status,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: json['id'] as String,
      passenger: json['passenger'] != null ? RouteStopPassenger.fromJson(json['passenger']) : null,
      lat: double.parse(json['location']['lat'].toString()),
      lng: double.parse(json['location']['lng'].toString()),
      stopTime: json['stop_time'] != null ? DateTime.parse(json['stop_time']) : null,
      status: json['status'] as String? ?? 'pending',
    );
  }

  @override
  List<Object?> get props => [id, passenger, lat, lng, stopTime, status];
}

class RouteStopPassenger extends Equatable {
  final String id;
  final String name;

  const RouteStopPassenger({
    required this.id,
    required this.name,
  });

  factory RouteStopPassenger.fromJson(Map<String, dynamic> json) {
    return RouteStopPassenger(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unknown Passenger',
    );
  }

  @override
  List<Object?> get props => [id, name];
}
