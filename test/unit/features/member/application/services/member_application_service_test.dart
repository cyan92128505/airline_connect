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
import 'package:app/features/member/application/use_cases/get_member_profile_use_case.dart';
import 'package:app/features/member/application/use_cases/register_member_use_case.dart';
import 'package:app/features/member/application/use_cases/update_member_contact_use_case.dart';
import 'package:app/features/member/application/use_cases/upgrade_member_tier_use_case.dart';
import 'package:app/features/member/application/use_cases/validate_member_eligibility_use_case.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';

import 'member_application_service_test.mocks.dart';

@GenerateMocks([
  AuthenticateMemberUseCase,
  GetMemberProfileUseCase,
  RegisterMemberUseCase,
  UpdateMemberContactUseCase,
  UpgradeMemberTierUseCase,
  ValidateMemberEligibilityUseCase,
  LogoutMemberUseCase,
])
void main() {
  late MemberApplicationService service;
  late MockAuthenticateMemberUseCase mockAuthenticateUseCase;
  late MockGetMemberProfileUseCase mockGetProfileUseCase;
  late MockRegisterMemberUseCase mockRegisterUseCase;
  late MockUpdateMemberContactUseCase mockUpdateContactUseCase;
  late MockUpgradeMemberTierUseCase mockUpgradeTierUseCase;
  late MockValidateMemberEligibilityUseCase mockValidateEligibilityUseCase;
  late MockLogoutMemberUseCase mockLogoutMemberUseCase;

  setUp(() {
    mockAuthenticateUseCase = MockAuthenticateMemberUseCase();
    mockGetProfileUseCase = MockGetMemberProfileUseCase();
    mockRegisterUseCase = MockRegisterMemberUseCase();
    mockUpdateContactUseCase = MockUpdateMemberContactUseCase();
    mockUpgradeTierUseCase = MockUpgradeMemberTierUseCase();
    mockValidateEligibilityUseCase = MockValidateMemberEligibilityUseCase();
    mockLogoutMemberUseCase = MockLogoutMemberUseCase();

    service = MemberApplicationService(
      mockAuthenticateUseCase,
      mockGetProfileUseCase,
      mockRegisterUseCase,
      mockUpdateContactUseCase,
      mockUpgradeTierUseCase,
      mockValidateEligibilityUseCase,
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

    group('getMemberProfile', () {
      test('should get member profile successfully', () async {
        // Arrange
        final memberDto = MemberDTO(
          memberId: 'member-001',
          memberNumber: 'BR857123',
          fullName: 'John Chen',
          email: 'john.chen@example.com',
          phone: '+886912345678',
          tier: MemberTier.gold,
        );

        when(
          mockGetProfileUseCase.call(any),
        ).thenAnswer((_) async => Right(memberDto));

        // Act
        final result = await service.getMemberProfile('BR857123');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (member) => {
            expect(member.memberNumber, equals('BR857123')),
            expect(member.fullName, equals('John Chen')),
          },
        );
      });

      test('should handle member not found', () async {
        // Arrange
        final failure = NotFoundFailure('Member not found');
        when(
          mockGetProfileUseCase.call(any),
        ).thenAnswer((_) async => Left(failure));

        // Act
        final result = await service.getMemberProfile('BR857123');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure.message, equals('Member not found')),
          (member) => fail('Expected failure but got success'),
        );
      });
    });

    group('registerMember', () {
      test('should register member successfully', () async {
        // Arrange
        final memberDto = MemberDTO(
          memberId: 'member-001',
          memberNumber: 'BR857123',
          fullName: 'John Chen',
          email: 'john.chen@example.com',
          phone: '+886912345678',
          tier: MemberTier.gold,
        );

        when(
          mockRegisterUseCase.call(any),
        ).thenAnswer((_) async => Right(memberDto));

        // Act
        final result = await service.registerMember(
          memberNumber: 'BR857123',
          fullName: 'John Chen',
          email: 'john.chen@example.com',
          phone: '+886912345678',
          tier: 'gold',
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (member) => {
            expect(member.memberNumber, equals('BR857123')),
            expect(member.fullName, equals('John Chen')),
          },
        );
      });

      test('should handle registration failure', () async {
        // Arrange
        final failure = ValidationFailure('Member already exists');
        when(
          mockRegisterUseCase.call(any),
        ).thenAnswer((_) async => Left(failure));

        // Act
        final result = await service.registerMember(
          memberNumber: 'BR857123',
          fullName: 'John Chen',
          email: 'john.chen@example.com',
          phone: '+886912345678',
          tier: 'gold',
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure.message, equals('Member already exists')),
          (member) => fail('Expected failure but got success'),
        );
      });
    });
  });
}
