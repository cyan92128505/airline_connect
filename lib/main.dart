import 'package:app/core/bootstrap/app_bootstrap.dart';
import 'package:app/core/bootstrap/bootstrap_config.dart';
import 'package:app/features/shared/presentation/app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

BootstrapConfig _createBootstrapConfig() {
  if (kDebugMode) {
    return BootstrapConfig.development();
  } else {
    return BootstrapConfig.production();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Create bootstrap configuration based on environment
    final config = _createBootstrapConfig();

    // Initialize application through bootstrap service
    final container = await AppBootstrap.initialize(config);

    // Launch application with initialized container
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const AirlineConnectApp(),
      ),
    );
  } catch (error, stackTrace) {
    _handleCriticalFailure(error, stackTrace);
  }
}

/// Global navigator key for error dialog
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Handle critical initialization failures with fallback UI
void _handleCriticalFailure(Object error, StackTrace stackTrace) {
  _logger.e('CRITICAL: Application initialization failed');
  _logger.e('Error: $error');
  _logger.e('StackTrace: $stackTrace');

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  '應用程式初始化失敗',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '錯誤詳情：${error.toString()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Force restart application
                    main();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新啟動應用程式'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Show detailed error information
                    showDialog(
                      context: navigatorKey.currentContext!,
                      builder: (context) => AlertDialog(
                        title: const Text('詳細錯誤資訊'),
                        content: SingleChildScrollView(
                          child: Text('$error\n\n$stackTrace'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('關閉'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('查看詳細錯誤'),
                ),
              ],
            ),
          ),
        ),
      ),
      navigatorKey: navigatorKey,
    ),
  );
}
