import 'base_models.dart';
import 'passenger.dart';

class Delivery extends BaseEntity {
  final String tripId;
  final String passengerId;
  final String status; // 'pending', 'picked_up', 'delivered', 'no_show', 'cancelled'
  final String? type; // 'pickup' or 'dropoff'
  final DateTime? scheduledPickupTime;
  final DateTime? actualPickupTime;
  final DateTime? scheduledDropoffTime;
  final DateTime? actualDropoffTime;
  final LocationCoordinates? pickupLocation;
  final LocationCoordinates? dropoffLocation;
  final String? pickupNotes;
  final String? dropoffNotes;
  final String? specialInstructions;
  final int? sequence;
  final String? passengerName;
  final String? schoolClass;
  final Passenger? passenger;

  const Delivery({
    required super.id,
    required this.tripId,
    required this.passengerId,
    required this.status,
    this.type,
    this.scheduledPickupTime,
    this.actualPickupTime,
    this.scheduledDropoffTime,
    this.actualDropoffTime,
    this.pickupLocation,
    this.dropoffLocation,
    this.pickupNotes,
    this.dropoffNotes,
    this.specialInstructions,
    this.sequence,
    this.passengerName,
    this.schoolClass,
    this.passenger,
    super.createdAt,
    super.updatedAt,
  });

  Delivery copyWith({
    String? id,
    String? tripId,
    String? passengerId,
    String? status,
    String? type,
    DateTime? scheduledPickupTime,
    DateTime? actualPickupTime,
    DateTime? scheduledDropoffTime,
    DateTime? actualDropoffTime,
    LocationCoordinates? pickupLocation,
    LocationCoordinates? dropoffLocation,
    String? pickupNotes,
    String? dropoffNotes,
    String? specialInstructions,
    int? sequence,
    String? passengerName,
    String? schoolClass,
  }) {
    return Delivery(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      passengerId: passengerId ?? this.passengerId,
      status: status ?? this.status,
      type: type ?? this.type,
      scheduledPickupTime: scheduledPickupTime ?? this.scheduledPickupTime,
      actualPickupTime: actualPickupTime ?? this.actualPickupTime,
      scheduledDropoffTime: scheduledDropoffTime ?? this.scheduledDropoffTime,
      actualDropoffTime: actualDropoffTime ?? this.actualDropoffTime,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupNotes: pickupNotes ?? this.pickupNotes,
      dropoffNotes: dropoffNotes ?? this.dropoffNotes,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      sequence: sequence ?? this.sequence,
      passengerName: passengerName ?? this.passengerName,
      schoolClass: schoolClass ?? this.schoolClass,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isPickedUp => status == 'picked_up';
  bool get isDelivered => status == 'delivered';
  bool get isCompleted => status == 'delivered' || status == 'cancelled';

  // Backwards compatibility getters
  double? get pickupLat => pickupLocation?.latitude;
  double? get pickupLng => pickupLocation?.longitude;
  double? get dropoffLat => dropoffLocation?.latitude;
  double? get dropoffLng => dropoffLocation?.longitude;

  LocationCoordinates? targetLocation(String tripType) {
    if (tripType == 'dropoff') {
      return dropoffLocation ?? pickupLocation;
    }
    return pickupLocation;
  }

  factory Delivery.fromJson(Map<String, dynamic> json) {
    // Handle coordinates
    LocationCoordinates? pickupLoc;
    if (json['pickup_lat'] != null && json['pickup_lng'] != null) {
      pickupLoc = LocationCoordinates.fromFlatJson(json, 'pickup_lat', 'pickup_lng');
    } else if (json['pickup_location'] != null) {
      pickupLoc = LocationCoordinates.fromJson(json['pickup_location']);
    }

    LocationCoordinates? dropoffLoc;
    if (json['dropoff_lat'] != null && json['dropoff_lng'] != null) {
      dropoffLoc = LocationCoordinates.fromFlatJson(json, 'dropoff_lat', 'dropoff_lng');
    } else if (json['dropoff_location'] != null) {
      dropoffLoc = LocationCoordinates.fromJson(json['dropoff_location']);
    }

    return Delivery(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      passengerId: json['passenger_id'] as String,
      status: json['status'] as String,
      type: json['type'] as String?,
      scheduledPickupTime: json['scheduled_pickup_time'] != null
          ? DateTime.parse(json['scheduled_pickup_time'] as String)
          : null,
      actualPickupTime: json['actual_pickup_time'] != null
          ? DateTime.parse(json['actual_pickup_time'] as String)
          : null,
      scheduledDropoffTime: json['scheduled_dropoff_time'] != null
          ? DateTime.parse(json['scheduled_dropoff_time'] as String)
          : null,
      actualDropoffTime: json['actual_dropoff_time'] != null
          ? DateTime.parse(json['actual_dropoff_time'] as String)
          : null,
      pickupLocation: pickupLoc,
      dropoffLocation: dropoffLoc,
      pickupNotes: json['pickup_notes'] as String?,
      dropoffNotes: json['dropoff_notes'] as String?,
      specialInstructions: json['special_instructions'] as String?,
      sequence: json['sequence'] as int?,
      passengerName: json['passenger_name'] as String? ?? 
                    json['passenger']?['full_name'] as String?,
      schoolClass: json['passenger']?['school_class']?['name'] as String?,
      passenger: json['passenger'] != null 
          ? Passenger.fromJson(json['passenger'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'passenger_id': passengerId,
      'status': status,
      'type': type,
      'scheduled_pickup_time': scheduledPickupTime?.toIso8601String(),
      'actual_pickup_time': actualPickupTime?.toIso8601String(),
      'scheduled_dropoff_time': scheduledDropoffTime?.toIso8601String(),
      'actual_dropoff_time': actualDropoffTime?.toIso8601String(),
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'pickup_notes': pickupNotes,
      'dropoff_notes': dropoffNotes,
      'special_instructions': specialInstructions,
      'sequence': sequence,
    };
  }

  @override
  List<Object?> get props => [
    ...super.props,
    tripId,
    passengerId,
    status,
  ];
}
