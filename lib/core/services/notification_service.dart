import 'dart:async';
import 'package:nitoroute/core/models/notification_message.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  final _notificationStreamController =
      StreamController<NotificationMessage>.broadcast();
  Stream<NotificationMessage> get notificationStream =>
      _notificationStreamController.stream;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  void dispose() {
    _notificationStreamController.close();
  }

  Future<void> requestPermission() async {
  }

  Future<String?> getToken() async {
    return null;
  }

  void subscribeToTopic(String topic) {
  }

  void unsubscribeFromTopic(String topic) {
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final message = NotificationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      data: payload != null ? {'payload': payload} : null,
      timestamp: DateTime.now(),
    );
    
    _notificationStreamController.add(message);
  }

  Future<String?> getFcmToken() async {
    return null;
  }

  Future<void> updateServerToken(String? token) async {
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiService.post(
        AppConfig.markNotificationReadEndpoint.replaceFirst('{id}', notificationId),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<NotificationMessage>> getNotifications() async {
    try {
      final response = await _apiService.get(AppConfig.notificationsEndpoint);
      
      if (response.statusCode == 200) {
        final dynamic rawData = response.data;
        
        // Match backend structure: response['data']['notifications']
        List<dynamic> listData = [];
        if (rawData is Map && rawData['success'] == true && rawData['data'] is Map) {
          final innerData = rawData['data'];
          if (innerData['notifications'] is List) {
            listData = innerData['notifications'];
          }
        } else if (rawData is List) {
          listData = rawData;
        }
            
        return listData.map((json) => NotificationMessage.fromJson(json)).toList();
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
