import 'package:app/core/failures/failure.dart';
import 'package:dartz/dartz.dart';

/// Base interface for all use cases
/// Follows the Clean Architecture pattern
abstract class UseCase<Type, Params> {
  /// Execute the use case with given parameters
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case that doesn't require parameters
abstract class NoParamsUseCase<Type> {
  /// Execute the use case without parameters
  Future<Either<Failure, Type>> call();
}
