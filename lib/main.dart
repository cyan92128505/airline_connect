import 'package:app/core/constant/constant.dart';
import 'package:app/features/shared/infrastructure/database/mock_data_seeder.dart';
import 'package:app/features/shared/presentation/app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:app/core/di/dependency_injection.dart';
import 'package:logger/logger.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Authentication pre-initialization imports
import 'package:app/features/member/infrastructure/repositories/secure_storage_repository_impl.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';

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

    // Create ProviderContainer for the app
    final container = ProviderContainer(
      overrides: [objectBoxProvider.overrideWithValue(objectBox)],
    );

    // Initialize authentication state after container is created
    await _initializeAuthStateAfterContainer(container);

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const AirlineConnectApp(),
      ),
    );
  } catch (e, stackTrace) {
    // Critical initialization failure handling
    _handleInitializationFailure(e, stackTrace);
  }
}

/// Initialize authentication state after ProviderContainer is created
/// This approach ensures proper initialization order
Future<void> _initializeAuthStateAfterContainer(
  ProviderContainer container,
) async {
  _logger.i('Initializing authentication state after container creation...');

  try {
    // Use existing secure storage repository
    final secureStorage = SecureStorageRepositoryImpl();

    // Try to restore member from secure storage
    final memberResult = await secureStorage.getMember();

    final initialAuthState = memberResult.fold(
      (failure) {
        _logger.i('No existing session found: ${failure.message}');
        // Return unauthenticated state (initialized but not authenticated)
        return MemberAuthState(
          member: MemberDTOExtensions.unauthenticated(),
          isAuthenticated: false,
          isInitialized: true,
        );
      },
      (member) {
        if (member != null) {
          _logger.i(
            'Session restored for member: ${member.memberNumber.value}',
          );
          // Convert domain member to DTO and mark as authenticated
          return MemberAuthState(
            member: MemberDTOExtensions.fromDomain(member),
            isAuthenticated: true,
            isInitialized: true,
          );
        } else {
          _logger.i('No member found in secure storage');
          return MemberAuthState(
            member: MemberDTOExtensions.unauthenticated(),
            isAuthenticated: false,
            isInitialized: true,
          );
        }
      },
    );

    // Get the MemberAuthNotifier and initialize it with the restored state
    final authNotifier = container.read(memberAuthNotifierProvider.notifier);
    authNotifier.initializeWithRestoredState(initialAuthState);

    _logger.i('Authentication state initialized successfully');
  } catch (e, stackTrace) {
    _logger.e('Failed to initialize auth state: $e');
    _logger.e('StackTrace: $stackTrace');

    // Even if session restoration fails, we still provide initialized state
    final fallbackState = MemberAuthState(
      member: MemberDTOExtensions.unauthenticated(),
      isAuthenticated: false,
      isInitialized: true,
      errorMessage: 'Session restoration failed',
    );

    try {
      final authNotifier = container.read(memberAuthNotifierProvider.notifier);
      authNotifier.initializeWithRestoredState(fallbackState);
    } catch (e) {
      _logger.e('Failed to set fallback auth state: $e');
      // Continue anyway - the app will use default unauthenticated state
    }
  }
}

/// Initialize timezone database - MUST be called before any DateTime operations
Future<void> _initializeTimezone() async {
  try {
    _logger.i('Initializing timezone database...');

    // Initialize timezone database
    tz.initializeTimeZones();

    // Set local timezone
    tz.setLocalLocation(tz.getLocation(appDefaultLocation));

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
void _setupDemoData(ObjectBox objectBox) async {
  try {
    if (kDebugMode) {
      final seeder = MockDataSeeder(objectBox);

      if (!await seeder.verifyEssentialData()) {
        await seeder.seedMinimalMockData();
      }
    }
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
