import '../config/app_config.dart';
import 'base_service.dart';
import '../models/trip.dart';
import '../models/delivery.dart';

class TripService extends BaseService {
  
  // Get trips with optional range and status filters
  Future<List<Trip>> getTrips({String? dateFrom, String? dateTo, dynamic status}) async {
    final Map<String, dynamic> queryParams = {};
    if (dateFrom != null) queryParams['date_from'] = dateFrom;
    if (dateTo != null) queryParams['date_to'] = dateTo;
    
    if (status != null) {
      if (status is List) {
        queryParams['status'] = status.join(',');
      } else {
        queryParams['status'] = status;
      }
    }

    return performRequest(
      () => apiService.get(AppConfig.tripsEndpoint, queryParameters: queryParams),
      onSuccess: (data) => (data as List).map((json) => Trip.fromJson(json)).toList(),
    );
  }

  // Get trips with pagination and filters
  Future<Map<String, dynamic>> getTripsPaginated({
    String? status,
    String? date,
    String? search,
    int page = 1,
    int perPage = 10,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'per_page': perPage,
    };
    if (status != null) queryParams['status'] = status;
    if (date != null) queryParams['date'] = date;
    if (search != null) queryParams['search'] = search;

    return performPaginatedRequest(
      () => apiService.get(
        AppConfig.tripsEndpoint,
        queryParameters: queryParams,
      ),
      fromJson: (json) => Trip.fromJson(json),
    );
  }

  // Get active trips
  Future<List<Trip>> getActiveTrips() async {
    return performRequest(
      () => apiService.get(AppConfig.activeTripEndpoint),
      onSuccess: (data) => (data as List).map((json) => Trip.fromJson(json)).toList(),
    );
  }

  // Get trips by route with filters
  Future<Map<String, dynamic>> getTripsByRoute(String routeId, {Map<String, dynamic> filters = const {}}) async {
    return performPaginatedRequest(
      () => apiService.get(
        '${AppConfig.routesEndpoint}/$routeId/trips',
        queryParameters: filters,
      ),
      fromJson: (json) => Trip.fromJson(json),
    );
  }

  // Get trip by ID
  Future<Trip> getTripById(String tripId) async {
    return performRequest(
      () => apiService.get('${AppConfig.tripsEndpoint}/$tripId'),
      onSuccess: (data) => Trip.fromJson(data),
    );
  }

  // Start a trip
  Future<Trip> startTrip(String tripId) async {
    final endpoint = AppConfig.startTripEndpoint.replaceAll('{id}', tripId);
    return performRequest(
      () => apiService.post(endpoint),
      onSuccess: (data) => Trip.fromJson(data),
    );
  }

  // Complete a trip
  Future<Trip> completeTrip(String tripId) async {
    final endpoint = AppConfig.completeTripEndpoint.replaceAll('{id}', tripId);
    return performRequest(
      () => apiService.post(endpoint),
      onSuccess: (data) => Trip.fromJson(data),
    );
  }

  // Update driver location
  Future<void> updateLocation(String driverId, double lat, double lng) async {
    final endpoint = AppConfig.driverLocationEndpoint.replaceAll('{driver}', driverId);
    await performRequest(
      () => apiService.post(
        endpoint,
        data: {
          'latitude': lat,
          'longitude': lng,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
      onSuccess: (_) => null,
    );
  }

  // Get deliveries for a trip
  Future<List<Delivery>> getTripDeliveries(String tripId) async {
    try {
      // First try to get deliveries through the trip endpoint
      final tripResponse = await apiService.get('${AppConfig.tripsEndpoint}/$tripId');

      if (tripResponse.statusCode == 200) {
        final tripData = tripResponse.data['data'] ?? tripResponse.data;
        final deliveries = tripData['deliveries'];

        if (deliveries != null && deliveries is List) {
          return deliveries.map((json) => Delivery.fromJson(json)).toList();
        }
      }

      // Fallback to deliveries endpoint using base service pattern
      return performRequest(
        () => apiService.get(
          AppConfig.deliveriesEndpoint,
          queryParameters: {'trip_id': tripId},
        ),
        onSuccess: (data) => (data as List).map((json) => Delivery.fromJson(json)).toList(),
      );
    } catch (e) {
      throw Exception('Error fetching deliveries: $e');
    }
  }

  // Mark passenger as picked up
  Future<Delivery> markAsPickedUp(String deliveryId) async {
    final endpoint = AppConfig.pickupDeliveryEndpoint.replaceAll('{id}', deliveryId);
    return performRequest(
      () => apiService.post(endpoint),
      onSuccess: (data) => Delivery.fromJson(data),
    );
  }

  // Mark passenger as delivered
  Future<Delivery> markAsDelivered(String deliveryId) async {
    final endpoint = AppConfig.dropoffDeliveryEndpoint.replaceAll('{id}', deliveryId);
    return performRequest(
      () => apiService.post(endpoint),
      onSuccess: (data) => Delivery.fromJson(data),
    );
  }

  // Mark delivery as no-show
  Future<Delivery> markAsNoShow(String deliveryId) async {
    final endpoint = AppConfig.deliveriesEndpoint + '/${deliveryId}/no-show';
    return performRequest(
      () => apiService.post(endpoint),
      onSuccess: (data) => Delivery.fromJson(data),
    );
  }

  // Get driver dashboard stats
  Future<Map<String, dynamic>> getDriverDashboardStats() async {
    return performRequest(
      () => apiService.get(AppConfig.driverDashboardEndpoint),
      onSuccess: (data) => data as Map<String, dynamic>,
    );
  }

  // Get guardian's trips
  Future<Map<String, dynamic>> getGuardianTrips({
    String? status,
    String? date,
    String? passengerId,
    int page = 1,
    int perPage = 15,
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'per_page': perPage,
    };
    if (status != null) queryParams['status'] = status;
    if (date != null) queryParams['date'] = date;
    if (passengerId != null) queryParams['passenger_id'] = passengerId;

    return performPaginatedRequest(
      () => apiService.get(
        AppConfig.guardianTripsEndpoint,
        queryParameters: queryParams,
      ),
      fromJson: (json) => Trip.fromJson(json),
    );
  }
}
