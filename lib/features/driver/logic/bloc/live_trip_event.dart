import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/delivery.dart';

abstract class LiveTripEvent extends Equatable {
  const LiveTripEvent();

  @override
  List<Object?> get props => [];
}

class LiveTripStarted extends LiveTripEvent {
  final Trip trip;

  const LiveTripStarted(this.trip);

  @override
  List<Object?> get props => [trip];
}

class LiveTripLocationUpdated extends LiveTripEvent {
  final LatLng position;
  final double bearing;

  const LiveTripLocationUpdated({
    required this.position,
    required this.bearing,
  });

  @override
  List<Object?> get props => [position, bearing];
}

class LiveTripStartRequested extends LiveTripEvent {}

class LiveTripStopArrivalRequested extends LiveTripEvent {
  final Delivery stop;

  const LiveTripStopArrivalRequested(this.stop);

  @override
  List<Object?> get props => [stop];
}

class LiveTripPickupRequested extends LiveTripEvent {
  final Delivery stop;

  const LiveTripPickupRequested(this.stop);

  @override
  List<Object?> get props => [stop];
}

class LiveTripDropoffRequested extends LiveTripEvent {
  final Delivery stop;

  const LiveTripDropoffRequested(this.stop);

  @override
  List<Object?> get props => [stop];
}

class LiveTripNoShowRequested extends LiveTripEvent {
  final Delivery stop;

  const LiveTripNoShowRequested(this.stop);

  @override
  List<Object?> get props => [stop];
}

class LiveTripCompleteRequested extends LiveTripEvent {}

class LiveTripDeliveryStatusUpdated extends LiveTripEvent {
  final String deliveryId;
  final String status;

  const LiveTripDeliveryStatusUpdated({
    required this.deliveryId,
    required this.status,
  });

  @override
  List<Object?> get props => [deliveryId, status];
}
