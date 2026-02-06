import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/passenger.dart';

abstract class GuardianTrackingEvent extends Equatable {
  const GuardianTrackingEvent();

  @override
  List<Object?> get props => [];
}

class GuardianTrackingStarted extends GuardianTrackingEvent {
  final Trip trip;
  final Passenger passenger;

  const GuardianTrackingStarted({required this.trip, required this.passenger});

  @override
  List<Object?> get props => [trip, passenger];
}

class GuardianTrackingLocationUpdated extends GuardianTrackingEvent {
  final LatLng driverPosition;
  final double bearing;
  final String? eta;
  final double? distanceRemaining;

  const GuardianTrackingLocationUpdated({
    required this.driverPosition,
    required this.bearing,
    this.eta,
    this.distanceRemaining,
  });

  @override
  List<Object?> get props => [driverPosition, bearing, eta, distanceRemaining];
}

class GuardianTrackingRefreshRequested extends GuardianTrackingEvent {}
