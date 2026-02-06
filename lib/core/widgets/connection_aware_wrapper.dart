import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'auth_wrapper.dart';

class ConnectionAwareWrapper extends StatefulWidget {
  final NotificationService notificationService;
  const ConnectionAwareWrapper({super.key, required this.notificationService});

  @override
  State<ConnectionAwareWrapper> createState() => _ConnectionAwareWrapperState();
}

class _ConnectionAwareWrapperState extends State<ConnectionAwareWrapper> {
  @override
  Widget build(BuildContext context) {
    // For now, just return the AuthWrapper without connection monitoring
    // This can be added later once the app is stable
    return AuthWrapper(notificationService: widget.notificationService);
  }
}
