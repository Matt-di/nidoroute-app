import '../../../../core/bloc/trip_bloc.dart';
import '../../../../core/repositories/trip_repository.dart';

/// Guardian-specific Trip BLoC using the unified TripBloc
/// This replaces the old GuardianTripListBloc with much less code
class GuardianTripListBloc extends TripBloc {
  GuardianTripListBloc({required super.tripRepository});

  // Convenience methods for guardian-specific operations
  void loadGuardianTrips({
    String? status,
    String? date,
    String? passengerId,
    int page = 1,
    int perPage = 20,
  }) {
    add(TripListLoadRequested(
      type: TripListType.guardian,
      filters: TripFilters(
        status: status,
        date: date,
        passengerId: passengerId,
      ),
      page: page,
      perPage: perPage,
    ));
  }

  void loadMoreGuardianTrips({
    String? status,
    String? date,
    String? passengerId,
    required int page,
    required int perPage,
  }) {
    add(TripListLoadMoreRequested(
      filters: TripFilters(
        status: status,
        date: date,
        passengerId: passengerId,
      ),
      page: page,
      perPage: perPage,
    ));
  }

  void refreshGuardianTrips({
    String? status,
    String? date,
    String? passengerId,
    int page = 1,
    int perPage = 20,
  }) {
    loadGuardianTrips(
      status: status,
      date: date,
      passengerId: passengerId,
      page: page,
      perPage: perPage,
    );
  }

  void updateFilters({
    String? status,
    String? date,
    String? passengerId,
  }) {
    loadGuardianTrips(
      status: status,
      date: date,
      passengerId: passengerId,
      page: 1,
      perPage: 20,
    );
  }
}
