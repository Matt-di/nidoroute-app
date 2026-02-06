import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/route_service.dart';
import '../../../../core/services/trip_service.dart';
import '../../../../core/models/route.dart' as model;
import 'route_event.dart';
import 'route_state.dart';

class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final RouteService routeService;
  final TripService tripService;

  RouteBloc({required this.routeService, required this.tripService})
      : super(const RouteInitial()) {
    on<RouteDetailLoadRequested>(_onRouteDetailLoadRequested);
    on<RouteTripsLoadRequested>(_onRouteTripsLoadRequested);
    on<RouteTripsFilterApplied>(_onRouteTripsFilterApplied);
  }

  Future<void> _onRouteDetailLoadRequested(
    RouteDetailLoadRequested event,
    Emitter<RouteState> emit,
  ) async {
    emit(const RouteLoading());
    try {
      final route = await routeService.getRouteById(event.routeId);
      emit(RouteLoaded(route));
    } catch (e) {
      emit(RouteError(e.toString()));
    }
  }

  Future<void> _onRouteTripsLoadRequested(
    RouteTripsLoadRequested event,
    Emitter<RouteState> emit,
  ) async {
    try {
      // If we don't have the route yet, load it first
      model.Route? route;
      if (state is RouteLoaded) {
        route = (state as RouteLoaded).route;
        emit(RouteTripsLoading(route));
      } else if (state is RouteWithTripsLoaded) {
        route = (state as RouteWithTripsLoaded).route;
        emit(RouteTripsLoading(route));
      } else {
        // Load route first
        emit(const RouteLoading());
        route = await routeService.getRouteById(event.routeId);
      }

      // Load trips with filters
      final tripsResponse = await tripService.getTripsByRoute(
        event.routeId,
        filters: event.filters,
      );

      emit(RouteWithTripsLoaded(
        route: route,
        trips: tripsResponse['data'] ?? [],
        filters: event.filters,
        hasMore: tripsResponse['meta']?['current_page'] < tripsResponse['meta']?['last_page'],
        currentPage: tripsResponse['meta']?['current_page'] ?? 1,
      ));
    } catch (e) {
      emit(RouteError(e.toString()));
    }
  }

  Future<void> _onRouteTripsFilterApplied(
    RouteTripsFilterApplied event,
    Emitter<RouteState> emit,
  ) async {
    if (state is RouteWithTripsLoaded) {
      final currentState = state as RouteWithTripsLoaded;
      emit(currentState.copyWith(filters: event.filters));

      // Reload trips with new filters
      add(RouteTripsLoadRequested(currentState.route.id, filters: event.filters));
    }
  }
}
