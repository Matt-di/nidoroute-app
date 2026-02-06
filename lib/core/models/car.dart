import 'package:equatable/equatable.dart';

class Car extends Equatable {
  final String id;
  final String make;
  final String model;
  final String plateNumber;
  final int capacity;
  final int? year;
  final String? color;
  final bool isActive;

  const Car({
    required this.id,
    required this.make,
    required this.model,
    required this.plateNumber,
    required this.capacity,
    this.year,
    this.color,
    this.isActive = true,
  });

  String get displayName => '$make $model ($plateNumber)';

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as String,
      make: json['make'] as String? ?? 'Unknown',
      model: json['model'] as String? ?? 'Unknown',
      plateNumber: json['plate_number'] as String? ?? 'Unknown',
      capacity: json['capacity'] != null ? int.tryParse(json['capacity'].toString()) ?? 0 : 0,
      year: json['year'] != null ? int.tryParse(json['year'].toString()) : null,
      color: json['color'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, make, model, plateNumber, capacity, year, color, isActive];
}
