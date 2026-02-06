import '../config/app_config.dart';
import 'api_service.dart';
import '../models/route.dart';

class RouteService {
  final ApiService _apiService = ApiService();

  // Get active routes for the driver
  Future<List<Route>> getDriverRoutes() async {
    try {
      final response = await _apiService.get(AppConfig.activeRoutesEndpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => Route.fromJson(json)).toList();
      }
      throw Exception('Failed to load routes');
    } catch (e) {
      throw Exception('Error fetching routes: $e');
    }
  }

  // Get route details
  Future<Route> getRouteById(String routeId) async {
    try {
      final response = await _apiService.get('${AppConfig.routesEndpoint}/$routeId');
      if (response.statusCode == 200) {
        return Route.fromJson(response.data['data'] ?? response.data);
      }
      throw Exception('Failed to load route details');
    } catch (e) {
      throw Exception('Error fetching route: $e');
    }
  }
}
