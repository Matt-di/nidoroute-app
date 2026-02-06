import 'package:equatable/equatable.dart';
import 'base_models.dart';
import 'car.dart';

class Driver extends BaseEntity {
  final DriverUser user;
  final String licenseNumber;
  final String phone;
  final bool isActive;
  final String? avatar;
  final List<Car>? cars;
  final DriverCurrentRoute? currentRoute;

  const Driver({
    required super.id,
    required this.user,
    required this.licenseNumber,
    required this.phone,
    required this.isActive,
    this.avatar,
    this.cars,
    this.currentRoute,
    super.createdAt,
    super.updatedAt,
  });

  String get fullName => user.fullName;
  String get email => user.email;

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      user: DriverUser.fromJson(json['user']),
      licenseNumber: json['license_number'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      avatar: json['avatar'] as String?,
      cars: json['cars'] != null
          ? (json['cars'] as List)
              .map((e) => Car.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      currentRoute: json['current_route'] != null
          ? DriverCurrentRoute.fromJson(json['current_route'])
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
      'license_number': licenseNumber,
      'phone': phone,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
    ...super.props,
    user,
    licenseNumber,
    phone,
    isActive,
    avatar,
  ];
}

class DriverUser extends BaseUser {
  final DateTime? dateOfBirth;

  const DriverUser({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    this.dateOfBirth,
    super.gender,
    super.role = 'driver',
  });

  factory DriverUser.fromJson(Map<String, dynamic> json) {
    return DriverUser(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'])
          : null,
      gender: json['gender'] as String?,
    );
  }

  @override
  List<Object?> get props => [...super.props, dateOfBirth];
}

class DriverCurrentRoute extends Equatable {
  final String id;
  final String name;
  final String status;
  final DateTime? startTime;

  const DriverCurrentRoute({
    required this.id,
    required this.name,
    required this.status,
    this.startTime,
  });

  factory DriverCurrentRoute.fromJson(Map<String, dynamic> json) {
    return DriverCurrentRoute(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'])
          : null,
    );
  }

  @override
  List<Object?> get props => [id, name, status, startTime];
}
