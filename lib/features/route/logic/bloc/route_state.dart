import 'package:equatable/equatable.dart';
import '../../../../core/models/route.dart' as model;
import '../../../../core/models/trip.dart';

abstract class RouteState extends Equatable {
  const RouteState();

  @override
  List<Object?> get props => [];
}

class RouteInitial extends RouteState {
  const RouteInitial();
}

class RouteLoading extends RouteState {
  const RouteLoading();
}

class RouteLoaded extends RouteState {
  final model.Route route;

  const RouteLoaded(this.route);

  @override
  List<Object?> get props => [route];
}

class RouteWithTripsLoaded extends RouteState {
  final model.Route route;
  final List<Trip> trips;
  final Map<String, dynamic> filters;
  final bool hasMore;
  final int currentPage;

  const RouteWithTripsLoaded({
    required this.route,
    required this.trips,
    this.filters = const {},
    this.hasMore = false,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [route, trips, filters, hasMore, currentPage];

  RouteWithTripsLoaded copyWith({
    model.Route? route,
    List<Trip>? trips,
    Map<String, dynamic>? filters,
    bool? hasMore,
    int? currentPage,
  }) {
    return RouteWithTripsLoaded(
      route: route ?? this.route,
      trips: trips ?? this.trips,
      filters: filters ?? this.filters,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class RouteTripsLoading extends RouteState {
  final model.Route route;

  const RouteTripsLoading(this.route);

  @override
  List<Object?> get props => [route];
}

class RouteError extends RouteState {
  final String message;

  const RouteError(this.message);

  @override
  List<Object?> get props => [message];
}
