import 'package:flutter/material.dart';

class Incident {
  final String id;
  final String tripId;
  final String type;
  final String description;
  final double? lat;
  final double? lng;
  final DateTime reportedAt;
  final String severity;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Incident({
    required this.id,
    required this.tripId,
    required this.type,
    required this.description,
    this.lat,
    this.lng,
    required this.reportedAt,
    this.severity = 'medium',
    this.resolvedAt,
    this.resolvedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as String? ?? '',
      tripId: json['trip_id'] as String? ?? '',
      type: json['type'] as String? ?? 'other',
      description: json['description'] as String? ?? '',
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
      reportedAt: json['reported_at'] != null 
          ? DateTime.parse(json['reported_at'].toString()) 
          : DateTime.now(),
      severity: json['severity'] as String? ?? 'medium',
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.parse(json['resolved_at'].toString()) 
          : null,
      resolvedBy: json['resolved_by'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'type': type,
      'description': description,
      'lat': lat,
      'lng': lng,
      'reported_at': reportedAt.toIso8601String(),
      'severity': severity,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Incident copyWith({
    String? id,
    String? tripId,
    String? type,
    String? description,
    double? lat,
    double? lng,
    DateTime? reportedAt,
    String? severity,
    DateTime? resolvedAt,
    String? resolvedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Incident(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      type: type ?? this.type,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      reportedAt: reportedAt ?? this.reportedAt,
      severity: severity ?? this.severity,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isResolved => resolvedAt != null;
  bool get isUnresolved => resolvedAt == null;
  bool get isCritical => severity == 'critical';
  bool get isHigh => severity == 'high';
  bool get isMedium => severity == 'medium';
  bool get isLow => severity == 'low';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Incident && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Incident(id: $id, type: $type, severity: $severity, resolved: $isResolved)';
  }
}

class IncidentType {
  static const String accident = 'accident';
  static const String breakdown = 'breakdown';
  static const String delay = 'delay';
  static const String medical = 'medical';
  static const String behavior = 'behavior';
  static const String weather = 'weather';
  static const String road = 'road';
  static const String other = 'other';

  static List<String> get allTypes => [
    accident,
    breakdown,
    delay,
    medical,
    behavior,
    weather,
    road,
    other,
  ];

  static String getDisplayName(String type) {
    switch (type) {
      case accident:
        return 'Accident';
      case breakdown:
        return 'Vehicle Breakdown';
      case delay:
        return 'Delay';
      case medical:
        return 'Medical Emergency';
      case behavior:
        return 'Behavior Issue';
      case weather:
        return 'Weather Issue';
      case road:
        return 'Road Condition';
      case other:
        return 'Other';
      default:
        return type;
    }
  }

  static IconData getIcon(String type) {
    switch (type) {
      case accident:
        return Icons.car_crash;
      case breakdown:
        return Icons.build;
      case delay:
        return Icons.schedule;
      case medical:
        return Icons.medical_services;
      case behavior:
        return Icons.person_off;
      case weather:
        return Icons.thunderstorm;
      case road:
        return Icons.add_road;
      case other:
        return Icons.report_problem;
      default:
        return Icons.report_problem;
    }
  }

  static Color getColor(String type) {
    switch (type) {
      case accident:
        return Colors.red;
      case breakdown:
        return Colors.orange;
      case delay:
        return Colors.amber;
      case medical:
        return Colors.red;
      case behavior:
        return Colors.purple;
      case weather:
        return Colors.blue;
      case road:
        return Colors.brown;
      case other:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class IncidentSeverity {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';

  static List<String> get allSeverities => [
    low,
    medium,
    high,
    critical,
  ];

  static String getDisplayName(String severity) {
    switch (severity) {
      case low:
        return 'Low';
      case medium:
        return 'Medium';
      case high:
        return 'High';
      case critical:
        return 'Critical';
      default:
        return severity;
    }
  }

  static Color getColor(String severity) {
    switch (severity) {
      case low:
        return Colors.green;
      case medium:
        return Colors.amber;
      case high:
        return Colors.orange;
      case critical:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static int getWeight(String severity) {
    switch (severity) {
      case low:
        return 1;
      case medium:
        return 2;
      case high:
        return 3;
      case critical:
        return 4;
      default:
        return 2;
    }
  }
}
