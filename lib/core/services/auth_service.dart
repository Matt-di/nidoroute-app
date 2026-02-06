import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import '../models/user.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        AppConfig.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['access_token'];
        final user = User.fromJson(data['user']);

        // Store token and user data with timeouts to prevent hangs
        await _storage.write(key: AppConfig.tokenKey, value: token).timeout(
          const Duration(seconds: 3),
        );
        
        await _storage.write(
          key: AppConfig.userKey,
          value: jsonEncode(user.toJson()),
        ).timeout(const Duration(seconds: 3));
        
        await _storage.write(
          key: AppConfig.userRoleKey,
          value: user.role,
        ).timeout(const Duration(seconds: 3));

        return {
          'token': token,
          'user': user,
          'role': user.role,
        };
      } else {
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _apiService.post(AppConfig.logoutEndpoint);
    } catch (e) {
      // Continue with local logout even if API call fails
    } finally {
      await _storage.delete(key: AppConfig.tokenKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
      await _storage.delete(key: AppConfig.userKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
      await _storage.delete(key: AppConfig.userRoleKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await _storage.read(key: AppConfig.tokenKey).timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
      return token != null;
    } catch (e) {
      return false;
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final userJson = await _storage.read(key: AppConfig.userKey).timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get stored token
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: AppConfig.tokenKey).timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
    } catch (e) {
      return null;
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    try {
      return await _storage.read(key: AppConfig.userRoleKey).timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
    } catch (e) {
      return null;
    }
  }

  // Refresh user data from API
  Future<User> refreshUserData() async {
    try {
      final response = await _apiService.get(AppConfig.userEndpoint);
      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        await _storage.write(
          key: AppConfig.userKey,
          value: jsonEncode(user.toJson()),
        );
        return user;
      } else {
        throw Exception('Failed to refresh user data');
      }
    } catch (e) {
      throw Exception('Refresh error: $e');
    }
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _apiService.post(
        AppConfig.passwordChangeEndpoint,
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        },
      );

      if (response.statusCode == 200) {
        // Password changed successfully
        return;
      } else {
        throw Exception('Failed to change password');
      }
    } catch (e) {
      throw Exception('Password change error: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      final response = await _apiService.post(
        AppConfig.passwordResetEndpoint,
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        // Password reset email sent
        return;
      } else {
        throw Exception('Failed to send password reset email');
      }
    } catch (e) {
      throw Exception('Password reset error: $e');
    }
  }
}
