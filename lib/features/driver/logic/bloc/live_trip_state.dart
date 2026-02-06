import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/delivery.dart';

abstract class LiveTripState extends Equatable {
  const LiveTripState();

  @override
  List<Object?> get props => [];
}

class LiveTripInitial extends LiveTripState {}

class LiveTripLoading extends LiveTripState {}

class LiveTripReady extends LiveTripState {
  final Trip trip;
  final LatLng currentPosition;
  final double bearing;
  final List<Delivery> stops;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final String? errorMessage;
  final bool isSubmitting;

  const LiveTripReady({
    required this.trip,
    required this.currentPosition,
    required this.bearing,
    required this.stops,
    required this.markers,
    required this.polylines,
    this.errorMessage,
    this.isSubmitting = false,
  });

  LiveTripReady copyWith({
    Trip? trip,
    LatLng? currentPosition,
    double? bearing,
    List<Delivery>? stops,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    String? errorMessage,
    bool? isSubmitting,
  }) {
    return LiveTripReady(
      trip: trip ?? this.trip,
      currentPosition: currentPosition ?? this.currentPosition,
      bearing: bearing ?? this.bearing,
      stops: stops ?? this.stops,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
    trip,
    currentPosition,
    bearing,
    stops,
    markers,
    polylines,
    errorMessage,
    isSubmitting,
  ];
}

class LiveTripError extends LiveTripState {
  final String message;

  const LiveTripError(this.message);

  @override
  List<Object?> get props => [message];
}

class LiveTripCompleted extends LiveTripState {}
