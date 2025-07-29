import 'dart:async';

import 'package:app/core/bootstrap/bootstrap_config.dart';
import 'package:app/core/bootstrap/initialization_step.dart';
import 'package:app/core/bootstrap/steps/auth_initialization_step.dart';
import 'package:app/core/bootstrap/steps/database_initialization_step.dart';
import 'package:app/core/bootstrap/steps/demo_data_initialization_step.dart';
import 'package:app/core/bootstrap/steps/system_ui_initialization_step.dart';
import 'package:app/core/bootstrap/steps/timezone_initialization_step.dart';
import 'package:app/core/di/dependency_injection.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
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
    final failures = <String, Object>{};

    // Define initialization steps in dependency order
    final steps = <InitializationStep>[
      TimezoneInitializationStep(config.timezoneName),
      SystemUIInitializationStep(),
      DatabaseInitializationStep(),
      if (config.enableDemoData) DemoDataInitializationStep(),
      AuthInitializationStep(),
    ];

    // Execute initialization steps sequentially
    for (final step in steps) {
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
          failures[step.name] = e;

          _logger.w('Non-critical step ${step.name} failed, continuing...');
        }
      }
    }

    if (failures.isNotEmpty) {
      _logger.w(
        'Initialization completed with ${failures.length} non-critical failures',
      );
    }

    // Create provider container with initialized dependencies
    final container = ProviderContainer(
      overrides: [
        // Override providers with initialized instances
        if (context.objectBox != null)
          objectBoxProvider.overrideWithValue(context.objectBox!),
      ],
    );

    // Get the MemberAuthNotifier and initialize it with the restored state
    final authNotifier = container.read(memberAuthNotifierProvider.notifier);
    authNotifier.initializeWithRestoredState(
      context.getData('initialAuthState'),
    );

    _logger.i('Application bootstrap completed successfully');
    return container;
  }
}
