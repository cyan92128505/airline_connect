import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/application/use_cases/logout_member_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/member/domain/services/member_auth_service.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';

import '../../../../../helpers/test_timezone_helper.dart';
import 'logout_member_use_case_test.mocks.dart';

@GenerateMocks([MemberAuthService])
void main() {
  late LogoutMemberUseCase useCase;
  late MockMemberAuthService mockAuthService;

  setUpAll(() {
    TestTimezoneHelper.setupForTesting();
  });

  setUp(() {
    mockAuthService = MockMemberAuthService();
    useCase = LogoutMemberUseCase(mockAuthService);
  });

  group('LogoutMemberUseCase Tests', () {
    test('should logout member successfully', () async {
      // Arrange
      final request = MemberDTO(
        memberId: '00000000-0000-0000-0000-000000000000',
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        tier: MemberTier.gold,
        email: 'john.chen@example.com',
        phone: '+886912345678',
      );

      final member = Member.create(
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        tier: MemberTier.gold,
        email: 'john.chen@example.com',
        phone: '+886912345678',
      );

      when(
        mockAuthService.logoutMember(any),
      ).thenAnswer((_) async => Right(member));

      // Act
      final result = await useCase.call(request.memberNumber);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (response) => {expect(response, isTrue)},
      );
    });

    test('should handle logout failure', () async {
      // Arrange
      final request = MemberDTO(
        memberId: '00000000-0000-0000-0000-000000000000',
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        tier: MemberTier.gold,
        email: 'john.chen@example.com',
        phone: '+886912345678',
      );

      final failure = NotFoundFailure('Member not found');
      when(
        mockAuthService.logoutMember(any),
      ).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase.call(request.memberNumber);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (response) => {expect(response, isFalse)},
      );
    });
  });
}
