import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/logic/bloc/auth_bloc.dart';
import '../../core/bloc/base_state.dart';
import '../services/notification_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import 'unified_navigation_wrapper.dart';

class AuthWrapper extends StatelessWidget {
  final NotificationService notificationService;
  const AuthWrapper({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, BlocState<AuthData>>(
      builder: (context, state) {
        // Show loading while we're still checking auth on startup
        if (state.isInitial || state.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if we have a valid token (authenticated)
        if (state.isSuccess && state.data?.token != null) {
          return const UnifiedNavigationWrapper();
        }

        // Default to login screen
        return const LoginScreen();
      },
    );
  }
}
