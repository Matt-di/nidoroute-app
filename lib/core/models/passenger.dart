import 'package:equatable/equatable.dart';

class Passenger extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? fullName;
  final DateTime? dateOfBirth;
  final int? age;
  final String? gender;
  final bool isActive;
  final String? image;
  final String? phone;
  final String? emergencyContact;
  final String? medicalConditions;
  final String? specialNeeds;
  final PassengerLocation? pickupLocation;
  final PassengerLocation? dropoffLocation;
  final PassengerGuardian? guardian;
  final PassengerSchoolClass? schoolClass;
  final PassengerRouteStop? currentRouteStop;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Passenger({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.fullName,
    this.dateOfBirth,
    this.age,
    this.gender,
    required this.isActive,
    this.image,
    this.phone,
    this.emergencyContact,
    this.medicalConditions,
    this.specialNeeds,
    this.pickupLocation,
    this.dropoffLocation,
    this.guardian,
    this.schoolClass,
    this.currentRouteStop,
    this.createdAt,
    this.updatedAt,
  });

  String get displayName => fullName ?? '$firstName $lastName';

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullName: json['full_name'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
      gender: json['gender'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      image: json['image'] as String?,
      phone: json['phone'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      medicalConditions: json['medical_conditions'] as String?,
      specialNeeds: json['special_needs'] as String?,
      pickupLocation: json['pickup_location'] != null
          ? PassengerLocation.fromJson(json['pickup_location'])
          : null,
      dropoffLocation: json['dropoff_location'] != null
          ? PassengerLocation.fromJson(json['dropoff_location'])
          : null,
      guardian: json['guardian'] != null
          ? PassengerGuardian.fromJson(json['guardian'])
          : null,
      schoolClass: json['school_class'] != null
          ? PassengerSchoolClass.fromJson(json['school_class'])
          : null,
      currentRouteStop: json['current_route_stop'] != null
          ? PassengerRouteStop.fromJson(json['current_route_stop'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'phone': phone,
      'emergency_contact': emergencyContact,
      'medical_conditions': medicalConditions,
      'special_needs': specialNeeds,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [id, firstName, lastName];
}

class PassengerLocation extends Equatable {
  final String? address;
  final Map<String, double>? coordinates;
  final String? landmark;
  final String? instructions;

  const PassengerLocation({
    this.address,
    this.coordinates,
    this.landmark,
    this.instructions,
  });

  factory PassengerLocation.fromJson(Map<String, dynamic> json) {
    return PassengerLocation(
      address: json['address'] as String?,
      coordinates: json['coordinates'] != null
          ? {
              'latitude': double.parse(json['coordinates']['latitude'].toString()),
              'longitude': double.parse(json['coordinates']['longitude'].toString()),
            }
          : null,
      landmark: json['landmark'] as String?,
      instructions: json['instructions'] as String?,
    );
  }

  @override
  List<Object?> get props => [address, coordinates, landmark, instructions];
}

class PassengerGuardian extends Equatable {
  final String id;
  final PassengerGuardianUser? user;

  const PassengerGuardian({
    required this.id,
    this.user,
  });

  factory PassengerGuardian.fromJson(Map<String, dynamic> json) {
    return PassengerGuardian(
      id: json['id'] as String,
      user: json['user'] != null
          ? PassengerGuardianUser.fromJson(json['user'])
          : null,
    );
  }

  @override
  List<Object?> get props => [id, user];
}

class PassengerGuardianUser extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;

  const PassengerGuardianUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
  });

  factory PassengerGuardianUser.fromJson(Map<String, dynamic> json) {
    return PassengerGuardianUser(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [id, firstName, lastName, email, phone];
}

class PassengerSchoolClass extends Equatable {
  final String id;
  final String name;
  final int? year;
  final String? school;

  const PassengerSchoolClass({
    required this.id,
    required this.name,
    this.year,
    this.school,
  });

  factory PassengerSchoolClass.fromJson(Map<String, dynamic> json) {
    return PassengerSchoolClass(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unknown',
      year: json['year'] != null ? int.tryParse(json['year'].toString()) : null,
      school: json['school'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, year, school];
}

class PassengerRouteStop extends Equatable {
  final String id;
  final String? routeId;
  final String status;
  final DateTime? stopTime;

  const PassengerRouteStop({
    required this.id,
    this.routeId,
    required this.status,
    this.stopTime,
  });

  factory PassengerRouteStop.fromJson(Map<String, dynamic> json) {
    return PassengerRouteStop(
      id: json['id'] as String,
      routeId: json['route_id'] as String?,
      status: json['status'] as String? ?? 'pending',
      stopTime: json['stop_time'] != null
          ? DateTime.parse(json['stop_time'])
          : null,
    );
  }

  @override
  List<Object?> get props => [id, routeId, status, stopTime];
}
