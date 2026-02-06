import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nitoroute/core/models/notification_message.dart';
import 'package:nitoroute/core/bloc/base_bloc.dart';
import 'package:nitoroute/core/bloc/base_state.dart';
import 'package:nitoroute/core/services/notification_service.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class NotificationLoadRequested extends NotificationEvent {}

class NotificationMarkAllReadRequested extends NotificationEvent {}

class NotificationMarkReadRequested extends NotificationEvent {
  final String notificationId;
  const NotificationMarkReadRequested(this.notificationId);
  
  @override
  List<Object?> get props => [notificationId];
}

class NotificationBloc extends BaseBloc<NotificationEvent, BlocState<List<NotificationMessage>>> {
  final NotificationService _notificationService;

  NotificationBloc({required NotificationService notificationService}) 
      : _notificationService = notificationService,
        super(const BlocState.initial()) {
    on<NotificationLoadRequested>(_onLoadRequested);
    on<NotificationMarkAllReadRequested>(_onMarkAllReadRequested);
    on<NotificationMarkReadRequested>(_onMarkReadRequested);
  }

  Future<void> _onLoadRequested(
    NotificationLoadRequested event,
    Emitter<BlocState<List<NotificationMessage>>> emit,
  ) async {
    await executeWithLoading<List<NotificationMessage>>(
      operation: () => _notificationService.getNotifications(),
      onSuccess: (notifications) {
        emit(BlocState.success(notifications));
      },
      onError: (error) {
        emit(BlocState.error(message: error.message));
      },
    );
  }

  Future<void> _onMarkAllReadRequested(
    NotificationMarkAllReadRequested event,
    Emitter<BlocState<List<NotificationMessage>>> emit,
  ) async {
    final currentNotifications = state.data ?? [];
    
    // We can either mark all read locally first for speed, or wait for API
    // Let's do a simple approach: mark each unread one as read
    final unreadOnes = currentNotifications.where((n) => !n.isRead).toList();
    
    if (unreadOnes.isEmpty) return;

    try {
      // Optimistically update UI
      final updatedNotifications = currentNotifications.map((n) => 
        n.copyWith(isRead: true)
      ).toList();
      emit(state.copyWith(data: updatedNotifications));

      // Mark all as read on server (assuming the backend has a "mark all read" or we loop)
      // Since our config only has markNotificationReadEndpoint for single ID, 
      // let's just loop for now or assume the user wants single updates.
      // If there's no bulk endpoint, we loop:
      await Future.wait(unreadOnes.map((n) => _notificationService.markAsRead(n.id)));
    } catch (e) {
      // On error, we might want to refresh list
      add(NotificationLoadRequested());
    }
  }

  Future<void> _onMarkReadRequested(
    NotificationMarkReadRequested event,
    Emitter<BlocState<List<NotificationMessage>>> emit,
  ) async {
    final currentNotifications = state.data ?? [];
    
    try {
      // Optimistically update UI
      final updatedNotifications = currentNotifications.map((n) {
        if (n.id == event.notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      emit(state.copyWith(data: updatedNotifications));

      await _notificationService.markAsRead(event.notificationId);
    } catch (e) {
      // On error, we might want to refresh list
      add(NotificationLoadRequested());
    }
  }
}
