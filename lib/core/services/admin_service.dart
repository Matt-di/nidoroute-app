import '../config/app_config.dart';
import 'base_service.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../models/user.dart';
import '../models/trip.dart';
import '../models/route.dart' as model;
import '../models/passenger.dart';
import '../models/guardian.dart';
import '../models/driver.dart';
import '../models/car.dart';

class AdminService extends BaseService {
  
  // Get all routes
  Future<List<model.Route>> getRoutes() async {
    return performRequest(
      () => apiService.get(AppConfig.routesEndpoint),
      onSuccess: (data) => (data as List).map((json) => model.Route.fromJson(json)).toList(),
    );
  }

  // Create route
  Future<model.Route> createRoute(Map<String, dynamic> data) async {
    return performRequest(
      () => apiService.post(AppConfig.routesEndpoint, data: data),
      onSuccess: (data) => model.Route.fromJson(data),
    );
  }

  // Update route
  Future<model.Route> updateRoute(String id, Map<String, dynamic> data) async {
    return performRequest(
      () => apiService.put('${AppConfig.routesEndpoint}/$id', data: data),
      onSuccess: (data) => model.Route.fromJson(data),
    );
  }

  // Delete route
  Future<void> deleteRoute(String id) async {
    await performRequest(
      () => apiService.delete('${AppConfig.routesEndpoint}/$id'),
      onSuccess: (_) => null,
    );
  }

  // Get all passengers
  Future<List<Passenger>> getPassengers() async {
    return performRequest(
      () => apiService.get(AppConfig.passengersEndpoint),
      onSuccess: (data) => (data as List).map((json) => Passenger.fromJson(json)).toList(),
    );
  }

  // Create passenger
  Future<Passenger> createPassenger(Map<String, dynamic> data) async {
    dynamic requestData = data;
    
    if (data.containsKey('image_file') && data['image_file'] is File) {
      final file = data['image_file'] as File;
      final mapData = Map<String, dynamic>.from(data);
      mapData.remove('image_file');
      
      requestData = FormData.fromMap({
        ...mapData,
        'image': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });
    }

    return performRequest(
      () => apiService.post(AppConfig.passengersEndpoint, data: requestData),
      onSuccess: (data) => Passenger.fromJson(data),
    );
  }

  // Update passenger
  Future<Passenger> updatePassenger(String id, Map<String, dynamic> data) async {
    dynamic requestData = data;
    
    if (data.containsKey('image_file') && data['image_file'] is File) {
      final file = data['image_file'] as File;
      final mapData = Map<String, dynamic>.from(data);
      mapData.remove('image_file');
      
      requestData = FormData.fromMap({
        ...mapData,
        'image': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });
    }

    return performRequest(
      () => apiService.put('${AppConfig.passengersEndpoint}/$id', data: requestData),
      onSuccess: (data) => Passenger.fromJson(data),
    );
  }

  // Delete passenger
  Future<void> deletePassenger(String id) async {
    await performRequest(
      () => apiService.delete('${AppConfig.passengersEndpoint}/$id'),
      onSuccess: (_) => null,
    );
  }

