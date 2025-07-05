abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message, 'NETWORK_ERROR');
}

class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message, 'SERVER_ERROR');
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message, 'VALIDATION_ERROR');
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message) : super(message, 'AUTH_ERROR');
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(String message) : super(message, 'NOT_FOUND');
}

class UnknownFailure extends Failure {
  const UnknownFailure(String message) : super(message, 'UNKNOWN_ERROR');
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(String message) : super(message, 'DATABASE_FAILURE');
}
