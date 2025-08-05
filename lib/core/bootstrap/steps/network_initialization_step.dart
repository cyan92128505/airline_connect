import 'dart:async';

import 'package:app/core/bootstrap/contracts/initialization_context.dart';
import 'package:app/core/bootstrap/initialization_step.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

/// Initialize network connectivity monitoring and permissions
class NetworkInitializationStep extends InitializationStep {
  static final Logger _logger = Logger();

  const NetworkInitializationStep()
    : super(name: 'Network Connectivity Setup', isCritical: false);

  @override
  Future<void> execute(InitializationContext context) async {
    try {
      // Check if connectivity service is available
      await _verifyConnectivityService();

      // Perform initial network state detection
      await _performInitialNetworkCheck(context);

      _logger.i('Network initialization completed successfully');
    } catch (e, stackTrace) {
      _logger.e('Network initialization failed: $e', stackTrace: stackTrace);

      // Store initialization error in context for later reference
      context.setData('network_init_error', e.toString());

      // Don't rethrow - network monitoring failure shouldn't prevent app startup
      // The app can still function in offline-first mode
    }
  }

  /// Verify that connectivity service is available
  Future<void> _verifyConnectivityService() async {
    try {
      final connectivity = Connectivity();

      // Test connectivity service availability
      await connectivity.checkConnectivity().timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException(
          'Connectivity service timeout',
          Duration(seconds: 5),
        ),
      );

      _logger.d('Connectivity service verified');
    } catch (e) {
      _logger.w('Connectivity service verification failed: $e');
      rethrow;
    }
  }

  /// Perform initial network state check and store in context
  Future<void> _performInitialNetworkCheck(
    InitializationContext context,
  ) async {
    try {
      final connectivity = Connectivity();
      final results = await connectivity.checkConnectivity();

      final isOnline =
          results.isNotEmpty && results.first != ConnectivityResult.none;
      final connectionType = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;

      // Store initial network state in context
      context.setData('initial_network_online', isOnline);
      context.setData('initial_connection_type', connectionType.toString());

      _logger.i(
        'Initial network state: ${isOnline ? 'online' : 'offline'} ($connectionType)',
      );

      // If offline, log warning but don't fail
      if (!isOnline) {
        _logger.w(
          'App starting in offline mode - limited functionality available',
        );
      }
    } catch (e) {
      _logger.e('Initial network check failed: $e');

      // Assume offline if check fails
      context.setData('initial_network_online', false);
      context.setData('initial_connection_type', 'unknown');
    }
  }
}
