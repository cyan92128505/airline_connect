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
