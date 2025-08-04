import 'package:app/di/dependency_injection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/member/application/dtos/authentication_dto.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import '../../../../../helpers/test_helpers.dart';

void main() {
  group('MemberAuthNotifier', () {
    late ProviderContainer container;
    late MockMemberApplicationService mockMemberService;

    setUp(() {
      mockMemberService = MockMemberApplicationService();

      // Set up default mock behaviors
      when(
        () => mockMemberService.logout(any()),
      ).thenAnswer((_) async => const Right(true));

      container = ProviderContainer(
        overrides: [
          memberApplicationServiceProvider.overrideWithValue(mockMemberService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('authenticateMember', () {
      test(
        'should update state to loading when authentication starts',
        () async {
          // Arrange
          when(
            () => mockMemberService.authenticateMember(
              memberNumber: any(named: 'memberNumber'),
              nameSuffix: any(named: 'nameSuffix'),
            ),
          ).thenAnswer(
            (_) async => Right(
              const AuthenticationResponseDTO(
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
            ),
          );

          final notifier = container.read(memberAuthNotifierProvider.notifier);

          // Act
          final future = notifier.authenticateMember(
            memberNumber: 'AA123456',
            nameSuffix: '1234',
          );

          // Assert initial loading state
          expect(container.read(memberAuthNotifierProvider).isLoading, isTrue);

          await future;
        },
      );

      test(
        'should update state with member data on successful authentication',
        () async {
          // Arrange
          const expectedMember = MemberDTO(
            memberId: 'test-id',
            memberNumber: 'AA123456',
            fullName: '王小明',
            email: 'test@example.com',
            phone: '+886912345678',
            tier: MemberTier.gold,
          );

          when(
            () => mockMemberService.authenticateMember(
              memberNumber: any(named: 'memberNumber'),
              nameSuffix: any(named: 'nameSuffix'),
            ),
          ).thenAnswer(
            (_) async => const Right(
              AuthenticationResponseDTO(
                isAuthenticated: true,
                member: expectedMember,
              ),
            ),
          );

          final notifier = container.read(memberAuthNotifierProvider.notifier);

          // Act
          await notifier.authenticateMember(
            memberNumber: 'AA123456',
            nameSuffix: '1234',
          );

          // Assert
          final state = container.read(memberAuthNotifierProvider);
          expect(state.isLoading, isFalse);
          expect(state.isAuthenticated, isTrue);
          expect(state.member, equals(expectedMember));
          expect(state.errorMessage, isNull);
        },
      );

      test(
        'should update state with error on authentication failure',
        () async {
          // Arrange
          when(
            () => mockMemberService.authenticateMember(
              memberNumber: any(named: 'memberNumber'),
              nameSuffix: any(named: 'nameSuffix'),
            ),
          ).thenAnswer(
            (_) async => Left(ValidationFailure('Member not found')),
          );

          final notifier = container.read(memberAuthNotifierProvider.notifier);

          // Act
          await notifier.authenticateMember(
            memberNumber: 'INVALID',
            nameSuffix: '0000',
          );

          // Assert
          final state = container.read(memberAuthNotifierProvider);
          expect(state.isLoading, isFalse);
          expect(state.isAuthenticated, isFalse);
          expect(state.member!.isUnauthenticated, isTrue);
          expect(state.errorMessage, equals('會員號碼或姓名後四碼錯誤'));
        },
      );

      test('should validate input parameters', () async {
        // Arrange
        final notifier = container.read(memberAuthNotifierProvider.notifier);

        // Act
        await notifier.authenticateMember(memberNumber: '', nameSuffix: '1234');

        // Assert
        final state = container.read(memberAuthNotifierProvider);
        expect(state.isAuthenticated, isFalse);
        expect(state.errorMessage, equals('會員號碼和姓名後四碼不能為空'));

        // Verify service was not called
        verifyNever(
          () => mockMemberService.authenticateMember(
            memberNumber: any(named: 'memberNumber'),
            nameSuffix: any(named: 'nameSuffix'),
          ),
        );
      });
    });

    group('logout', () {
      test('should clear authentication state', () async {
        when(
          () => mockMemberService.logout(any()),
        ).thenAnswer((_) async => const Right(true));

        // Arrange - Set initial authenticated state
        when(
          () => mockMemberService.authenticateMember(
            memberNumber: any(named: 'memberNumber'),
            nameSuffix: any(named: 'nameSuffix'),
          ),
        ).thenAnswer(
          (_) async => const Right(
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
          ),
        );

        final notifier = container.read(memberAuthNotifierProvider.notifier);
        await notifier.authenticateMember(
          memberNumber: 'AA123456',
          nameSuffix: '1234',
        );

        // Verify initial state
        expect(
          container.read(memberAuthNotifierProvider).isAuthenticated,
          isTrue,
        );

        // Act
        notifier.logout();

        // Assert
        final state = container.read(memberAuthNotifierProvider);
        expect(state.isAuthenticated, isFalse);
        expect(state.member!.isUnauthenticated, isTrue);
        expect(state.errorMessage, isNull);
      });
    });
  });
}
