import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../core/widgets/unified_navigation_wrapper.dart';
import '../../core/widgets/auth_wrapper.dart';
import '../../core/services/notification_service.dart';
import 'package:provider/provider.dart';

class AppRouter {
  static const String root = '/';
  static const String login = '/login';
  static const String home = '/home';

  static Map<String, WidgetBuilder> get routes => {
    root: (context) => AuthWrapper(
      notificationService: context.read<NotificationService>(),
    ),
    login: (context) => const LoginScreen(),
    home: (context) => const UnifiedNavigationWrapper(),
  };

  static String getInitialRoute(String? role) {
    if (role != null) return home;
    return login;
  }
}
