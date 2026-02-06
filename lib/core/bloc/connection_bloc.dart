import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/connection_service.dart';
import 'base_state.dart';

// Connection status enum for better type safety
enum ConnectionStatus {
  connected,
  disconnected,
  checking,
  unknown,
}

// Connection data model for BlocState
class ConnectionData {
  final ConnectionStatus status;
  final String? errorMessage;
  final DateTime? lastChecked;

  const ConnectionData({
    required this.status,
    this.errorMessage,
    this.lastChecked,
  });

  ConnectionData copyWith({
    ConnectionStatus? status,
    String? errorMessage,
    DateTime? lastChecked,
  }) {
    return ConnectionData(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  factory ConnectionData.initial() {
    return const ConnectionData(status: ConnectionStatus.unknown);
  }
}

// Connection events
abstract class ConnectionEvent {
  const ConnectionEvent();
}

class ConnectionCheckRequested extends ConnectionEvent {}

class ConnectionStatusChanged extends ConnectionEvent {
  final ConnectionStatus status;
  final String? errorMessage;

  const ConnectionStatusChanged(this.status, this.errorMessage);
}

class ConnectionReset extends ConnectionEvent {}

// Connection BLoC using standard Bloc
class ConnectionBloc extends Bloc<ConnectionEvent, BlocState<ConnectionData>> {
  final ConnectionService _connectionService;
  
  // Timer for periodic connection checks
  Timer? _periodicCheckTimer;

  ConnectionBloc({required ConnectionService connectionService})
      : _connectionService = connectionService,
        super(const BlocState.initial()) {
    on<ConnectionCheckRequested>(_onConnectionCheckRequested);
    on<ConnectionStatusChanged>(_onConnectionStatusChanged);
    on<ConnectionReset>(_onConnectionReset);
    
    // Start periodic connection checks
    _startPeriodicChecks();
    
    // Do initial connection check after a short delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      add(ConnectionCheckRequested());
    });
  }

  Future<void> _onConnectionCheckRequested(
    ConnectionCheckRequested event,
    Emitter<BlocState<ConnectionData>> emit,
  ) async {
    emit(const BlocState.loading());
    
    try {
      final isConnected = await _connectionService.checkConnection();
      
      if (isConnected) {
        emit(BlocState.success(ConnectionData(status: ConnectionStatus.connected)));
      } else {
        final errorMessage = _connectionService.lastError ?? 'Unknown error';
        emit(BlocState.success(ConnectionData(
          status: ConnectionStatus.disconnected,
          errorMessage: errorMessage,
          lastChecked: DateTime.now(),
        )));
      }
    } catch (e) {
      emit(BlocState.success(ConnectionData(
        status: ConnectionStatus.disconnected,
        errorMessage: e.toString(),
        lastChecked: DateTime.now(),
      )));
    }
  }

  Future<void> _onConnectionStatusChanged(
    ConnectionStatusChanged event,
    Emitter<BlocState<ConnectionData>> emit,
  ) async {
    final currentData = state.isSuccess ? state.data! : ConnectionData.initial();
    final updatedData = currentData.copyWith(
      status: event.status,
      errorMessage: event.errorMessage,
      lastChecked: DateTime.now(),
    );
    
    emit(BlocState.success(updatedData));
  }

  Future<void> _onConnectionReset(
    ConnectionReset event,
    Emitter<BlocState<ConnectionData>> emit,
  ) async {
    emit(BlocState.success(ConnectionData.initial()));
  }

  void _startPeriodicChecks() {
    _periodicCheckTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      add(ConnectionCheckRequested());
    });
  }

  @override
  Future<void> close() {
    _periodicCheckTimer?.cancel();
    return super.close();
  }
}
