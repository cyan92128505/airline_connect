import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:app/app/presentation/screens/main_screen.dart';
import 'package:app/features/shared/presentation/theme/app_theme.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:app/core/di/dependency_injection.dart';
import 'package:logger/logger.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final Logger _logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize timezone database before any DateTime operations
    await _initializeTimezone();

    // Initialize ObjectBox with validation
    final objectBox = await _initializeObjectBox();

    // Setup demo data after validation
    _setupDemoData(objectBox);

    // Configure system UI
    await _configureSystemUI();

    runApp(
      ProviderScope(
        overrides: [objectBoxProvider.overrideWithValue(objectBox)],
        child: const AirlineConnectApp(),
      ),
    );
  } catch (e, stackTrace) {
    // Critical initialization failure handling
    _handleInitializationFailure(e, stackTrace);
  }
}

/// Initialize timezone database - MUST be called before any DateTime operations
Future<void> _initializeTimezone() async {
  try {
    _logger.i('Initializing timezone database...');

    // Initialize timezone database
    tz.initializeTimeZones();

    // Set local timezone
    tz.setLocalLocation(tz.getLocation('Asia/Taipei'));

    _logger.i('Timezone database initialized successfully');
  } catch (e, stackTrace) {
    _logger.i('Failed to initialize timezone database: $e');
    _logger.i('StackTrace: $stackTrace');
    // Don't rethrow - let the app continue with default timezone handling
  }
}

/// Initialize ObjectBox with proper validation
Future<ObjectBox> _initializeObjectBox() async {
  final objectBox = await ObjectBox.create();

  // Validate store state immediately after creation
  if (objectBox.store.isClosed()) {
    throw StateError('ObjectBox store failed to initialize properly');
  }

  // Test basic operations to ensure all boxes are accessible
  try {
    objectBox.memberBox.isEmpty();
    objectBox.flightBox.isEmpty();
    objectBox.boardingPassBox.isEmpty();
  } catch (e) {
    objectBox.close(); // Clean up on failure
    throw StateError('ObjectBox boxes are not accessible: $e');
  }

  return objectBox;
}

/// Setup demo data with error handling
void _setupDemoData(ObjectBox objectBox) {
  try {
    objectBox.setupDemoMember();
  } catch (e) {
    // Log but don't fail - demo data is not critical
    _logger.i('Warning: Failed to setup demo data: $e');
  }
}

/// Configure system UI settings
Future<void> _configureSystemUI() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

/// Handle critical initialization failures
void _handleInitializationFailure(Object error, StackTrace stackTrace) {
  _logger.i('CRITICAL: App initialization failed');
  _logger.i('Error: $error');
  _logger.i('StackTrace: $stackTrace');

  // In production, you might want to show an error screen
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('應用程式初始化失敗'),
              const SizedBox(height: 8),
              Text('錯誤: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restart the app
                  main();
                },
                child: const Text('重新啟動'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AirlineConnectApp extends StatelessWidget {
  const AirlineConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AirlineConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
