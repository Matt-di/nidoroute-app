import 'package:equatable/equatable.dart';
import 'base_models.dart';
import 'route.dart' as model;
import 'delivery.dart';
import 'car.dart';

class Trip extends BaseEntity {
  final String? routeId;
  final String? driverId;
  final String? carId;

  final DateTime tripDate;
  final String tripType;
  final String status;

  final String? scheduledStartTime;
  final String? scheduledEndTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;

  final LocationCoordinates? startLocation;
  final LocationCoordinates? endLocation;
  final LocationCoordinates? driverLocation;

  final TripMetrics metrics;
  final TripProgress? progress;

  final String? polyline;
  final String? notes;

  // Nested
  final model.Route? route;
  final TripDriver? driver;
  final Car? car;
  final List<Delivery>? deliveries;
  final TripNextDelivery? nextDelivery;

  const Trip({
    required super.id,
    this.routeId,
    this.driverId,
    this.carId,
    required this.tripDate,
    required this.tripType,
    required this.status,
    this.scheduledStartTime,
    this.scheduledEndTime,
    this.actualStartTime,
    this.actualEndTime,
    this.startLocation,
    this.endLocation,
    this.driverLocation,
    required this.metrics,
    this.progress,
    this.polyline,
    this.notes,
    super.createdAt,
    super.updatedAt,
    this.route,
    this.driver,
    this.car,
    this.deliveries,
    this.nextDelivery,
  });

  /* ===================== DERIVED ===================== */

  bool get isActive => status == 'scheduled' || status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';

  double? get startLat => startLocation?.latitude;
  double? get startLng => startLocation?.longitude;
  double? get endLat => endLocation?.latitude;
  double? get endLng => endLocation?.longitude;
  double? get driverLat => driverLocation?.latitude;
  double? get driverLng => driverLocation?.longitude;

  /* ===================== COPY ===================== */

  Trip copyWith({
    String? status,
    LocationCoordinates? driverLocation,
    List<Delivery>? deliveries,
    TripProgress? progress,
    TripMetrics? metrics,
    String? polyline,
    TripNextDelivery? nextDelivery,
  }) {
    return Trip(
      id: id,
      routeId: routeId,
      driverId: driverId,
      carId: carId,
      tripDate: tripDate,
      tripType: tripType,
      status: status ?? this.status,
      scheduledStartTime: scheduledStartTime,
      scheduledEndTime: scheduledEndTime,
      actualStartTime: actualStartTime,
      actualEndTime: actualEndTime,
      startLocation: startLocation,
      endLocation: endLocation,
      driverLocation: driverLocation ?? this.driverLocation,
      metrics: metrics ?? this.metrics,
      progress: progress ?? this.progress,
      polyline: polyline ?? this.polyline,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      route: route,
      driver: driver,
      car: car,
      deliveries: deliveries ?? this.deliveries,
      nextDelivery: nextDelivery ?? this.nextDelivery,
    );
  }

  /* ===================== JSON ===================== */

  factory Trip.fromJson(Map<String, dynamic> json) {
    LocationCoordinates? _parseLocation(
      Map<String, dynamic> json,
      String key,
      String flatLat,
      String flatLng,
    ) {
      if (json[key] != null) {
        return LocationCoordinates.fromJson(json[key]);
      }
      if (json[flatLat] != null && json[flatLng] != null) {
        return LocationCoordinates.fromFlatJson(json, flatLat, flatLng);
      }
      return null;
    }

    return Trip(
      id: json['id'],
      routeId: json['route_id'],
      driverId: json['driver_id'],
      carId: json['car_id'],
      tripDate: DateTime.parse(json['trip_date']),
      tripType: json['trip_type'] ?? 'pickup',
      status: json['status'],
      scheduledStartTime: json['scheduled_start_time'],
      scheduledEndTime: json['scheduled_end_time'],
      actualStartTime: DateTime.tryParse(json['actual_start_time'] ?? ''),
      actualEndTime: DateTime.tryParse(json['actual_end_time'] ?? ''),
      startLocation: _parseLocation(
        json,
        'start_location',
        'start_lat',
        'start_lng',
      ),
      endLocation: _parseLocation(json, 'end_location', 'end_lat', 'end_lng'),
      driverLocation: json['driver_location'] != null
          ? LocationCoordinates.fromJson(json['driver_location'])
          : json['current_location'] != null
          ? LocationCoordinates.fromJson(json['current_location'])
          : json['last_known_location'] != null
          ? LocationCoordinates.fromJson(json['last_known_location'])
          : null,
      metrics: json['metrics'] != null
          ? TripMetrics.fromJson(json['metrics'])
          : TripMetrics.fromMainJson(json),
      progress: json['progress'] != null
          ? TripProgress.fromJson(json['progress'])
          : null,
      polyline: json['polyline'],
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? ''),
      route: json['route'] != null ? model.Route.fromJson(json['route']) : null,
      driver: json['driver'] != null
          ? TripDriver.fromJson(json['driver'])
          : null,
      car: json['car'] != null ? Car.fromJson(json['car']) : null,
      deliveries: (json['deliveries'] as List?)
          ?.map((e) => Delivery.fromJson(e))
          .toList(),
      nextDelivery: json['next_delivery'] != null
          ? TripNextDelivery.fromJson(json['next_delivery'])
          : null,
    );
  }

  /* ===================== EQUATABLE ===================== */

  @override
  List<Object?> get props => [
    ...super.props,
    status,
    tripDate,
    routeId,
    driverId,
    driverLocation,
    deliveries,
    progress,
    metrics,
    polyline,
  ];
}

