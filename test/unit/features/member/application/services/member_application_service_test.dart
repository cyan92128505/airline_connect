import 'package:app/features/member/application/use_cases/logout_member_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/member/application/services/member_application_service.dart';
import 'package:app/features/member/application/dtos/authentication_dto.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/application/use_cases/authenticate_member_use_case.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';

import 'member_application_service_test.mocks.dart';

@GenerateMocks([AuthenticateMemberUseCase, LogoutMemberUseCase])
void main() {
  late MemberApplicationService service;
  late MockAuthenticateMemberUseCase mockAuthenticateUseCase;
  late MockLogoutMemberUseCase mockLogoutMemberUseCase;

  setUp(() {
    mockAuthenticateUseCase = MockAuthenticateMemberUseCase();
    mockLogoutMemberUseCase = MockLogoutMemberUseCase();

    service = MemberApplicationService(
      mockAuthenticateUseCase,
      mockLogoutMemberUseCase,
    );
  });

  group('MemberApplicationService Tests', () {
    group('authenticateMember', () {
      test('should authenticate member successfully', () async {
        // Arrange
        final response = AuthenticationResponseDTO(
          isAuthenticated: true,
          member: MemberDTO(
            memberId: 'member-001',
            memberNumber: 'BR857123',
            fullName: 'John Chen',
            email: 'john.chen@example.com',
            phone: '+886912345678',
            tier: MemberTier.gold,
          ),
        );

        when(
          mockAuthenticateUseCase.call(any),
        ).thenAnswer((_) async => Right(response));

        // Act
        final result = await service.authenticateMember(
          memberNumber: 'BR857123',
          nameSuffix: 'CHEN',
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (response) => {
            expect(response.isAuthenticated, isTrue),
            expect(response.member, isNotNull),
          },
        );
      });

      test('should handle authentication failure', () async {
        // Arrange
        final failure = ValidationFailure('Invalid credentials');
        when(
          mockAuthenticateUseCase.call(any),
        ).thenAnswer((_) async => Left(failure));

        // Act
        final result = await service.authenticateMember(
          memberNumber: 'BR857123',
          nameSuffix: 'CHEN',
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure.message, equals('Invalid credentials')),
          (response) => fail('Expected failure but got success'),
        );
      });
    });
  });
}
