import '../models/trip.dart';
import '../models/delivery.dart';
import '../services/trip_service.dart';

class TripRepository {
  final TripService _tripService;

  TripRepository({required TripService tripService}) : _tripService = tripService;

  // Reading data
  Future<List<Trip>> getTrips({String? dateFrom, String? dateTo, dynamic status}) => 
      _tripService.getTrips(dateFrom: dateFrom, dateTo: dateTo, status: status);

  Future<Map<String, dynamic>> getTripsPaginated({
    String? status,
    String? date,
    String? search,
    int page = 1,
    int perPage = 10,
  }) => _tripService.getTripsPaginated(
    status: status,
    date: date,
    search: search,
    page: page,
    perPage: perPage,
  );

  Future<List<Trip>> getActiveTrips() => _tripService.getActiveTrips();
  Future<Trip> getTripById(String tripId) => _tripService.getTripById(tripId);
  Future<List<Delivery>> getTripDeliveries(String tripId) => _tripService.getTripDeliveries(tripId);
  
  // Trip Lifecycle
  Future<Trip> startTrip(String tripId) => _tripService.startTrip(tripId);
  Future<Trip> completeTrip(String tripId) => _tripService.completeTrip(tripId);
  
  // Updates
  Future<void> updateLocation(String tripId, double lat, double lng) => _tripService.updateLocation(tripId, lat, lng);
  
  // Delivery status shortcuts
  Future<Delivery> markAsPickedUp(String deliveryId) => _tripService.markAsPickedUp(deliveryId);
  Future<Delivery> markAsDelivered(String deliveryId) => _tripService.markAsDelivered(deliveryId);
  Future<Delivery> markAsNoShow(String deliveryId) => _tripService.markAsNoShow(deliveryId);

  // Stats and specialized lists
  Future<Map<String, dynamic>> getDriverDashboardStats() => _tripService.getDriverDashboardStats();
  
  Future<Map<String, dynamic>> getGuardianTrips({
    String? status,
    String? date,
    String? passengerId,
    int page = 1,
    int perPage = 15,
  }) => _tripService.getGuardianTrips(
    status: status,
    date: date,
    passengerId: passengerId,
    page: page,
    perPage: perPage,
  );
}
