/// Base exception for all BLoC-related errors
abstract class BlocException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const BlocException({
    required this.message,
    this.code,
    this.originalError,
  });
  
  @override
  String toString() => 'BlocException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Network-related BLoC exceptions
class NetworkBlocException extends BlocException {
  const NetworkBlocException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}

/// Validation-related BLoC exceptions
class ValidationBlocException extends BlocException {
  final Map<String, String>? fieldErrors;
  
  const ValidationBlocException({
    required String message,
    this.fieldErrors,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}

/// Authentication-related BLoC exceptions
class AuthBlocException extends BlocException {
  const AuthBlocException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}

/// Data-related BLoC exceptions
class DataBlocException extends BlocException {
  const DataBlocException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}

/// Permission-related BLoC exceptions
class PermissionBlocException extends BlocException {
  const PermissionBlocException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}