class TripMetrics extends Equatable {
  final int plannedPassengers;
  final int actualPassengers;
  final double plannedDistance;
  final double actualDistance;
  final int plannedDuration;
  final int actualDuration;

  const TripMetrics({
    this.plannedPassengers = 0,
    this.actualPassengers = 0,
    this.plannedDistance = 0,
    this.actualDistance = 0,
    this.plannedDuration = 0,
    this.actualDuration = 0,
  });

  factory TripMetrics.fromJson(Map<String, dynamic> json) {
    return TripMetrics(
      plannedPassengers: json['planned_passengers'] as int? ?? 0,
      actualPassengers: json['actual_passengers'] as int? ?? 0,
      plannedDistance:
          double.tryParse(json['planned_distance']?.toString() ?? '0') ?? 0,
      actualDistance:
          double.tryParse(json['actual_distance']?.toString() ?? '0') ?? 0,
      plannedDuration: json['planned_duration'] as int? ?? 0,
      actualDuration: json['actual_duration'] as int? ?? 0,
    );
  }

  factory TripMetrics.fromMainJson(Map<String, dynamic> json) {
    return TripMetrics(
      plannedPassengers: json['planned_passengers'] as int? ?? 0,
      actualPassengers: json['actual_passengers'] as int? ?? 0,
      plannedDistance:
          double.tryParse(json['planned_distance']?.toString() ?? '0') ?? 0,
      actualDistance:
          double.tryParse(json['actual_distance']?.toString() ?? '0') ?? 0,
      plannedDuration: json['planned_duration'] as int? ?? 0,
      actualDuration: json['actual_duration'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    plannedPassengers,
    actualPassengers,
    plannedDistance,
    actualDistance,
  ];
}

class TripProgress extends Equatable {
  final int totalDeliveries;
  final int completedDeliveries;
  final int pendingDeliveries;
  final double percentageComplete;

  const TripProgress({
    this.totalDeliveries = 0,
    this.completedDeliveries = 0,
    this.pendingDeliveries = 0,
    this.percentageComplete = 0,
  });

  factory TripProgress.fromJson(Map<String, dynamic> json) {
    return TripProgress(
      totalDeliveries: json['total_deliveries'] as int? ?? 0,
      completedDeliveries: json['completed_deliveries'] as int? ?? 0,
      pendingDeliveries: json['pending_deliveries'] as int? ?? 0,
      percentageComplete:
          double.tryParse(json['percentage_complete']?.toString() ?? '0') ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    totalDeliveries,
    completedDeliveries,
    percentageComplete,
  ];
}

class TripDriver extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? fullName;
  final String? phone;
  final String? avatar;
  final TripDriverUser? user;

  const TripDriver({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.fullName,
    this.phone,
    this.avatar,
    this.user,
  });

  factory TripDriver.fromJson(Map<String, dynamic> json) {
    return TripDriver(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      user: json['user'] != null ? TripDriverUser.fromJson(json['user']) : null,
    );
  }

  @override
  List<Object?> get props => [id, firstName, lastName, fullName, phone, avatar, user];
}

class TripDriverUser extends Equatable {
  final String id;
  final String email;

  const TripDriverUser({required this.id, required this.email});

  factory TripDriverUser.fromJson(Map<String, dynamic> json) {
    return TripDriverUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, email];
}

class TripNextDelivery extends Equatable {
  final String id;
  final String passengerName;
  final int sequence;
  final DateTime? scheduledPickup;
  final double? pickupLat;
  final double? pickupLng;

  const TripNextDelivery({
    required this.id,
    required this.passengerName,
    required this.sequence,
    this.scheduledPickup,
    this.pickupLat,
    this.pickupLng,
  });

  factory TripNextDelivery.fromJson(Map<String, dynamic> json) {
    return TripNextDelivery(
      id: json['id'] as String,
      passengerName:
          json['passenger_name'] as String? ??
          json['passenger']?['full_name'] as String? ??
          'Unknown',
      sequence: json['sequence'] as int? ?? 0,
      scheduledPickup: json['scheduled_pickup'] != null
          ? DateTime.tryParse(json['scheduled_pickup'] as String)
          : json['scheduled_pickup_time'] != null
          ? DateTime.tryParse(json['scheduled_pickup_time'] as String)
          : null,
      pickupLat: json['pickup_location']?['latitude'] != null
          ? double.tryParse(json['pickup_location']['latitude'].toString())
          : null,
      pickupLng: json['pickup_location']?['longitude'] != null
          ? double.tryParse(json['pickup_location']['longitude'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [id, passengerName, sequence];
}
