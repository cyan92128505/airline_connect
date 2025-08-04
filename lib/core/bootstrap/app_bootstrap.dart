import 'dart:async';
import 'package:app/core/bootstrap/bootstrap_config.dart';
import 'package:app/core/bootstrap/contracts/initialization_context.dart';
import 'package:app/core/bootstrap/initialization_step.dart';
import 'package:app/core/bootstrap/steps/auth_initialization_step.dart';
import 'package:app/core/bootstrap/steps/database_initialization_step.dart';
import 'package:app/core/bootstrap/steps/demo_data_initialization_step.dart';
import 'package:app/core/bootstrap/steps/system_ui_initialization_step.dart';
import 'package:app/core/bootstrap/steps/timezone_initialization_step.dart';
import 'package:app/di/dependency_injection.dart';
import 'package:app/features/member/infrastructure/bootstrap/member_auth_initializer.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

/// Central bootstrap service responsible for application initialization
/// Orchestrates initialization steps with proper error handling and timeout
class AppBootstrap {
  static final Logger _logger = Logger();

  static Future<ProviderContainer> initialize(BootstrapConfig config) async {
    _logger.i('Starting application bootstrap with config: $config');

    try {
      return _performInitialization(config).timeout(
        Duration(seconds: config.maxInitializationTimeoutSeconds),
        onTimeout: () => throw InitializationException(
          'Application initialization timed out after '
          '${config.maxInitializationTimeoutSeconds} seconds',
        ),
      );
    } on TimeoutException {
      throw InitializationException(
        'Application initialization timed out after '
        '${config.maxInitializationTimeoutSeconds} seconds',
      );
    } catch (e) {
      _logger.e('Bootstrap initialization failed: $e');
      rethrow;
    }
  }

  /// Perform the actual initialization steps in proper sequence
  static Future<ProviderContainer> _performInitialization(
    BootstrapConfig config,
  ) async {
    final context = InitializationContext();

    // Create dependency injection overrides
    final List<Override> overrides = [];

    try {
      await _executeBasicInitializationSteps(config, context);

      if (context.objectBox != null) {
        overrides.add(objectBoxProvider.overrideWithValue(context.objectBox!));
      }

      overrides.add(
        authInitializerProvider.overrideWithValue(MemberAuthInitializer()),
      );

      final container = ProviderContainer(overrides: overrides);
      context.container = container;

      _logger.i(
        'Provider container created with ${overrides.length} overrides',
      );

      if (config.enableAuthInitialization) {
        await _executeAuthInitialization(context);
      }

      await _validateInitializations(context, config);

      _logger.i('Application bootstrap completed successfully');
      return container;
    } catch (e) {
      _logger.e('Initialization failed, performing cleanup');
      await _cleanupOnFailure(context);
      rethrow;
    }
  }

  /// Execute basic initialization steps that don't require container
  static Future<void> _executeBasicInitializationSteps(
    BootstrapConfig config,
    InitializationContext context,
  ) async {
    final steps = <InitializationStep>[
      TimezoneInitializationStep(config.timezoneName),
      SystemUIInitializationStep(),
      DatabaseInitializationStep(),
      if (config.enableDemoData) DemoDataInitializationStep(),
    ];

    for (final step in steps) {
      await _executeStep(step, context);
    }
  }

  /// Execute authentication initialization using dependency injection
  static Future<void> _executeAuthInitialization(
    InitializationContext context,
  ) async {
    try {
      _logger.i('Executing authentication initialization...');

      final authStep = AuthInitializationStep();
      await _executeStep(authStep, context);

      _logger.i('Authentication initialization completed');
    } catch (e) {
      _logger.e('Authentication initialization failed: $e');
      // Don't rethrow - auth failure shouldn't prevent app startup
    }
  }

  /// Execute a single initialization step with error handling
  static Future<void> _executeStep(
    InitializationStep step,
    InitializationContext context,
  ) async {
    _logger.i('Executing initialization step: ${step.name}');

    try {
      await step.execute(context);
      _logger.i('Successfully completed step: ${step.name}');
    } catch (e, stackTrace) {
      _logger.e('Failed to execute step ${step.name}: $e');
      _logger.e('StackTrace: $stackTrace');

      // Check if step is critical - if so, fail fast
      if (step.isCritical) {
        throw InitializationException(
          'Critical initialization step failed: ${step.name}',
          originalError: e,
          stackTrace: stackTrace,
        );
      } else {
        // Log warning for non-critical steps and continue
        _logger.w('Non-critical step ${step.name} failed, continuing...');
      }
    }
  }

  /// Validate that all initializations completed successfully
  static Future<void> _validateInitializations(
    InitializationContext context,
    BootstrapConfig config,
  ) async {
    _logger.i('Validating initialization results...');

    // Validate database if available
    if (context.objectBox != null) {
      if (!context.objectBox!.isHealthy()) {
        throw InitializationException('Database validation failed');
      }
    }

    // Validate auth initialization if enabled
    if (config.enableAuthInitialization && context.container != null) {
      try {
        final authInitializer = context.container!.read(
          authInitializerProvider,
        );
        final authValidation = await authInitializer.validate(context);

        authValidation.fold(
          (failure) => _logger.w('Auth validation failed: ${failure.message}'),
          (isValid) => _logger.d('Auth validation passed: $isValid'),
        );
      } catch (e) {
        _logger.w('Auth validation error: $e');
      }
    }

    _logger.i('Initialization validation completed');
    _logger.d('Context summary: ${context.getSummary()}');
  }

  /// Cleanup resources on initialization failure
  static Future<void> _cleanupOnFailure(InitializationContext context) async {
    try {
      _logger.w('Performing cleanup after initialization failure');

      // Cleanup auth initializer if available
      if (context.container != null) {
        try {
          final authInitializer = context.container!.read(
            authInitializerProvider,
          );
          await authInitializer.cleanup();
        } catch (e) {
          _logger.w('Auth cleanup failed: $e');
        }
      }

      // Close database if opened
      context.objectBox?.close();

      // Clear context data
      context.clearData();

      _logger.i('Cleanup completed');
    } catch (e) {
      _logger.e('Error during cleanup: $e');
      // Don't rethrow cleanup errors
    }
  }
}
