import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base_bloc.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/models/user.dart';
import 'auth_event.dart';

/// Auth data model for BlocState
class AuthData extends Equatable {
  final User? user;
  final String? token;
  final String? role;

  const AuthData({
    this.user,
    this.token,
    this.role,
  });

  @override
  List<Object?> get props => [user, token, role];

  factory AuthData.authenticated({
    required User user,
    required String token,
    required String role,
  }) {
    return AuthData(
      user: user,
      token: token,
      role: role,
    );
  }

  factory AuthData.unauthenticated() {
    return const AuthData();
  }
}

class AuthBloc extends BaseBloc<AuthEvent, BlocState<AuthData>> {
  final AuthService _authService;

  AuthBloc({required AuthService authService}) 
      : _authService = authService,
        super(const BlocState.initial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthRefreshRequested>(_onAuthRefreshRequested);
    on<AuthPasswordChanged>(_onAuthPasswordChanged);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<BlocState<AuthData>> emit,
  ) async {
    await executeSilent<AuthData>(
      operation: () async {
        final isAuthenticated = await _authService.isAuthenticated();
        
        if (isAuthenticated) {
          final user = await _authService.getCurrentUser();
          final token = await _authService.getToken();
          final role = await _authService.getUserRole();

          if (user != null && token != null && role != null) {
            return AuthData.authenticated(
              user: user,
              token: token,
              role: role,
            );
          } else {
            return AuthData.unauthenticated();
          }
        } else {
          return AuthData.unauthenticated();
        }
      },
      onSuccess: (authData) {
        emit(BlocState.success(authData));
      },
      onError: (error) {
        // Silent error handling for initial check
        emit(BlocState.success(AuthData.unauthenticated()));
      },
    );
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<BlocState<AuthData>> emit,
  ) async {
    await executeWithLoading<AuthData>(
      operation: () async {
        final result = await _authService.login(event.email, event.password).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Login process timed out. Please try again.');
          },
        );
        
        return AuthData.authenticated(
          user: result['user'],
          token: result['token'],
          role: result['role'],
        );
      },
      onSuccess: (authData) {
        emit(BlocState.success(authData));
      },
      onError: (error) {
        emit(BlocState.error(message: 'Login failed: ${error.message}'));
        // Return to unauthenticated after showing error
        Future.delayed(const Duration(seconds: 2)).then((_) {
          emit(BlocState.success(AuthData.unauthenticated()));
        });
      },
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<BlocState<AuthData>> emit,
  ) async {
    await executeWithLoading<void>(
      operation: () async {
        await _authService.logout().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            // Proceed with local cleanup on timeout
          },
        );
        return;
      },
      onSuccess: (_) {
        emit(BlocState.success(AuthData.unauthenticated()));
      },
      onError: (error) {
        // Even if logout fails, clear local state
        emit(BlocState.success(AuthData.unauthenticated()));
      },
    );
  }

  Future<void> _onAuthRefreshRequested(
    AuthRefreshRequested event,
    Emitter<BlocState<AuthData>> emit,
  ) async {
    await executeSilent<AuthData>(
      operation: () async {
        final user = await _authService.refreshUserData();
        final token = await _authService.getToken();
        final role = await _authService.getUserRole();

        if (token != null && role != null) {
          return AuthData.authenticated(
            user: user,
            token: token,
            role: role,
          );
        } else {
          return AuthData.unauthenticated();
        }
      },
      onSuccess: (authData) {
        emit(BlocState.success(authData));
      },
      onError: (error) {
        // Keep current state if refresh fails
      },
    );
  }

  Future<void> _onAuthPasswordChanged(
    AuthPasswordChanged event,
    Emitter<BlocState<AuthData>> emit,
  ) async {
    await executeWithLoading<void>(
      operation: () async {
        await _authService.changePassword(event.currentPassword, event.newPassword);
        return;
      },
      onSuccess: (_) {
        // Keep current state, just show success message
        emit(BlocState.success(state.data!));
      },
      onError: (error) {
        emit(BlocState.error(message: 'Failed to change password: ${error.message}'));
        // Return to current state after showing error
        Future.delayed(const Duration(seconds: 2)).then((_) {
          emit(BlocState.success(state.data!));
        });
      },
    );
  }
}
