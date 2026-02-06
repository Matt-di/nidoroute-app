import 'package:dio/dio.dart';
import 'api_service.dart';

abstract class BaseService {
  final ApiService apiService = ApiService();

  /// Handle common API response parsing and error handling
  Future<T> performRequest<T>(
    Future<Response> Function() request, {
    required T Function(dynamic data) onSuccess,
  }) async {
    try {
      final response = await request();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        return onSuccess(data);
      }
      throw Exception('Request failed with status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Operation failed: $e');
    }
  }

  /// Helper for paginated list responses
  Future<Map<String, dynamic>> performPaginatedRequest<T>(
    Future<Response> Function() request, {
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final response = await request();
      if (response.statusCode == 200) {
        final List<dynamic> list = response.data['data'] ?? [];
        final items = list.map((json) => fromJson(json)).toList();
        final meta = response.data['meta'] ?? {};
        return {
          'items': items,
          'meta': meta,
        };
      }
      throw Exception('Request failed with status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Operation failed: $e');
    }
  }
}
