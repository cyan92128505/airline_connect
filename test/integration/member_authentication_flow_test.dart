import 'dart:io';
import 'package:app/app/presentation/screens/main_screen.dart';
import 'package:app/objectbox.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:objectbox_flutter_libs/objectbox_flutter_libs.dart';

// Import actual app components
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:app/features/member/presentation/screens/member_auth_screen.dart';
import 'package:app/features/member/infrastructure/entities/member_entity.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Real Member Authentication Integration Tests', () {
    late ObjectBox objectBox;
    late Directory tempDir;

    setUpAll(() async {
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

    testWidgets('Complete authentication flow with real services', (
      tester,
    ) async {
      // Create real app with test database
      final app = TestAppWithRealServices(objectBox: objectBox);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify initial auth screen
      expect(find.byType(MemberAuthScreen), findsOneWidget);
      expect(find.text('會員登入'), findsOneWidget);

      // Find input fields
      final memberNumberField = find.byType(TextFormField).first;
      final nameSuffixField = find.byType(TextFormField).last;

      // Enter valid test credentials
      await tester.enterText(memberNumberField, 'AA123456');
      await tester.enterText(nameSuffixField, '1234');
      await tester.pumpAndSettle();

      // Tap login button
      final loginButton = find.text('登入驗證');
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);

      // Wait for authentication process
      await tester.pump(const Duration(milliseconds: 100)); // Show loading

      // Check for loading state or success
      final hasLoadingText = find.text('驗證中...').evaluate().isNotEmpty;
      if (hasLoadingText) {
        expect(find.text('驗證中...'), findsOneWidget);
      }

      await tester.pumpAndSettle(const Duration(seconds: 3)); // Complete auth

      // Verify navigation to main screen
      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Invalid credentials show error with real services', (
      tester,
    ) async {
      final app = TestAppWithRealServices(objectBox: objectBox);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Enter invalid credentials
      final memberNumberField = find.byType(TextFormField).first;
      final nameSuffixField = find.byType(TextFormField).last;

      await tester.enterText(memberNumberField, 'INVALID');
      await tester.enterText(nameSuffixField, '9999');
      await tester.pumpAndSettle();

      // Submit authentication
      await tester.tap(find.text('登入驗證'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should remain on auth screen with error
      expect(find.byType(MemberAuthScreen), findsOneWidget);

      // Look for error indicators (icon or text)
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

    testWidgets('Form validation works correctly', (tester) async {
      final app = TestAppWithRealServices(objectBox: objectBox);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Clear any pre-filled data
      final memberNumberField = find.byType(TextFormField).first;
      final nameSuffixField = find.byType(TextFormField).last;

      await tester.enterText(memberNumberField, '');
      await tester.enterText(nameSuffixField, '');
      await tester.pumpAndSettle();

      // Try to submit empty form
      await tester.tap(find.text('登入驗證'));
      await tester.pumpAndSettle();

      // Should show validation errors
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

/// Test app that uses real services with test database
class TestAppWithRealServices extends ConsumerWidget {
  final ObjectBox objectBox;

  const TestAppWithRealServices({super.key, required this.objectBox});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        // Override ObjectBox provider with test instance
        // Note: You'll need to check your actual provider structure
        // This is a placeholder for the actual provider override syntax
      ],
      child: MaterialApp(
        title: 'AirlineConnect Integration Test',
        theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
        home: MemberAuthScreen(),
        routes: {'/main': (context) => MainScreen()},
      ),
    );
  }
}

/// Seed test data
Future<void> _seedTestData(ObjectBox objectBox) async {
  // Clear existing data
  objectBox.memberBox.removeAll();

  // Add test member
  final testMember = MemberEntity()
    ..memberNumber = 'AA123456'
    ..fullName = '測試用戶'
    ..email = 'test@example.com'
    ..phone = '+886912345678'
    ..tier = 'GOLD'
    ..lastLoginAt = DateTime.now();

  objectBox.memberBox.put(testMember);

  debugPrint('Test data seeded: ${objectBox.memberBox.count()} members');
}
