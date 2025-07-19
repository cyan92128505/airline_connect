import 'dart:io';
import 'package:app/app/presentation/app.dart';
import 'package:app/app/presentation/routes/app_routes.dart';
import 'package:app/core/di/dependency_injection.dart';
import 'package:app/features/boarding_pass/presentation/screens/boarding_pass_screen.dart';
import 'package:app/features/member/presentation/screens/member_auth_screen.dart';
import 'package:app/features/member/presentation/widgets/member_auth_form.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:app/objectbox.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest.dart' as tz;

// Import actual app components
import 'package:app/features/member/infrastructure/entities/member_entity.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Go Router Authentication Flow Integration Tests', () {
    late ObjectBox objectBox;
    late Directory tempDir;

    setUpAll(() async {
      tz.initializeTimeZones();

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
      // Create app with real router and test database
      final app = TestAppWithGoRouter(objectBox: objectBox);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify initial route redirects to auth screen for unauthenticated user
      expect(find.byType(MemberAuthScreen), findsOneWidget);
      expect(find.text('會員登入'), findsOneWidget);

      // Verify current route is member auth
      final context = tester.element(find.byType(MemberAuthScreen));
      final currentLocation = GoRouterState.of(context).uri.path;
      expect(currentLocation, equals(AppRoutes.memberAuth));

      // Find input fields
      final memberNumberField = find.byType(TextFormField).first;
      final nameSuffixField = find.byType(TextFormField).last;

      // Enter valid test credentials
      await tester.enterText(memberNumberField, 'AA123456');
      await tester.enterText(nameSuffixField, '1234');
      await tester.pumpAndSettle();

      // Tap login button
      await tester.ensureVisible(find.byKey(MemberAuthForm.submitButtonKey));
      final loginButton = find.byKey(MemberAuthForm.submitButtonKey);
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pump();

      // Wait for authentication to complete
      int attempts = 0;
      while (attempts < 10 &&
          find.byType(BoardingPassScreen).evaluate().isEmpty) {
        await tester.pump(const Duration(milliseconds: 100));
        attempts++;
      }

      // After successful authentication, should be redirected to boarding pass
      expect(
        find.byType(BoardingPassScreen),
        findsOneWidget,
        reason: 'Should navigate to boarding pass after successful auth',
      );

      // Verify route changed to boarding pass
      final newContext = tester.element(find.byType(BoardingPassScreen));
      final newLocation = GoRouterState.of(newContext).uri.path;
      expect(newLocation, equals(AppRoutes.boardingPass));
    });

    testWidgets('Invalid credentials remain on auth screen with error', (
      tester,
    ) async {
      final app = TestAppWithGoRouter(objectBox: objectBox);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify starting on auth screen
      expect(find.byType(MemberAuthScreen), findsOneWidget);

      // Enter invalid credentials
      final memberNumberField = find.byType(TextFormField).first;
      final nameSuffixField = find.byType(TextFormField).last;

      await tester.enterText(memberNumberField, 'INVALID');
      await tester.enterText(nameSuffixField, '9999');
      await tester.pumpAndSettle();

      // Submit authentication
      await tester.ensureVisible(find.text('登入驗證'));
      await tester.tap(find.text('登入驗證'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should remain on auth screen
      expect(find.byType(MemberAuthScreen), findsOneWidget);

      // Verify route hasn't changed
      final context = tester.element(find.byType(MemberAuthScreen));
      final currentLocation = GoRouterState.of(context).uri.path;
      expect(currentLocation, equals(AppRoutes.memberAuth));

      // Look for error indicators
      bool errorFound = false;
      if (find.byIcon(Icons.error_outline).evaluate().isNotEmpty) {
        errorFound = true;
      } else if (find.textContaining('失敗').evaluate().isNotEmpty) {
        errorFound = true;
      } else if (find.textContaining('錯誤').evaluate().isNotEmpty) {
        errorFound = true;
      }

      expect(
        errorFound,
        isTrue,
        reason: 'Should show error for invalid credentials',
      );
    });

    testWidgets('Route protection works correctly', (tester) async {
      final app = TestAppWithGoRouter(objectBox: objectBox);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Initially unauthenticated, should be on auth screen
      expect(find.byType(MemberAuthScreen), findsOneWidget);

      // Try to navigate to protected route via bottom navigation
      final qrScannerTab = find.byIcon(Icons.qr_code_scanner);
      if (qrScannerTab.evaluate().isNotEmpty) {
        await tester.tap(qrScannerTab);
        await tester.pumpAndSettle();

        // Should redirect back to auth screen
        expect(find.byType(MemberAuthScreen), findsOneWidget);

        final context = tester.element(find.byType(MemberAuthScreen));
        final currentLocation = GoRouterState.of(context).uri.path;
        expect(currentLocation, equals(AppRoutes.memberAuth));
      }
    });

    testWidgets('Bottom navigation updates correctly after authentication', (
      tester,
    ) async {
      final app = TestAppWithGoRouter(objectBox: objectBox);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Authenticate first
      final memberNumberField = find.byType(TextFormField).first;
      final nameSuffixField = find.byType(TextFormField).last;

      await tester.enterText(memberNumberField, 'AA123456');
      await tester.enterText(nameSuffixField, '1234');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('登入驗證'));
      await tester.tap(find.text('登入驗證'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should be on boarding pass screen
      expect(find.byType(BoardingPassScreen), findsOneWidget);

      // Test navigation between protected routes
      final qrScannerTab = find.byIcon(Icons.qr_code_scanner);
      if (qrScannerTab.evaluate().isNotEmpty) {
        await tester.tap(qrScannerTab);
        await tester.pumpAndSettle();

        // Should successfully navigate to QR scanner
        // Note: Exact screen type depends on your QRScannerScreen implementation
        final context = tester.element(find.byType(Scaffold));
        final currentLocation = GoRouterState.of(context).uri.path;
        expect(currentLocation, equals(AppRoutes.qrScanner));
      }
    });

    testWidgets('Form validation works correctly', (tester) async {
      final app = TestAppWithGoRouter(objectBox: objectBox);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Clear any pre-filled data
      final memberNumberField = find.byType(TextFormField).first;
      final nameSuffixField = find.byType(TextFormField).last;

      await tester.enterText(memberNumberField, '');
      await tester.enterText(nameSuffixField, '');
      await tester.pumpAndSettle();

      // Try to submit empty form
      await tester.ensureVisible(find.text('登入驗證'));
      await tester.tap(find.text('登入驗證'));
      await tester.pumpAndSettle();

      // Should show validation errors and remain on auth screen
      expect(find.byType(MemberAuthScreen), findsOneWidget);

      bool validationFound = false;
      if (find.textContaining('請輸入').evaluate().isNotEmpty) {
        validationFound = true;
      } else if (find.textContaining('必填').evaluate().isNotEmpty) {
        validationFound = true;
      } else if (find.textContaining('不能為空').evaluate().isNotEmpty) {
        validationFound = true;
      }

      expect(
        validationFound,
        isTrue,
        reason: 'Should show validation errors for empty form',
      );
    });
  });
}

/// Test app that uses real go_router with test database
class TestAppWithGoRouter extends ConsumerWidget {
  final ObjectBox objectBox;

  const TestAppWithGoRouter({super.key, required this.objectBox});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [objectBoxProvider.overrideWithValue(objectBox)],
      child: const AirlineConnectApp(),
    );
  }
}

/// Seed test data for authentication testing
Future<void> _seedTestData(ObjectBox objectBox) async {
  // Clear existing data
  objectBox.memberBox.removeAll();

  // Add test member with specific credentials for testing
  final testMember = MemberEntity()
    ..memberNumber = 'AA123456'
    ..fullName =
        '測試用戶1234' // Last 4 chars should be "1234" for name suffix
    ..email = 'test@example.com'
    ..phone = '+886912345678'
    ..tier = 'GOLD'
    ..lastLoginAt = DateTime.now();

  objectBox.memberBox.put(testMember);

  // Add another test member for additional testing scenarios
  final testMember2 = MemberEntity()
    ..memberNumber = 'BB789012'
    ..fullName = '另一個測試用戶5678'
    ..email = 'test2@example.com'
    ..phone = '+886987654321'
    ..tier = 'SILVER'
    ..lastLoginAt = DateTime.now().subtract(const Duration(days: 1));

  objectBox.memberBox.put(testMember2);

  debugPrint('Test data seeded: ${objectBox.memberBox.count()} members');

  // Log test credentials for debugging
  debugPrint('Test credentials: AA123456 / 1234');
  debugPrint('Test credentials: BB789012 / 5678');
}
