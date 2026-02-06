import 'package:equatable/equatable.dart';

/// Status enum for generic state management
enum BlocStatus {
  initial,
  loading,
  success,
  error,
}

/// Generic base state that can be used by all BLoCs
class BlocState<T> extends Equatable {
  final BlocStatus status;
  final T? data;
  final String? errorMessage;
  final String? errorCode;
  
  const BlocState._({
    required this.status,
    this.data,
    this.errorMessage,
    this.errorCode,
  });

  /// Initial state
  const BlocState.initial() : this._(status: BlocStatus.initial);

  /// Loading state
  const BlocState.loading() : this._(status: BlocStatus.loading);

  /// Success state with data
  const BlocState.success(T data) : this._(
    status: BlocStatus.success,
    data: data,
  );

  /// Error state
  const BlocState.error({
    required String message,
    String? errorCode,
  }) : this._(
    status: BlocStatus.error,
    errorMessage: message,
    errorCode: errorCode,
  );

  /// Convenience getters
  bool get isInitial => status == BlocStatus.initial;
  bool get isLoading => status == BlocStatus.loading;
  bool get isSuccess => status == BlocStatus.success;
  bool get isError => status == BlocStatus.error;
  bool get hasData => data != null;

  /// Copy with modified properties
  BlocState<T> copyWith({
    BlocStatus? status,
    T? data,
    String? errorMessage,
    String? errorCode,
  }) {
    return BlocState._(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
    );
  }

  @override
  List<Object?> get props => [
    status,
    data,
    errorMessage,
    errorCode,
  ];

  @override
  String toString() {
    return 'BlocState<$T>(status: $status, data: $data, error: $errorMessage)';
  }
}

/// Mixin for common state operations
mixin BlocStateMixin<T> on BlocState<T> {
  /// Create loading state from current state
  BlocState<T> toLoading() => copyWith(status: BlocStatus.loading);

  /// Create success state from current state
  BlocState<T> toSuccess(T data) => copyWith(
    status: BlocStatus.success,
    data: data,
    errorMessage: null,
    errorCode: null,
  );

  /// Create error state from current state
  BlocState<T> toError(String message, {String? errorCode}) => copyWith(
    status: BlocStatus.error,
    errorMessage: message,
    errorCode: errorCode,
  );
}
