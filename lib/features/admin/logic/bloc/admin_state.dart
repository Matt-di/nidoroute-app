import 'package:equatable/equatable.dart';
import '../../../../core/models/user.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/route.dart';
import '../../../../core/models/passenger.dart';
import '../../../../core/models/guardian.dart';
import '../../../../core/models/driver.dart';
import '../../../../core/models/car.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoadingStats extends AdminState {}

class AdminLoadingTrips extends AdminState {}

class AdminLoadingDrivers extends AdminState {}

class AdminLoadingRoutes extends AdminState {}

class AdminLoadingPassengers extends AdminState {}

class AdminLoadingGuardians extends AdminState {}

class AdminLoadingStaff extends AdminState {}

class AdminLoadingRouteDependencies extends AdminState {}

class AdminDashboardStatsLoaded extends AdminState {
  final Map<String, dynamic> stats;
  final List<Trip>? activeTrips;

  const AdminDashboardStatsLoaded(this.stats, {this.activeTrips});

  @override
  List<Object?> get props => [stats, activeTrips];
}

class AdminDriversLoaded extends AdminState {
  final List<Driver> drivers;

  const AdminDriversLoaded(this.drivers);

  @override
  List<Object?> get props => [drivers];
}

class AdminGuardiansLoaded extends AdminState {
  final List<Guardian> guardians;

  const AdminGuardiansLoaded(this.guardians);

  @override
  List<Object?> get props => [guardians];
}

class AdminRoutesLoaded extends AdminState {
  final List<Route> routes;

  const AdminRoutesLoaded(this.routes);

  @override
  List<Object?> get props => [routes];
}

class AdminPassengersLoaded extends AdminState {
  final List<Passenger> passengers;

  const AdminPassengersLoaded(this.passengers);

  @override
  List<Object?> get props => [passengers];
}

class AdminActiveTripsLoaded extends AdminState {
  final List<Trip> trips;
  final Map<String, dynamic>? stats;

  const AdminActiveTripsLoaded(this.trips, {this.stats});

  @override
  List<Object?> get props => [trips, stats];
}

class AdminAllTripsLoaded extends AdminState {
  final List<Trip> trips;

  const AdminAllTripsLoaded(this.trips);

  @override
  List<Object?> get props => [trips];
}

class AdminStaffLoaded extends AdminState {
  final List<User> staff;

  const AdminStaffLoaded(this.staff);

  @override
  List<Object?> get props => [staff];
}

class AdminCarsLoaded extends AdminState {
  final List<Car> cars;

  const AdminCarsLoaded(this.cars);

  @override
  List<Object?> get props => [cars];
}

class AdminRouteDependenciesLoaded extends AdminState {
  final List<Driver> drivers;
  final List<Car> cars;

  const AdminRouteDependenciesLoaded({required this.drivers, required this.cars});

  @override
  List<Object?> get props => [drivers, cars];
}

class AdminOperationSuccess extends AdminState {
  final String message;
  const AdminOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminOperationFailure extends AdminState {
  final String message;
  const AdminOperationFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}
