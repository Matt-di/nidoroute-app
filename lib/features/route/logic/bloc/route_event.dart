import 'package:equatable/equatable.dart';

abstract class RouteEvent extends Equatable {
  const RouteEvent();

  @override
  List<Object?> get props => [];
}

class RouteDetailLoadRequested extends RouteEvent {
  final String routeId;

  const RouteDetailLoadRequested(this.routeId);

  @override
  List<Object?> get props => [routeId];
}

class RouteTripsLoadRequested extends RouteEvent {
  final String routeId;
  final Map<String, dynamic> filters;

  const RouteTripsLoadRequested(this.routeId, {this.filters = const {}});

  @override
  List<Object?> get props => [routeId, filters];
}

class RouteTripsFilterApplied extends RouteEvent {
  final Map<String, dynamic> filters;

  const RouteTripsFilterApplied(this.filters);

  @override
  List<Object?> get props => [filters];
}