  // Get dashboard overview stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    return performRequest(
      () => apiService.get(AppConfig.dashboardOverviewEndpoint),
      onSuccess: (data) => data as Map<String, dynamic>,
    );
  }

  // Get all drivers
  Future<List<Driver>> getDrivers() async {
    return performRequest(
      () => apiService.get(AppConfig.driversEndpoint),
      onSuccess: (data) => (data as List).map((json) => Driver.fromJson(json)).toList(),
    );
  }

  // Create driver
  Future<Driver> createDriver(Map<String, dynamic> data) async {
    dynamic requestData = data;
    
    if (data.containsKey('avatar') && data['avatar'] != null && data['avatar'] is String) {
      final file = File(data['avatar'] as String);
      if (await file.exists()) {
        final mapData = Map<String, dynamic>.from(data);
        mapData.remove('avatar');
        
        requestData = FormData.fromMap({
          ...mapData,
          'avatar': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        });
      }
    }

    return performRequest(
      () => apiService.post(AppConfig.driversEndpoint, data: requestData),
      onSuccess: (data) => Driver.fromJson(data),
    );
  }

  // Update driver
  Future<Driver> updateDriver(String id, Map<String, dynamic> data) async {
    dynamic requestData = data;
    
    if (data.containsKey('avatar') && data['avatar'] != null && data['avatar'] is String) {
      final file = File(data['avatar'] as String);
      if (await file.exists()) {
        final mapData = Map<String, dynamic>.from(data);
        mapData.remove('avatar');
        
        requestData = FormData.fromMap({
          ...mapData,
          'avatar': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        });
      }
    }

    return performRequest(
      () => apiService.put('${AppConfig.driversEndpoint}/$id', data: requestData),
      onSuccess: (data) => Driver.fromJson(data),
    );
  }

  // Delete driver
  Future<void> deleteDriver(String id) async {
    await performRequest(
      () => apiService.delete('${AppConfig.driversEndpoint}/$id'),
      onSuccess: (_) => null,
    );
  }

  // Get all staff (users/admins)
  Future<List<User>> getStaff() async {
    return performRequest(
      () => apiService.get(AppConfig.staffEndpoint),
      onSuccess: (data) => (data as List).map((json) => User.fromJson(json)).toList(),
    );
  }

  // Create staff
  Future<User> createStaff(Map<String, dynamic> data) async {
    return performRequest(
      () => apiService.post(AppConfig.staffEndpoint, data: data),
      onSuccess: (data) => User.fromJson(data),
    );
  }

  // Update staff
  Future<User> updateStaff(String id, Map<String, dynamic> data) async {
    return performRequest(
      () => apiService.put('${AppConfig.staffEndpoint}/$id', data: data),
      onSuccess: (data) => User.fromJson(data),
    );
  }

  // Delete staff
  Future<void> deleteStaff(String id) async {
    await performRequest(
      () => apiService.delete('${AppConfig.staffEndpoint}/$id'),
      onSuccess: (_) => null,
    );
  }

  // Get all guardians
  Future<List<Guardian>> getGuardians() async {
    return performRequest(
      () => apiService.get(AppConfig.guardiansEndpoint),
      onSuccess: (data) => (data as List).map((json) => Guardian.fromJson(json)).toList(),
    );
  }

  // Create guardian
  Future<Guardian> createGuardian(Map<String, dynamic> data) async {
    return performRequest(
      () => apiService.post(AppConfig.guardiansEndpoint, data: data),
      onSuccess: (data) => Guardian.fromJson(data),
    );
  }

  // Update guardian
  Future<Guardian> updateGuardian(String id, Map<String, dynamic> data) async {
    return performRequest(
      () => apiService.put('${AppConfig.guardiansEndpoint}/$id', data: data),
      onSuccess: (data) => Guardian.fromJson(data),
    );
  }

  // Delete guardian
  Future<void> deleteGuardian(String id) async {
    await performRequest(
      () => apiService.delete('${AppConfig.guardiansEndpoint}/$id'),
      onSuccess: (_) => null,
    );
  }

  // Get active trips for monitoring
  Future<List<Trip>> getActiveTrips() async {
    try {
      // First try the dedicated active endpoint
      final activeTrips = await performRequest(
        () => apiService.get(AppConfig.activeTripEndpoint),
        onSuccess: (data) => (data as List).map((json) => Trip.fromJson(json)).toList(),
      );
      
      // If we got trips from the active endpoint, return them
      if (activeTrips.isNotEmpty) {
        return activeTrips;
      }
      
      // Fallback: get all trips and filter for active ones on client side
      // This ensures we catch trips that might be missed by the backend filter
      final allTrips = await performRequest(
        () => apiService.get(AppConfig.tripsEndpoint),
        onSuccess: (data) => (data as List).map((json) => Trip.fromJson(json)).toList(),
      );
      
      // Filter trips that are considered active (scheduled or in_progress)
      return allTrips.where((trip) => trip.isActive).toList();
    } catch (e) {
      // If active endpoint fails, try getting all trips as fallback
      try {
        final allTrips = await performRequest(
          () => apiService.get(AppConfig.tripsEndpoint),
          onSuccess: (data) => (data as List).map((json) => Trip.fromJson(json)).toList(),
        );
        return allTrips.where((trip) => trip.isActive).toList();
      } catch (fallbackError) {
        throw fallbackError;
      }
    }
  }

  // Get all trips (history)
  Future<List<Trip>> getTrips() async {
    return performRequest(
      () => apiService.get(AppConfig.tripsEndpoint),
      onSuccess: (data) => (data as List).map((json) => Trip.fromJson(json)).toList(),
    );
  }

  // Create trip
  Future<Trip> createTrip(Map<String, dynamic> data) async {
    return performRequest(
      () => apiService.post(AppConfig.tripsEndpoint, data: data),
      onSuccess: (data) => Trip.fromJson(data),
    );
  }

  // Delete trip
  Future<void> deleteTrip(String id) async {
    await performRequest(
      () => apiService.delete('${AppConfig.tripsEndpoint}/$id'),
      onSuccess: (_) => null,
    );
  }

  // Get all cars
  Future<List<Car>> getCars() async {
    return performRequest(
      () => apiService.get(AppConfig.carsEndpoint),
      onSuccess: (data) => (data as List).map((json) => Car.fromJson(json)).toList(),
    );
  }
}
