import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class AdminLoadDashboardStats extends AdminEvent {
  const AdminLoadDashboardStats();
}

class AdminLoadDrivers extends AdminEvent {
  const AdminLoadDrivers();
}

class AdminCreateDriver extends AdminEvent {
  final Map<String, dynamic> data;
  const AdminCreateDriver(this.data);
  @override
  List<Object?> get props => [data];
}

class AdminUpdateDriver extends AdminEvent {
  final String id;
  final Map<String, dynamic> data;
  const AdminUpdateDriver(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class AdminDeleteDriver extends AdminEvent {
  final String id;
  const AdminDeleteDriver(this.id);
  @override
  List<Object?> get props => [id];
}

class AdminLoadRoutes extends AdminEvent {
  const AdminLoadRoutes();
}

class AdminCreateRoute extends AdminEvent {
  final Map<String, dynamic> data;
  const AdminCreateRoute(this.data);
  @override
  List<Object?> get props => [data];
}

class AdminUpdateRoute extends AdminEvent {
  final String id;
  final Map<String, dynamic> data;
  const AdminUpdateRoute(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class AdminDeleteRoute extends AdminEvent {
  final String id;
  const AdminDeleteRoute(this.id);
  @override
  List<Object?> get props => [id];
}

class AdminLoadPassengers extends AdminEvent {
  const AdminLoadPassengers();
}

class AdminCreatePassenger extends AdminEvent {
  final Map<String, dynamic> data;
  const AdminCreatePassenger(this.data);
  @override
  List<Object?> get props => [data];
}

class AdminUpdatePassenger extends AdminEvent {
  final String id;
  final Map<String, dynamic> data;
  const AdminUpdatePassenger(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class AdminDeletePassenger extends AdminEvent {
  final String id;
  const AdminDeletePassenger(this.id);
  @override
  List<Object?> get props => [id];
}

class AdminLoadGuardians extends AdminEvent {
  const AdminLoadGuardians();
}

class AdminCreateGuardian extends AdminEvent {
  final Map<String, dynamic> data;
  const AdminCreateGuardian(this.data);
  @override
  List<Object?> get props => [data];
}

class AdminUpdateGuardian extends AdminEvent {
  final String id;
  final Map<String, dynamic> data;
  const AdminUpdateGuardian(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class AdminDeleteGuardian extends AdminEvent {
  final String id;
  const AdminDeleteGuardian(this.id);
  @override
  List<Object?> get props => [id];
}

class AdminLoadActiveTrips extends AdminEvent {
  const AdminLoadActiveTrips();
}

class AdminLoadAllTrips extends AdminEvent {
  const AdminLoadAllTrips();
}

class AdminCreateTrip extends AdminEvent {
  final Map<String, dynamic> data;
  const AdminCreateTrip(this.data);
  @override
  List<Object?> get props => [data];
}

class AdminDeleteTrip extends AdminEvent {
  final String id;
  const AdminDeleteTrip(this.id);
  @override
  List<Object?> get props => [id];
}

class AdminLoadStaff extends AdminEvent {
  const AdminLoadStaff();
}

class AdminLoadCars extends AdminEvent {
  const AdminLoadCars();
}

class AdminLoadRouteDependencies extends AdminEvent {
  const AdminLoadRouteDependencies();
}

class AdminCreateStaff extends AdminEvent {
  final Map<String, dynamic> data;
  const AdminCreateStaff(this.data);
  @override
  List<Object?> get props => [data];
}

class AdminUpdateStaff extends AdminEvent {
  final String id;
  final Map<String, dynamic> data;
  const AdminUpdateStaff(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

class AdminDeleteStaff extends AdminEvent {
  final String id;
  const AdminDeleteStaff(this.id);
  @override
  List<Object?> get props => [id];
}

