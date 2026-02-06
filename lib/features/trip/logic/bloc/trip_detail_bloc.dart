import '../../../../core/bloc/trip_bloc.dart';

/// Trip Detail BLoC using the unified TripBloc
/// This replaces the old TripDetailBloc with much less code
class TripDetailBloc extends TripBloc {
  TripDetailBloc({required super.tripRepository});

  // Convenience methods for trip detail operations
  void loadTripDetails(String tripId) {
    add(TripDetailLoadRequested(tripId: tripId));
  }

  void startTrip(String tripId) {
    add(TripStartRequested(tripId: tripId));
  }

  void completeTrip(String tripId) {
    add(TripCompleteRequested(tripId: tripId));
  }

  // Additional convenience methods for common operations
  void refreshTripDetails(String tripId, {bool quiet = false}) {
    add(TripDetailLoadRequested(tripId: tripId, quiet: quiet));
  }
}
