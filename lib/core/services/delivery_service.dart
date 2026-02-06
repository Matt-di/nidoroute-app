import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import '../models/delivery.dart';

class DeliveryService {
  final ApiService _apiService = ApiService();

  // Get deliveries for a specific trip (guardian view)
  Future<List<Delivery>> getTripDeliveries(String tripId) async {
    try {
      final response = await _apiService.get('${AppConfig.baseUrl}/deliveries?trip_id=$tripId');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => Delivery.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load trip deliveries');
      }
    } catch (e) {
      throw Exception('Error loading trip deliveries: $e');
    }
  }

  // Get delivery history for a specific passenger
  Future<List<Delivery>> getPassengerDeliveryHistory(String passengerId) async {
    try {
      final response = await _apiService.get('${AppConfig.baseUrl}/passengers/$passengerId/deliveries');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => Delivery.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load passenger delivery history');
      }
    } catch (e) {
      throw Exception('Error loading passenger delivery history: $e');
    }
  }

  // Mark delivery as picked up
  Future<Delivery> markAsPickedUp(String deliveryId) async {
    try {
      final response = await _apiService.post('${AppConfig.baseUrl}/deliveries/$deliveryId/pickup');

      if (response.statusCode == 200) {
        return Delivery.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to mark delivery as picked up');
      }
    } catch (e) {
      throw Exception('Error marking delivery as picked up: $e');
    }
  }

  // Mark delivery as delivered
  Future<Delivery> markAsDelivered(String deliveryId) async {
    try {
      final response = await _apiService.post('${AppConfig.baseUrl}/deliveries/$deliveryId/deliver');

      if (response.statusCode == 200) {
        return Delivery.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to mark delivery as delivered');
      }
    } catch (e) {
      throw Exception('Error marking delivery as delivered: $e');
    }
  }

  // Get deliveries for current guardian's children
  Future<List<Delivery>> getGuardianDeliveries({
    String? status,
    String? dateRange,
    String? passengerId,
    int perPage = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status != 'All') queryParams['status'] = status;
      if (dateRange != null && dateRange != 'All Time') queryParams['date_range'] = dateRange;
      if (passengerId != null) queryParams['passenger_id'] = passengerId;
      queryParams['per_page'] = perPage.toString();

      final queryString = queryParams.isNotEmpty
          ? '?' + queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')
          : '';

      final response = await _apiService.get('${AppConfig.baseUrl}/guardians/my-deliveries$queryString');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => Delivery.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load guardian deliveries');
      }
    } catch (e) {
      throw Exception('Error loading guardian deliveries: $e');
    }
  }

  // Get active deliveries for guardian (ongoing trips)
  Future<List<Delivery>> getActiveGuardianDeliveries() async {
    try {
      final deliveries = await getGuardianDeliveries();
      // Filter for deliveries that are not completed
      return deliveries.where((delivery) => !delivery.isCompleted).toList();
    } catch (e) {
      throw Exception('Error loading active guardian deliveries: $e');
    }
  }

  // Get delivery statistics
  Future<Map<String, dynamic>> getDeliveryStats() async {
    try {
      final response = await _apiService.get('${AppConfig.baseUrl}/deliveries/stats');

      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      } else {
        throw Exception('Failed to load delivery stats');
      }
    } catch (e) {
      throw Exception('Error loading delivery stats: $e');
    }
  }
}
