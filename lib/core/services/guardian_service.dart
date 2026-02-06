import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'base_service.dart';
import '../models/passenger.dart';
import '../models/delivery.dart';

class GuardianService extends BaseService {
  
  // Get current guardian's passengers (children)
  Future<List<Passenger>> getMyPassengers() async {
    return performRequest(
      () => apiService.get('${AppConfig.baseUrl}/guardians/my-passengers'),
      onSuccess: (data) => (data as List).map((json) => Passenger.fromJson(json)).toList(),
    );
  }

  // Get current guardian's deliveries (for all children)
  Future<List<Delivery>> getMyDeliveries() async {
    return performRequest(
      () => apiService.get('${AppConfig.baseUrl}/deliveries/guardian'),
      onSuccess: (data) => (data as List).map((json) => Delivery.fromJson(json)).toList(),
    );
  }

  // Active deliveries
  Future<List<Delivery>> getActiveDeliveries() async {
    try {
      final deliveries = await getMyDeliveries();
      // Filter for deliveries that are not completed
      return deliveries.where((delivery) => !delivery.isCompleted).toList();
    } catch (e) {
      throw Exception('Error loading active deliveries: $e');
    }
  }

  // Get delivery history for a specific child
  Future<List<Delivery>> getChildDeliveryHistory(String passengerId) async {
    return performRequest(
      () => apiService.get('${AppConfig.baseUrl}/passengers/$passengerId/deliveries'),
      onSuccess: (data) => (data as List).map((json) => Delivery.fromJson(json)).toList(),
    );
  }

  // Get guardian dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    return performRequest(
      () => apiService.get('${AppConfig.baseUrl}/guardians/dashboard'),
      onSuccess: (data) => data as Map<String, dynamic>,
    );
  }

  // Contact bus driver (placeholder for future implementation)
  Future<void> contactDriver(String driverId, String message) async {
    await performRequest(
      () => apiService.post(
        '${AppConfig.baseUrl}/guardians/contact-driver',
        data: {
          'driver_id': driverId,
          'message': message,
        },
      ),
      onSuccess: (_) => null,
    );
  }

  // Leave a note for bus driver
  Future<void> leaveNote(String tripId, String passengerId, String note) async {
    await performRequest(
      () => apiService.post(
        '${AppConfig.baseUrl}/guardians/leave-note',
        data: {
          'trip_id': tripId,
          'passenger_id': passengerId,
          'note': note,
        },
      ),
      onSuccess: (_) => null,
    );
  }

  // Get guardian profile information
  Future<Map<String, dynamic>> getProfile() async {
    return performRequest(
      () => apiService.get('${AppConfig.baseUrl}/guardians/profile'),
      onSuccess: (data) => data as Map<String, dynamic>,
    );
  }

  // Update guardian profile
  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    await performRequest(
      () => apiService.put(
        '${AppConfig.baseUrl}/guardians/profile',
        data: profileData,
      ),
      onSuccess: (_) => null,
    );
  }
}
