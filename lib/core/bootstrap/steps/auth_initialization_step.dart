import 'package:app/core/bootstrap/contracts/initialization_context.dart';
import 'package:app/core/bootstrap/initialization_step.dart';
import 'package:app/di/dependency_injection.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

class AuthInitializationStep extends InitializationStep {
  const AuthInitializationStep()
    : super(name: 'Authentication Initialization', isCritical: false);

  @override
  Future<void> execute(InitializationContext context) async {
    if (context.container == null) {
      _logger.w(' Container not available, skipping auth initialization');
      return;
    }

    try {
      // Get auth initializer from DI container
      final authInitializer = context.container!.read(authInitializerProvider);

      // Execute authentication initialization
      final result = await authInitializer.initialize(context);

      result.fold(
        (failure) =>
            _logger.w(' Auth initialization failed: ${failure.message}'),
        (_) => _logger.i(' Auth initialization completed successfully'),
      );
    } catch (e, stackTrace) {
      _logger.e(' Auth initialization error: $e');
      _logger.e(' StackTrace: $stackTrace');
      // Don't rethrow - auth failure shouldn't prevent app startup
    }
  }
}
