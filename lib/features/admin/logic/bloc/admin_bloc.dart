import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:nitoroute/core/models/car.dart';
import 'package:nitoroute/core/models/driver.dart';
import 'package:nitoroute/core/models/trip.dart';
import '../../../../core/services/admin_service.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminService _adminService;

  AdminBloc({required AdminService adminService})
    : _adminService = adminService,
      super(AdminInitial()) {
    on<AdminLoadDashboardStats>(_onLoadDashboardStats);
    on<AdminLoadDrivers>(_onLoadDrivers);
    on<AdminCreateDriver>(_onCreateDriver);
    on<AdminUpdateDriver>(_onUpdateDriver);
    on<AdminDeleteDriver>(_onDeleteDriver);
    on<AdminLoadRoutes>(_onLoadRoutes);
    on<AdminCreateRoute>(_onCreateRoute);
    on<AdminUpdateRoute>(_onUpdateRoute);
    on<AdminDeleteRoute>(_onDeleteRoute);
    on<AdminLoadPassengers>(_onLoadPassengers);
    on<AdminCreatePassenger>(_onCreatePassenger);
    on<AdminUpdatePassenger>(_onUpdatePassenger);
    on<AdminDeletePassenger>(_onDeletePassenger);
    on<AdminLoadGuardians>(_onLoadGuardians);
    on<AdminCreateGuardian>(_onCreateGuardian);
    on<AdminUpdateGuardian>(_onUpdateGuardian);
    on<AdminDeleteGuardian>(_onDeleteGuardian);
    on<AdminLoadActiveTrips>(_onLoadActiveTrips);
    on<AdminLoadAllTrips>(_onLoadAllTrips);
    on<AdminCreateTrip>(_onCreateTrip);
    on<AdminDeleteTrip>(_onDeleteTrip);
    on<AdminLoadStaff>(_onLoadStaff);
    on<AdminLoadCars>(_onLoadCars);
    on<AdminLoadRouteDependencies>(_onLoadRouteDependencies);
    on<AdminCreateStaff>(_onCreateStaff);
    on<AdminUpdateStaff>(_onUpdateStaff);
    on<AdminDeleteStaff>(_onDeleteStaff);
  }

  Future<void> _onCreateDriver(
    AdminCreateDriver event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.createDriver(event.data);
      emit(const AdminOperationSuccess('Driver created successfully'));
      // Reload drivers
      add(const AdminLoadDrivers());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onUpdateDriver(
    AdminUpdateDriver event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.updateDriver(event.id, event.data);
      emit(const AdminOperationSuccess('Driver updated successfully'));
      // Reload drivers
      add(const AdminLoadDrivers());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onDeleteDriver(
    AdminDeleteDriver event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.deleteDriver(event.id);
      emit(const AdminOperationSuccess('Driver deleted successfully'));
      // Reload drivers
      add(const AdminLoadDrivers());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onLoadRoutes(
    AdminLoadRoutes event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final routes = await _adminService.getRoutes();
      emit(AdminRoutesLoaded(routes));
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onCreateRoute(
    AdminCreateRoute event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.createRoute(event.data);
      emit(const AdminOperationSuccess('Route created successfully'));
      // Reload routes
      add(const AdminLoadRoutes());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onUpdateRoute(
    AdminUpdateRoute event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.updateRoute(event.id, event.data);
      emit(const AdminOperationSuccess('Route updated successfully'));
      // Reload routes
      add(const AdminLoadRoutes());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onDeleteRoute(
    AdminDeleteRoute event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.deleteRoute(event.id);
      emit(const AdminOperationSuccess('Route deleted successfully'));
      // Reload routes
      add(const AdminLoadRoutes());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onLoadPassengers(
    AdminLoadPassengers event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final passengers = await _adminService.getPassengers();
      emit(AdminPassengersLoaded(passengers));
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onCreatePassenger(
    AdminCreatePassenger event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.createPassenger(event.data);
      emit(const AdminOperationSuccess('Passenger created successfully'));
      add(const AdminLoadPassengers());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onUpdatePassenger(
    AdminUpdatePassenger event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.updatePassenger(event.id, event.data);
      emit(const AdminOperationSuccess('Passenger updated successfully'));
      add(const AdminLoadPassengers());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onDeletePassenger(
    AdminDeletePassenger event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.deletePassenger(event.id);
      emit(const AdminOperationSuccess('Passenger deleted successfully'));
      add(const AdminLoadPassengers());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onLoadDashboardStats(
    AdminLoadDashboardStats event,
    Emitter<AdminState> emit,
  ) async {
    final currentState = state;
    List<Trip>? existingTrips;
    
    // Extract existing trips from any state that has them
    if (currentState is AdminActiveTripsLoaded) {
      existingTrips = currentState.trips;
    }
    
    // Always emit AdminLoadingStats to show loading state
    emit(AdminLoadingStats());
    
    try {
      final stats = await _adminService.getDashboardStats();
      
      // If we don't have trips yet, load them now
      if (existingTrips == null) {
        try {
          final trips = await _adminService.getActiveTrips();
          emit(AdminDashboardStatsLoaded(stats, activeTrips: trips));
        } catch (e) {
          emit(AdminDashboardStatsLoaded(stats, activeTrips: []));
        }
      } else {
        emit(AdminDashboardStatsLoaded(stats, activeTrips: existingTrips));
      }
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onLoadDrivers(
    AdminLoadDrivers event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final drivers = await _adminService.getDrivers();
      emit(AdminDriversLoaded(drivers));
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onLoadGuardians(
    AdminLoadGuardians event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoadingGuardians());
    try {
      final guardians = await _adminService.getGuardians();
      emit(AdminGuardiansLoaded(guardians));
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onCreateGuardian(
    AdminCreateGuardian event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.createGuardian(event.data);
      emit(const AdminOperationSuccess('Guardian created successfully'));
      add(const AdminLoadGuardians());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onUpdateGuardian(
    AdminUpdateGuardian event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.updateGuardian(event.id, event.data);
      emit(const AdminOperationSuccess('Guardian updated successfully'));
      add(const AdminLoadGuardians());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onDeleteGuardian(
    AdminDeleteGuardian event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.deleteGuardian(event.id);
      emit(const AdminOperationSuccess('Guardian deleted successfully'));
      add(const AdminLoadGuardians());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onLoadActiveTrips(
    AdminLoadActiveTrips event,
    Emitter<AdminState> emit,
  ) async {
    final currentState = state;
    Map<String, dynamic>? existingStats;
    
    // Extract existing stats from any state that has them
    if (currentState is AdminDashboardStatsLoaded) {
      existingStats = currentState.stats;
    } else if (currentState is AdminActiveTripsLoaded) {
      existingStats = currentState.stats;
    }
    
    // IMPORTANT: Don't emit AdminLoadingTrips if we already have stats or if the current state already has the data we need
    if (existingStats != null || currentState is AdminDashboardStatsLoaded || currentState is AdminActiveTripsLoaded) {
      // Already have needed data, loading trips without loading state
    } else {
      emit(AdminLoadingTrips());
    }
    
    try {
      final trips = await _adminService.getActiveTrips();
      
      // Always emit AdminActiveTripsLoaded with stats if available
      emit(AdminActiveTripsLoaded(trips, stats: existingStats));
    } catch (e) {
      if (existingStats != null) {
        emit(AdminError(_sanitizeError(e)));
      } else {
        emit(AdminError(_sanitizeError(e)));
      }
    }
  }

  Future<void> _onLoadAllTrips(
    AdminLoadAllTrips event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final trips = await _adminService.getTrips();
      emit(AdminAllTripsLoaded(trips));
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onCreateTrip(
    AdminCreateTrip event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.createTrip(event.data);
      emit(const AdminOperationSuccess('Trip created successfully'));
      // Reload trips
      add(const AdminLoadAllTrips());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onDeleteTrip(
    AdminDeleteTrip event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.deleteTrip(event.id);
      emit(const AdminOperationSuccess('Trip deleted successfully'));
      // Reload trips
      add(const AdminLoadAllTrips());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onLoadStaff(
    AdminLoadStaff event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final staff = await _adminService.getStaff();
      emit(AdminStaffLoaded(staff));
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onLoadCars(
    AdminLoadCars event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final cars = await _adminService.getCars();
      emit(AdminCarsLoaded(cars));
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onLoadRouteDependencies(
    AdminLoadRouteDependencies event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoadingRouteDependencies());
    try {
      final results = await Future.wait([
        _adminService.getDrivers(),
        _adminService.getCars(),
      ]);
      emit(
        AdminRouteDependenciesLoaded(
          drivers: results[0] as List<Driver>,
          cars: results[1] as List<Car>,
        ),
      );
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onCreateStaff(
    AdminCreateStaff event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.createStaff(event.data);
      emit(const AdminOperationSuccess('Staff created successfully'));
      add(const AdminLoadStaff());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onUpdateStaff(
    AdminUpdateStaff event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.updateStaff(event.id, event.data);
      emit(const AdminOperationSuccess('Staff updated successfully'));
      add(const AdminLoadStaff());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  Future<void> _onDeleteStaff(
    AdminDeleteStaff event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _adminService.deleteStaff(event.id);
      emit(const AdminOperationSuccess('Staff deleted successfully'));
      add(const AdminLoadStaff());
    } catch (e) {
      emit(AdminError(_sanitizeError(e)));
    }
  }

  String _sanitizeError(dynamic error) {
    if (error is DioException) {
      final response = error.response;
      if (response != null) {
        // Handle 422 Validation Errors
        if (response.statusCode == 422) {
          final data = response.data;
          if (data is Map && data.containsKey('message')) {
            return data['message'].toString();
          }
          return 'Validation failed. Please check your data.';
        }
        
        // Handle other server errors with messages
        if (response.data is Map && (response.data as Map).containsKey('message')) {
          return (response.data as Map)['message'].toString();
        }
      }
      
      // Network/Timeout errors
      if (error.type == DioExceptionType.connectionTimeout || 
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Please check your internet.';
      }
      
      if (error.type == DioExceptionType.connectionError) {
        return 'Network connection error. Please try again.';
      }
    }
    
    // Fallback for generic errors
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('socketexception')) {
      return 'No internet connection.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }
}
