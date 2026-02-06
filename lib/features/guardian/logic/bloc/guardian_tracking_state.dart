import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/passenger.dart';
import '../../../../core/models/delivery.dart';

abstract class GuardianTrackingState extends Equatable {
  const GuardianTrackingState();

  @override
  List<Object?> get props => [];
}

class GuardianTrackingInitial extends GuardianTrackingState {}

class GuardianTrackingLoading extends GuardianTrackingState {}

class GuardianTrackingReady extends GuardianTrackingState {
  final Trip trip;
  final Passenger passenger;
  final Delivery? passengerDelivery;
  final LatLng driverPosition;
  final double bearing;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final String eta;
  final String distanceLabel;
  final String? errorMessage;

  const GuardianTrackingReady({
    required this.trip,
    required this.passenger,
    this.passengerDelivery,
    required this.driverPosition,
    required this.bearing,
    required this.markers,
    required this.polylines,
    required this.eta,
    required this.distanceLabel,
    this.errorMessage,
  });

  GuardianTrackingReady copyWith({
    Trip? trip,
    Passenger? passenger,
    Delivery? passengerDelivery,
    LatLng? driverPosition,
    double? bearing,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    String? eta,
    String? distanceLabel,
    String? errorMessage,
  }) {
    return GuardianTrackingReady(
      trip: trip ?? this.trip,
      passenger: passenger ?? this.passenger,
      passengerDelivery: passengerDelivery ?? this.passengerDelivery,
      driverPosition: driverPosition ?? this.driverPosition,
      bearing: bearing ?? this.bearing,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      eta: eta ?? this.eta,
      distanceLabel: distanceLabel ?? this.distanceLabel,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    trip,
    passenger,
    passengerDelivery,
    driverPosition,
    bearing,
    markers,
    polylines,
    eta,
    distanceLabel,
    errorMessage,
  ];
}

class GuardianTrackingError extends GuardianTrackingState {
  final String message;

  const GuardianTrackingError(this.message);

  @override
  List<Object?> get props => [message];
}
