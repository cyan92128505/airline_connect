import 'dart:io';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import 'package:app/features/shared/presentation/app.dart';
import 'package:app/features/shared/presentation/routes/app_routes.dart';
import 'package:app/di/dependency_injection.dart';
import 'package:app/features/boarding_pass/presentation/screens/boarding_pass_screen.dart';
import 'package:app/features/member/presentation/screens/member_auth_screen.dart';
import 'package:app/features/member/presentation/widgets/member_auth_form.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:app/features/shared/presentation/screens/splash_screen.dart';
import 'package:app/objectbox.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/timezone.dart' as tz;

// Import actual app components and new auth initialization
import 'package:app/features/member/infrastructure/entities/member_entity.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';

// NEW: Mock imports
import 'package:app/features/member/domain/repositories/secure_storage_repository.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:dartz/dartz.dart';

import '../helpers/test_timezone_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Go Router Authentication Flow Integration Tests', () {
    late ObjectBox objectBox;
    late Directory tempDir;

    setUpAll(() async {
      TestTimezoneHelper.setupForTesting();

      // Create test database in temporary directory
      tempDir = await Directory.systemTemp.createTemp(
        'objectbox_integration_test_',
      );

      try {
        // Initialize ObjectBox with test database
        final store = await openStore(directory: tempDir.path);
        objectBox = ObjectBox.createFromStore(store);

        // Seed test data
        await _seedTestData(objectBox);

        debugPrint('Test ObjectBox initialized at: ${tempDir.path}');
      } catch (e) {
        debugPrint('Failed to initialize test ObjectBox: $e');
        rethrow;
      }
    });

    tearDownAll(() async {
      // Cleanup test database
      objectBox.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('Complete authentication flow with go_router navigation', (
      tester,
    ) async {
      // Create app with test initialization and mock secure storage
      final app = await TestAppWithGoRouter.create(
        objectBox: objectBox,
        useMockSecureStorage: true,
      );
      await tester.pumpWidget(app);

      // Wait for splash screen to appear
      expect(find.byType(SplashScreen), findsOneWidget);
      debugPrint('✓ Splash screen appeared');

      // Wait for initialization to complete and splash to finish
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // After initialization, should redirect to auth screen for unauthenticated user
      expect(find.byType(MemberAuthScreen), findsOneWidget);
      expect(find.text('會員登入'), findsOneWidget);
      debugPrint('✓ Redirected to auth screen');

      // Verify current route is member auth
      final context = tester.element(find.byType(MemberAuthScreen));
      final currentLocation = GoRouterState.of(context).uri.path;
      expect(currentLocation, equals(AppRoutes.memberAuth));

      // Find input fields using fallback approach
      final memberNumberInput = _findInputField(
        tester,
        'member_number_field',
        0,
      );
      final nameSuffixInput = _findInputField(tester, 'name_suffix_field', 1);

      // Enter valid test credentials
      await tester.enterText(memberNumberInput, 'AA123456');
      await tester.enterText(nameSuffixInput, '1234');
      await tester.pumpAndSettle();
      debugPrint('✓ Entered credentials');

      // Find and tap login button
      final loginButton = _findLoginButton(tester);
      expect(loginButton, findsOneWidget);
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      debugPrint('✓ Tapped login button');

      // Wait for authentication request to start
      await tester.pump();

      // Wait for authentication to complete and navigation to occur
      bool foundBoardingPassScreen = false;
      for (int attempt = 0; attempt < 100; attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(BoardingPassScreen).evaluate().isNotEmpty) {
          foundBoardingPassScreen = true;
          debugPrint('✓ Found boarding pass screen after ${attempt * 100}ms');
          break;
        }
      }

      // Verify successful navigation to boarding pass screen
      expect(
        foundBoardingPassScreen,
        isTrue,
        reason:
            'Should navigate to boarding pass after successful authentication',
      );

      expect(
        find.byType(BoardingPassScreen),
        findsOneWidget,
        reason: 'BoardingPassScreen should be displayed after successful auth',
      );

      // Verify route changed to boarding pass
      final newContext = tester.element(find.byType(BoardingPassScreen));
      final newLocation = GoRouterState.of(newContext).uri.path;
      expect(newLocation, equals(AppRoutes.boardingPass));
      debugPrint('✓ Successfully navigated to boarding pass screen');
    });

    testWidgets('Session restoration works with mock storage', (tester) async {
      // Create app with mock storage that has existing session
      final mockStorage = MockSecureStorageRepository();

      // Simulate existing member session
      final existingMember = _createTestMember();
      mockStorage.setMockMember(existingMember);

      final app = await TestAppWithGoRouter.create(
        objectBox: objectBox,
        useMockSecureStorage: true,
        mockSecureStorage: mockStorage,
      );
      await tester.pumpWidget(app);

      // Wait for splash screen
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Should directly go to boarding pass (authenticated)
      expect(find.byType(BoardingPassScreen), findsOneWidget);
      debugPrint(
        '✓ Successfully restored session and navigated to main screen',
      );
    });
  });
}

