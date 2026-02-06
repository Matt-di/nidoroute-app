import 'base_models.dart';

class User extends BaseUser {
  final DateTime? dateOfBirth;
  final String? driverId;
  final String? guardianId;

  const User({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.role,
    super.phone,
    super.gender,
    this.dateOfBirth,
    this.driverId,
    this.guardianId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: _extractRole(json),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      phone: json['phone_number'] as String?,
      driverId: json['driver']?['id'] as String?,
      guardianId: json['guardian']?['id'] as String?,
    );
  }

  static String _extractRole(Map<String, dynamic> json) {
    // Check if roles array exists
    if (json['roles'] != null && json['roles'] is List) {
      final roles = json['roles'] as List;
      if (roles.isNotEmpty) {
        return roles[0]['name'] as String;
      }
    }
    // Fallback to role field if exists
    return json['role'] as String? ?? 'user';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'role': role,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'phone_number': phone,
    };
  }

  @override
  List<Object?> get props => [
    ...super.props,
    dateOfBirth,
    driverId,
    guardianId,
  ];
}
