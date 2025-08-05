class DomainException implements Exception {
  final String message;
  final String? code;

  const DomainException(this.message, [this.code]);

  @override
  String toString() => 'DomainException: $message';
}

class AuthenticationException extends DomainException {
  const AuthenticationException(String message) : super(message, 'AUTH_ERROR');
}

class ValidationException extends DomainException {
  const ValidationException(String message)
    : super(message, 'VALIDATION_ERROR');
}

class InfrastructureException implements Exception {
  final String message;
  final String? code;

  const InfrastructureException(this.message, {this.code});

  @override
  String toString() => 'InfrastructureException: $message';
}

class InitializationException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  const InitializationException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('InitializationException: $message');

    if (originalError != null) {
      buffer.write(' (caused by: $originalError)');
    }

    return buffer.toString();
  }
}

class NetworkInitializationException implements Exception {
  final String message;
  final Object? cause;

  const NetworkInitializationException(this.message, [this.cause]);

  @override
  String toString() =>
      'NetworkInitializationException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}
