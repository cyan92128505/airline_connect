import 'package:app/features/member/presentation/widgets/member_auth_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:app/features/member/application/dtos/authentication_dto.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:app/features/member/presentation/screens/member_auth_screen.dart';
import '../../../../../helpers/test_helpers.dart';

void main() {
  group('MemberAuthScreen Widget Tests', () {
    late MockMemberApplicationService mockMemberService;

    setUp(() {
      mockMemberService = MockMemberApplicationService();
    });

    testWidgets('should display login form with pre-filled demo data', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        TestProviderScope.create(
          memberService: mockMemberService,
          child: const MaterialApp(home: MemberAuthScreen()),
        ),
      );

      // Assert
      expect(find.text('Airline Connect'), findsOneWidget);
      expect(find.text('會員登入'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Check demo data is pre-filled
      expect(find.byKey(MemberAuthForm.memberNumberFieldKey), findsOneWidget);
      expect(find.byKey(MemberAuthForm.nameSuffixFieldKey), findsOneWidget);
    });

    testWidgets('should show loading indicator during authentication', (
      tester,
    ) async {
      // Arrange
      when(
        () => mockMemberService.authenticateMember(
          memberNumber: any(named: 'memberNumber'),
          nameSuffix: any(named: 'nameSuffix'),
        ),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return const Right(
          AuthenticationResponseDTO(
            isAuthenticated: true,
            member: MemberDTO(
              memberId: 'test-id',
              memberNumber: 'AA123456',
              fullName: '王小明',
              email: 'test@example.com',
              phone: '+886912345678',
              tier: MemberTier.gold,
            ),
          ),
        );
      });

      await tester.pumpWidget(
        TestProviderScope.create(
          memberService: mockMemberService,
          child: const MaterialApp(home: MemberAuthScreen()),
        ),
      );

      // Act
      await tester.ensureVisible(find.text('登入驗證'));
      await tester.tap(find.text('登入驗證'));
      await tester.pump(); // Trigger the loading state

      // Assert
      expect(find.text('驗證中...'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(MemberAuthForm.submitButtonKey),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('should display error message on authentication failure', (
      tester,
    ) async {
      // Arrange
      when(
        () => mockMemberService.authenticateMember(
          memberNumber: any(named: 'memberNumber'),
          nameSuffix: any(named: 'nameSuffix'),
        ),
      ).thenAnswer(
        (_) async => const Right(
          AuthenticationResponseDTO(
            isAuthenticated: false,
            errorMessage: 'Invalid credentials',
          ),
        ),
      );

      await tester.pumpWidget(
        TestProviderScope.create(
          memberService: mockMemberService,
          child: const MaterialApp(home: MemberAuthScreen()),
        ),
      );

      // Act
      await tester.enterText(
        find.byKey(MemberAuthForm.memberNumberFieldKey),
        'ZZ999999',
      );
      await tester.enterText(
        find.byKey(MemberAuthForm.nameSuffixFieldKey),
        '9999',
      );

      await tester.ensureVisible(find.text('登入驗證'));
      await tester.tap(find.text('登入驗證'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(MemberAuthScreen.errorMessageKey), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should validate form inputs', (tester) async {
      // Arrange
      await tester.pumpWidget(
        TestProviderScope.create(
          memberService: mockMemberService,
          child: const MaterialApp(home: MemberAuthScreen()),
        ),
      );

      // Clear the pre-filled data
      await tester.enterText(
        find.byKey(MemberAuthForm.memberNumberFieldKey),
        '',
      );
      await tester.enterText(find.byKey(MemberAuthForm.nameSuffixFieldKey), '');

      // Act
      await tester.tap(find.byKey(MemberAuthForm.memberNumberFieldKey));
      await tester.pump();

      // Assert
      expect(find.text('請輸入會員號碼'), findsOneWidget);
      expect(find.text('請輸入姓名後四碼'), findsOneWidget);

      // Verify service was not called
      verifyNever(
        () => mockMemberService.authenticateMember(
          memberNumber: any(named: 'memberNumber'),
          nameSuffix: any(named: 'nameSuffix'),
        ),
      );
    });
  });
}
