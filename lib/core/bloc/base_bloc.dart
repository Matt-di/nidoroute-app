import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'base_state.dart';
import 'bloc_exceptions.dart';

/// Abstract base class for all BLoCs with common functionality
abstract class BaseBloc<Event, State extends BlocState> extends Bloc<Event, State> {
  BaseBloc(State initialState) : super(initialState);

  /// Execute an async operation with automatic loading and error handling
  Future<T?> executeWithLoading<T>({
    required Future<T> Function() operation,
    required void Function(T) onSuccess,
    required void Function(BlocException) onError,
  }) async {
    try {
      emit(state.copyWith(status: BlocStatus.loading) as State);
      final result = await operation();
      onSuccess(result);
      return result;
    } catch (e) {
      final exception = _convertToBlocException(e);
      onError(exception);
      return null;
    }
  }

  /// Execute multiple operations in parallel with loading state
  Future<List<T?>> executeParallelWithLoading<T>({
    required List<Future<T> Function()> operations,
    required void Function(List<T>) onSuccess,
    required void Function(BlocException) onError,
  }) async {
    try {
      emit(state.copyWith(status: BlocStatus.loading) as State);
      final results = await Future.wait(operations.map((op) => op()));
      onSuccess(results);
      return results;
    } catch (e) {
      final exception = _convertToBlocException(e);
      onError(exception);
      return [];
    }
  }

  /// Execute operation without loading state (for background operations)
  Future<T?> executeSilent<T>({
    required Future<T> Function() operation,
    required void Function(T) onSuccess,
    void Function(BlocException)? onError,
  }) async {
    try {
      final result = await operation();
      onSuccess(result);
      return result;
    } catch (e) {
      final exception = _convertToBlocException(e);
      onError?.call(exception);
      return null;
    }
  }

  /// Convert any exception to a BlocException with user-friendly messages
  BlocException _convertToBlocException(dynamic error) {
    if (error is BlocException) {
      return error;
    }

    if (error is DioException) {
      final response = error.response;
      if (response != null && response.data != null) {
        final data = response.data;
        if (data is Map && data.containsKey('message')) {
          return DataBlocException(
            message: data['message'].toString(),
            code: response.statusCode?.toString(),
            originalError: error,
          );
        }
      }
    }
    
    final errorString = error.toString().toLowerCase();
    
    // Network related errors
    if (errorString.contains('connection') || errorString.contains('network')) {
      return NetworkBlocException(
        message: 'Network connection error. Please check your internet connection.',
        code: 'NETWORK_ERROR',
        originalError: error,
      );
    }
    
    if (errorString.contains('timeout')) {
      return NetworkBlocException(
        message: 'Request timed out. Please try again.',
        code: 'TIMEOUT',
        originalError: error,
      );
    }
    
    // HTTP Status Code errors
    if (errorString.contains('404') || errorString.contains('not found')) {
      return DataBlocException(
        message: 'The requested data was not found.',
        code: 'NOT_FOUND',
        originalError: error,
      );
    }
    
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return AuthBlocException(
        message: 'You are not authorized to perform this action.',
        code: 'UNAUTHORIZED',
        originalError: error,
      );
    }
    
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return PermissionBlocException(
        message: 'Access denied. You don\'t have permission for this action.',
        code: 'FORBIDDEN',
        originalError: error,
      );
    }
    
    if (errorString.contains('500') || errorString.contains('server error')) {
      return DataBlocException(
        message: 'Server error. Please try again later.',
        code: 'SERVER_ERROR',
        originalError: error,
      );
    }
    
    // API specific errors
    if (errorString.contains('validation')) {
      return ValidationBlocException(
        message: 'Invalid data provided. Please check your input.',
        originalError: error,
      );
    }
    
    if (errorString.contains('failed to load')) {
      return DataBlocException(
        message: 'Unable to load data. Please try again.',
        code: 'LOAD_FAILED',
        originalError: error,
      );
    }
    
    if (errorString.contains('permission')) {
      return PermissionBlocException(
        message: 'You don\'t have permission to perform this action.',
        code: 'PERMISSION_DENIED',
        originalError: error,
      );
    }
    
    // Default fallback with user-friendly message
    return DataBlocException(
      message: 'Something went wrong. Please try again later.',
      code: 'UNKNOWN_ERROR',
      originalError: error,
    );
  }

  /// Safe emit that prevents state emission after BLoC is closed
  @override
  void emit(State state) {
    if (isClosed) return;
    super.emit(state);
  }

  /// Emit with null check
  void emitSafe(State? state) {
    if (state != null && !isClosed) {
      super.emit(state);
    }
  }
}

/// Mixin for common BLoC operations
mixin BlocMixin<Event, State extends BlocState> on BaseBloc<Event, State> {
  /// Handle common CRUD operations
  Future<void> handleCreate<T>({
    required Future<T> Function() createOperation,
    required void Function(T) onSuccess,
    String? successMessage,
  }) async {
    await executeWithLoading<T>(
      operation: createOperation,
      onSuccess: (result) {
        onSuccess(result);
        // Could add success notification here if needed
      },
      onError: (error) {
        // Could add error notification here if needed
      },
    );
  }

  /// Handle update operations
  Future<void> handleUpdate<T>({
    required Future<T> Function() updateOperation,
    required void Function(T) onSuccess,
  }) async {
    await executeWithLoading<T>(
      operation: updateOperation,
      onSuccess: onSuccess,
      onError: (error) {
        // Handle error
      },
    );
  }

  /// Handle delete operations
  Future<void> handleDelete({
    required Future<void> Function() deleteOperation,
    required void Function() onSuccess,
  }) async {
    await executeWithLoading<void>(
      operation: deleteOperation,
      onSuccess: (_) => onSuccess(),
      onError: (error) {
        // Handle error
      },
    );
  }

  /// Handle fetch operations
  Future<void> handleFetch<T>({
    required Future<T> Function() fetchOperation,
    required void Function(T) onSuccess,
  }) async {
    await executeWithLoading<T>(
      operation: fetchOperation,
      onSuccess: onSuccess,
      onError: (error) {
        // Handle error
      },
    );
  }
}