/// Mock Secure Storage Repository for testing
class MockSecureStorageRepository implements SecureStorageRepository {
  Member? _mockMember;
  Map<String, dynamic> _mockPreferences = {};

  void setMockMember(Member? member) {
    _mockMember = member;
  }

  @override
  Future<Either<Failure, void>> saveMember(Member member) async {
    _mockMember = member;
    return const Right(null);
  }

  @override
  Future<Either<Failure, Member?>> getMember() async {
    return Right(_mockMember);
  }

  @override
  Future<Either<Failure, bool>> hasValidMember() async {
    return Right(_mockMember != null);
  }

  @override
  Future<Either<Failure, void>> clearMember() async {
    _mockMember = null;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> clearAll() async {
    _mockMember = null;
    _mockPreferences.clear();
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveAppPreferences(
    Map<String, dynamic> preferences,
  ) async {
    _mockPreferences = Map.from(preferences);
    return const Right(null);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAppPreferences() async {
    return Right(Map.from(_mockPreferences));
  }

  // Implement other required methods with mock behavior
  @override
  Future<Either<Failure, void>> cleanupExpiredSessions() async =>
      const Right(null);

  @override
  Future<Either<Failure, MemberNumber?>> getLastMemberNumber() async =>
      const Right(null);

  @override
  Future<Either<Failure, StorageStatistics>> getStatistics() async {
    return Right(
      StorageStatistics(
        hasCurrentMember: _mockMember != null,
        hasLastMemberNumber: false,
        hasAppPreferences: _mockPreferences.isNotEmpty,
        currentMemberSize: _mockMember != null ? 100 : 0,
        lastChecked: DateTime.now(),
      ),
    );
  }

  @override
  Future<Either<Failure, void>> setAutoLoginEnabled(
    memberNumber,
    bool enabled,
  ) async => const Right(null);

  @override
  Future<Either<Failure, void>> updateMemberActivity() async =>
      const Right(null);

  @override
  Future<Either<Failure, bool>> validateIntegrity() async => const Right(true);
}

/// Test app that properly initializes authentication like the real app
class TestAppWithGoRouter extends ConsumerWidget {
  final ObjectBox objectBox;
  final ProviderContainer container;

  const TestAppWithGoRouter._({
    required this.objectBox,
    required this.container,
  });

  /// Create test app with proper initialization
  static Future<Widget> create({
    required ObjectBox objectBox,
    bool useMockSecureStorage = false,
    MockSecureStorageRepository? mockSecureStorage,
  }) async {
    final overrides = <Override>[
      objectBoxProvider.overrideWithValue(objectBox),
    ];

    // Add mock secure storage if needed
    if (useMockSecureStorage) {
      final mockStorage = mockSecureStorage ?? MockSecureStorageRepository();
      overrides.add(
        secureStorageRepositoryProvider.overrideWithValue(mockStorage),
      );
    }

    // Create container with overrides
    final container = ProviderContainer(overrides: overrides);

    // Initialize authentication state
    await _initializeTestAuthState(container, useMockSecureStorage);

    return UncontrolledProviderScope(
      container: container,
      child: TestAppWithGoRouter._(objectBox: objectBox, container: container),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AirlineConnectApp();
  }

  /// Initialize authentication state for testing
  static Future<void> _initializeTestAuthState(
    ProviderContainer container,
    bool useMockSecureStorage,
  ) async {
    debugPrint(
      'Initializing test auth state (useMock: $useMockSecureStorage)...',
    );

    try {
      // Get secure storage repository (real or mock)
      final secureStorage = container.read(secureStorageRepositoryProvider);

      // Try to restore member from secure storage
      final memberResult = await secureStorage.getMember();

      final initialAuthState = memberResult.fold(
        (failure) {
          debugPrint('Test: No existing session found: ${failure.message}');
          return MemberAuthState(
            member: MemberDTOExtensions.unauthenticated(),
            isAuthenticated: false,
            isInitialized: true,
          );
        },
        (member) {
          if (member != null) {
            debugPrint(
              'Test: Session restored for member: ${member.memberNumber.value}',
            );
            return MemberAuthState(
              member: MemberDTOExtensions.fromDomain(member),
              isAuthenticated: true,
              isInitialized: true,
            );
          } else {
            debugPrint('Test: No member found in secure storage');
            return MemberAuthState(
              member: MemberDTOExtensions.unauthenticated(),
              isAuthenticated: false,
              isInitialized: true,
            );
          }
        },
      );

      // Get the MemberAuthNotifier and initialize it
      final authNotifier = container.read(memberAuthNotifierProvider.notifier);
      authNotifier.initializeWithRestoredState(initialAuthState);

      debugPrint('Test auth state initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Test: Failed to initialize auth state: $e');
      debugPrint('Test: StackTrace: $stackTrace');

      // Fallback to unauthenticated state
      final fallbackState = MemberAuthState(
        member: MemberDTOExtensions.unauthenticated(),
        isAuthenticated: false,
        isInitialized: true,
        errorMessage: 'Test session restoration failed',
      );

      try {
        final authNotifier = container.read(
          memberAuthNotifierProvider.notifier,
        );
        authNotifier.initializeWithRestoredState(fallbackState);
      } catch (e) {
        debugPrint('Test: Failed to set fallback auth state: $e');
      }
    }
  }
}

/// Helper function to create test member domain entity
Member _createTestMember() {
  final testMember = Member.fromPersistence(
    memberId: 'test-member-uuid-12345',
    memberNumber: 'AA123456',
    fullName: '測試使用者1234', // 後四碼是 "1234" 符合測試憑證
    tier: MemberTier.gold,
    email: 'test@example.com',
    phone: '+886912345678',
    createdAt: tz.TZDateTime.now(tz.local).subtract(const Duration(days: 30)),
    lastLoginAt: tz.TZDateTime.now(tz.local).subtract(const Duration(hours: 1)),
  );

  return testMember;
}

/// Helper function to find input fields with fallback
Finder _findInputField(WidgetTester tester, String keyName, int fallbackIndex) {
  final keyFinder = find.byKey(Key(keyName));
  if (keyFinder.evaluate().isNotEmpty) {
    return keyFinder;
  }

  // Fallback to type-based selection
  final textFields = find.byType(TextFormField);
  if (textFields.evaluate().length > fallbackIndex) {
    return textFields.at(fallbackIndex);
  }

  return textFields.first;
}

/// Helper function to find login button with multiple strategies
Finder _findLoginButton(WidgetTester tester) {
  // Try key-based first
  final keyFinder = find.byKey(MemberAuthForm.submitButtonKey);
  if (keyFinder.evaluate().isNotEmpty) {
    return keyFinder;
  }

  // Try text-based
  final textFinder = find.text('登入驗證');
  if (textFinder.evaluate().isNotEmpty) {
    return textFinder;
  }

  // Try button type
  final buttonFinder = find.byType(ElevatedButton);
  if (buttonFinder.evaluate().isNotEmpty) {
    return buttonFinder.last; // Assume login button is the last ElevatedButton
  }

  throw Exception('Could not find login button');
}

/// Seed test data for authentication testing
Future<void> _seedTestData(ObjectBox objectBox) async {
  // Clear existing data
  objectBox.memberBox.removeAll();

  // Add test member with specific credentials for testing
  final testMember = MemberEntity()
    ..memberNumber = 'AA123456'
    ..fullName =
        '測試使用者1234' // Last 4 chars should be "1234" for name suffix
    ..email = 'test@example.com'
    ..phone = '+886912345678'
    ..tier = 'GOLD'
    ..lastLoginAt = DateTime.now();

  objectBox.memberBox.put(testMember);

  // Add another test member for additional testing scenarios
  final testMember2 = MemberEntity()
    ..memberNumber = 'BB789012'
    ..fullName = '另一個測試使用者5678'
    ..email = 'test2@example.com'
    ..phone = '+886987654321'
    ..tier = 'SILVER'
    ..lastLoginAt = DateTime.now().subtract(const Duration(days: 1));

  objectBox.memberBox.put(testMember2);

  debugPrint('Test data seeded: ${objectBox.memberBox.count()} members');
  debugPrint('Test credentials: AA123456 / 1234');
  debugPrint('Test credentials: BB789012 / 5678');
}
