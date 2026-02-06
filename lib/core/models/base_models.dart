import 'package:equatable/equatable.dart';

abstract class BaseEntity extends Equatable {
  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BaseEntity({
    required this.id,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, createdAt, updatedAt];
}

class BaseUser extends BaseEntity {
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;
  final String? gender;

  const BaseUser({
    required super.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.phone,
    this.isActive = true,
    this.gender,
    super.createdAt,
    super.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
    ...super.props,
    firstName,
    lastName,
    email,
    role,
    phone,
    isActive,
    gender,
  ];
}

class LocationCoordinates extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;

  const LocationCoordinates({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory LocationCoordinates.fromJson(Map<String, dynamic> json) {
    return LocationCoordinates(
      latitude: double.tryParse(json['latitude']?.toString() ?? json['lat']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? json['lng']?.toString() ?? '') ?? 0,
      address: json['address'] as String?,
    );
  }

  // Helper to parse from flat fields (e.g. start_lat, start_lng)
  factory LocationCoordinates.fromFlatJson(Map<String, dynamic> json, String latKey, String lngKey, {String? addressKey}) {
    return LocationCoordinates(
      latitude: double.tryParse(json[latKey]?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json[lngKey]?.toString() ?? '') ?? 0,
      address: addressKey != null ? json[addressKey] as String? : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    if (address != null) 'address': address,
  };

  @override
  List<Object?> get props => [latitude, longitude, address];
}
