import '../models/route.dart' as model;
import '../models/passenger.dart';
import '../models/guardian.dart';
import '../models/driver.dart';
import '../models/car.dart';
import '../services/admin_service.dart';

class AdminRepository {
  final AdminService _adminService;

  AdminRepository({required AdminService adminService}) : _adminService = adminService;

  // Route management
  Future<List<model.Route>> getRoutes() => _adminService.getRoutes();
  
  Future<model.Route> createRoute(Map<String, dynamic> data) => 
      _adminService.createRoute(data);

  Future<model.Route> updateRoute(String id, Map<String, dynamic> data) => 
      _adminService.updateRoute(id, data);

  Future<void> deleteRoute(String id) => _adminService.deleteRoute(id);

  // Passenger management
  Future<List<Passenger>> getPassengers() => _adminService.getPassengers();
  
  Future<Passenger> createPassenger(Map<String, dynamic> data) => 
      _adminService.createPassenger(data);

  Future<Passenger> updatePassenger(String id, Map<String, dynamic> data) => 
      _adminService.updatePassenger(id, data);

  Future<void> deletePassenger(String id) => _adminService.deletePassenger(id);

  // Guardian management
  Future<List<Guardian>> getGuardians() => _adminService.getGuardians();
  
  Future<Guardian> createGuardian(Map<String, dynamic> data) => 
      _adminService.createGuardian(data);

  Future<Guardian> updateGuardian(String id, Map<String, dynamic> data) => 
      _adminService.updateGuardian(id, data);

  Future<void> deleteGuardian(String id) => _adminService.deleteGuardian(id);

  // Driver management
  Future<List<Driver>> getDrivers() => _adminService.getDrivers();
  
  Future<Driver> createDriver(Map<String, dynamic> data) => 
      _adminService.createDriver(data);

  Future<Driver> updateDriver(String id, Map<String, dynamic> data) => 
      _adminService.updateDriver(id, data);

  Future<void> deleteDriver(String id) => _adminService.deleteDriver(id);

  // Car management (read-only)
  Future<List<Car>> getCars() => _adminService.getCars();

  // Dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() => _adminService.getDashboardStats();
}
