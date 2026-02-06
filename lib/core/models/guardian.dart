import 'package:equatable/equatable.dart';
import 'base_models.dart';

class Guardian extends BaseEntity {
  final String userId;
  final GuardianUser user;
  final String? phone;
  final String? address;
  final String? emergencyContact;
  final String? relationship;
  final int? passengersCount;
  final List<GuardianPassenger>? passengers;

  const Guardian({
    required super.id,
    required this.userId,
    required this.user,
    this.phone,
    this.address,
    this.emergencyContact,
    this.relationship,
    this.passengersCount,
    this.passengers,
    super.createdAt,
    super.updatedAt,
  });

  String get fullName => user.fullName;
  String get email => user.email;
  bool get isActive => user.isActive;

  factory Guardian.fromJson(Map<String, dynamic> json) {
    return Guardian(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      user: GuardianUser.fromJson(json['user']),
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      relationship: json['relationship'] as String?,
      passengersCount: json['passengers_count'] != null ? int.tryParse(json['passengers_count'].toString()) : null,
      passengers: json['passengers'] != null
          ? (json['passengers'] as List)
              .map((e) => GuardianPassenger.fromJson(e as Map<String, dynamic>))
              .toList()
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
      'user_id': userId,
      'phone': phone,
      'address': address,
      'emergency_contact': emergencyContact,
      'relationship': relationship,
    };
  }

  @override
  List<Object?> get props => [
    ...super.props,
    userId,
    user,
    passengers,
  ];
}

class GuardianUser extends BaseUser {
  const GuardianUser({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    super.phone,
    required super.isActive,
    super.role = 'guardian',
    super.createdAt,
    super.updatedAt,
  });

  factory GuardianUser.fromJson(Map<String, dynamic> json) {
    return GuardianUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }
}

class GuardianPassenger extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? fullName;
  final String? gender;
  final bool isActive;

  const GuardianPassenger({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.fullName,
    this.gender,
    required this.isActive,
  });

  String get displayName => fullName ?? '$firstName $lastName';

  factory GuardianPassenger.fromJson(Map<String, dynamic> json) {
    return GuardianPassenger(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullName: json['full_name'] as String?,
      gender: json['gender'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, firstName, lastName, fullName, gender, isActive];
}
