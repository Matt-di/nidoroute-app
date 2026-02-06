import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // API Configuration
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1';
  static String get wsUrl => dotenv.env['WS_URL'] ?? 'ws://localhost:8080';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';
  static const String userEndpoint = '/user';
  static const String refreshEndpoint = '/auth/refresh';
  static const String passwordResetEndpoint = '/auth/password/reset';
  static const String passwordChangeEndpoint = '/user/password/change';
  static const String updateFcmTokenEndpoint = '/user/fcm-token';
  static const String notificationsEndpoint = '/notifications';
  static const String markNotificationReadEndpoint = '/notifications/{id}/read';
  
  // Drivers
  static const String driversEndpoint = '/drivers';
  /// Driver location update path. Override in .env with DRIVER_LOCATION_ENDPOINT if your API uses a different path (e.g. /api/driver/location/update).
  static String get driverLocationEndpoint =>
      dotenv.env['DRIVER_LOCATION_ENDPOINT'] ?? '/drivers/{driver}/location';
  
  // Trips
  static const String tripsEndpoint = '/trips';
  static const String activeTripEndpoint = '/trips/active';
  static const String tripTrackingEndpoint = '/trips/{id}/tracking';
  static const String startTripEndpoint = '/trips/{id}/start';
  static const String completeTripEndpoint = '/trips/{id}/complete';
  
  // Routes
  static const String routesEndpoint = '/routes';
  static const String activeRoutesEndpoint = '/routes/active';
  static const String routeTrackingEndpoint = '/routes/{id}/tracking';
  
  // Deliveries (Passenger Pickup/Dropoff)
  static const String deliveriesEndpoint = '/deliveries';
  static const String pickupDeliveryEndpoint = '/deliveries/{id}/pickup';
  static const String dropoffDeliveryEndpoint = '/deliveries/{id}/deliver';
  
  // Passengers
  static const String passengersEndpoint = '/passengers';
  
  // Guardians
  static const String guardiansEndpoint = '/guardians';
  static const String guardianTripsEndpoint = '/guardians/my-trips';

  // Cars
  static const String carsEndpoint = '/cars';

  // Staff (Users/Admins)
  static const String staffEndpoint = '/users';
  
  // Dashboard
  static const String dashboardOverviewEndpoint = '/dashboard/overview';
  static const String driverDashboardEndpoint = '/driver/dashboard/overview';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String userRoleKey = 'user_role';
  
  // App Settings
  static int get connectionTimeout => int.tryParse(dotenv.env['CONNECTION_TIMEOUT'] ?? '30000') ?? 30000;
  static int get receiveTimeout => int.tryParse(dotenv.env['RECEIVE_TIMEOUT'] ?? '30000') ?? 30000;
  static int get locationUpdateInterval => int.tryParse(dotenv.env['LOCATION_UPDATE_INTERVAL'] ?? '10') ?? 10;
  static const double mapZoom = 15.0;
  
  // Google Maps
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'dummy_google_maps_api_key_replace_with_real_key';

  // Pusher / Reverb Configuration
  static String get pusherAppKey => dotenv.env['PUSHER_APP_KEY'] ?? 'app-key';
  static String get pusherAppCluster => dotenv.env['PUSHER_APP_CLUSTER'] ?? 'mt1';
  static String get pusherHost => dotenv.env['PUSHER_HOST'] ?? 'localhost';
  static int get pusherPort => int.tryParse(dotenv.env['PUSHER_PORT'] ?? '8080') ?? 8080;
  static String get pusherScheme => dotenv.env['PUSHER_SCHEME'] ?? 'ws';

  // Reverb Aliases
  static String get reverbKey => pusherAppKey;
  static String get reverbHost => pusherHost;
  static int get reverbPort => pusherPort;
  static String get reverbScheme => pusherScheme;
}

class SocketEvents {
  static const String tripLocationUpdated = '.trip.location.updated';
  static const String tripStatusUpdated = '.trip.status.updated';
  static const String deliveryStatusUpdated = '.delivery.status.updated';
  static const String routeStatusUpdated = '.route.status.updated';
  static const String tripCreated = '.trip.created';
}
