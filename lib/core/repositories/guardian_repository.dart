import '../models/passenger.dart';
import '../models/delivery.dart';
import '../services/guardian_service.dart';

class GuardianRepository {
  final GuardianService _guardianService;

  GuardianRepository({required GuardianService guardianService}) : _guardianService = guardianService;

  // Passenger management
  Future<List<Passenger>> getMyPassengers() => _guardianService.getMyPassengers();

  // Delivery management
  Future<List<Delivery>> getMyDeliveries() => _guardianService.getMyDeliveries();
  
  Future<List<Delivery>> getActiveDeliveries() => _guardianService.getActiveDeliveries();

  // Profile management
  Future<Map<String, dynamic>> getProfile() => _guardianService.getProfile();

  Future<void> updateProfile(Map<String, dynamic> profileData) => 
      _guardianService.updateProfile(profileData);

  // Leave note
  Future<void> leaveNote(String tripId, String passengerId, String note) => 
      _guardianService.leaveNote(tripId, passengerId, note);
}
