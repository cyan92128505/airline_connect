import 'package:app/core/bootstrap/contracts/initialization_context.dart';
import 'package:app/core/failures/failure.dart';
import 'package:dartz/dartz.dart';

/// Abstract contract for authentication initialization
/// Defines the interface for feature-specific auth initialization logic
abstract class AuthInitializer {
  /// Human-readable name of this initializer for logging
  String get name;
  
  /// Whether this initializer is required for app functionality
  /// If true, initialization failure will prevent app startup
  bool get isRequired;

  /// Initialize authentication state for the feature
  /// Returns success or failure without throwing exceptions
  Future<Either<Failure, void>> initialize(InitializationContext context);

  /// Validate if the initialization was successful
  /// Can be called after initialize() to verify state
  Future<Either<Failure, bool>> validate(InitializationContext context);

  /// Cleanup resources if initialization fails
  /// Should not throw exceptions
  Future<void> cleanup();
}