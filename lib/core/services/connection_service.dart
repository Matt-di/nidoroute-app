import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import 'toast_service.dart';

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  bool _isConnected = false;
  DateTime? _lastCheck;
  String? _lastError;

  bool get isConnected => _isConnected;
  DateTime? get lastCheck => _lastCheck;
  String? get lastError => _lastError;

  Future<bool> checkConnection() async {
    try {
      _lastCheck = DateTime.now();
      
      // Try multiple endpoints to check if server is running
      bool connected = false;
      String? lastError;
      
      // Try common endpoints in order
      final endpoints = ['/health', '/api/health', '/ping', '/api/ping', '/'];
      
      for (final endpoint in endpoints) {
        try {
          await _dio.get(endpoint).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw DioException(
                requestOptions: RequestOptions(
                  path: endpoint,
                  baseUrl: _dio.options.baseUrl,
                ),
                type: DioExceptionType.connectionTimeout,
              );
            },
          );
          
          _isConnected = true;
          _lastError = null;
          return true;
        } catch (e) {
          lastError = e.toString();
        }
      }
      
      _isConnected = false;
      _lastError = lastError ?? 'All endpoints failed';
      return false;
    } catch (e) {
      _isConnected = false;
      _lastError = e.toString();
      return false;
    }
  }

  Future<void> _checkInternetConnectivity() async {
    try {
      // Try to reach a reliable external service (like Google DNS)
      final internetDio = Dio(
        BaseOptions(
          baseUrl: 'https://8.8.8.8',
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      
      await internetDio.get('/').timeout(const Duration(seconds: 3));
    } catch (e) {
      // If we can't reach external services, it's likely no internet
      throw DioException(
        requestOptions: RequestOptions(
          path: '/',
          baseUrl: 'https://8.8.8.8',
          method: 'GET',
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
        type: DioExceptionType.connectionError,
        error: 'No internet connection',
      );
    }
  }

  Future<bool> checkConnectionWithToast(BuildContext context) async {
    try {
      _lastCheck = DateTime.now();
      
      // Try to reach the health endpoint or root
      await _dio.get('/health').timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw DioException(
            requestOptions: RequestOptions(
              path: '/health',
              baseUrl: _dio.options.baseUrl,
              method: 'GET',
              connectTimeout: _dio.options.connectTimeout,
              receiveTimeout: _dio.options.receiveTimeout,
              headers: _dio.options.headers,
            ),
            type: DioExceptionType.connectionTimeout,
          );
        },
      );
      
      _isConnected = true;
      _lastError = null;
      
      // Show success toast only if we were previously disconnected
      if (_lastError != null) {
        ToastService().showSuccess(context, 'Connection restored');
      }
      
      return true;
    } catch (e) {
      _isConnected = false;
      _lastError = e.toString();
      
      // Show appropriate error message
      String errorMessage = _getErrorMessage(e);
      ToastService().showError(context, errorMessage);
      
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          if (error.requestOptions.baseUrl.contains('8.8.8.8')) {
            return 'Internet connection timeout. Please check your network settings.';
          }
          return 'Server connection timeout. The server may be busy or down.';
        case DioExceptionType.connectionError:
          if (error.requestOptions.baseUrl.contains('8.8.8.8')) {
            return 'No internet connection. Please check your Wi-Fi or mobile data.';
          }
          return 'Server is not reachable. Please check if the server is running.';
        case DioExceptionType.badResponse:
          if (error.response?.statusCode == 404) {
            return 'Server is running but endpoint not found. Contact support.';
          } else if (error.response?.statusCode != null && error.response!.statusCode! >= 500) {
            return 'Server error occurred. The server is having issues.';
          }
          return 'Server responded with an error. Please try again later.';
        default:
          if (error.toString().contains('8.8.8.8')) {
            return 'Internet connection problem. Please check your network.';
          }
          return 'Cannot connect to server. Please check your connection and try again.';
      }
    }
    return 'Network connection failed. Please check your internet connection.';
  }

  void resetConnectionStatus() {
    _isConnected = false;
    _lastError = null;
    _lastCheck = null;
  }
}
