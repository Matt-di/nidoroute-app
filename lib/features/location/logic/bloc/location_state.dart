import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoadInProgress extends LocationState {}

class LocationLoadSuccess extends LocationState {
  final Position position;
  const LocationLoadSuccess(this.position);

  @override
  List<Object?> get props => [position];
}

class LocationLoadFailure extends LocationState {
  final String error;
  const LocationLoadFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class LocationPermissionDenied extends LocationState {}

class LocationPermissionPermanentlyDenied extends LocationState {}
