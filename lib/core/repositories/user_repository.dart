import '../models/user.dart';
import '../services/auth_service.dart';

class UserRepository {
  final AuthService _authService;

  UserRepository({required AuthService authService}) : _authService = authService;

  // Authentication
  Future<Map<String, dynamic>> login(String email, String password) => 
      _authService.login(email, password);

  Future<void> logout() => _authService.logout();

  Future<bool> isAuthenticated() => _authService.isAuthenticated();

  // User data
  Future<User?> getCurrentUser() => _authService.getCurrentUser();

  Future<User> refreshUserData() => _authService.refreshUserData();

  Future<String?> getToken() => _authService.getToken();

  Future<String?> getUserRole() => _authService.getUserRole();

  // Password management
  Future<void> changePassword(String currentPassword, String newPassword) => 
      _authService.changePassword(currentPassword, newPassword);

  Future<void> resetPassword(String email) => _authService.resetPassword(email);
}
