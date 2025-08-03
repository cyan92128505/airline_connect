import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:app/features/member/application/use_cases/get_member_profile_use_case.dart';
import 'package:app/features/member/domain/repositories/member_repository.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';

import '../../../../../helpers/test_timezone_helper.dart';
import 'get_member_profile_use_case_test.mocks.dart';

@GenerateMocks([MemberRepository])
void main() {
  late GetMemberProfileUseCase useCase;
  late MockMemberRepository mockRepository;

  setUpAll(() {
    TestTimezoneHelper.setupForTesting();
  });

  setUp(() {
    mockRepository = MockMemberRepository();
    useCase = GetMemberProfileUseCase(mockRepository);
  });

  group('GetMemberProfileUseCase Tests', () {
    test('should get member profile successfully', () async {
      // Arrange
      final member = Member.create(
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        tier: MemberTier.gold,
        email: 'john.chen@example.com',
        phone: '+886912345678',
      );

      when(
        mockRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => Right(member));

      // Act
      final result = await useCase.call('BR857123');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (dto) => {
          expect(dto.memberNumber, equals('BR857123')),
          expect(dto.fullName, equals('John Chen')),
          expect(dto.tier, equals(MemberTier.gold)),
        },
      );
    });

    test('should handle member not found', () async {
      // Arrange
      when(
        mockRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => Right(null));

      // Act
      final result = await useCase.call('BR857123');

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, contains('Member not found')),
        (dto) => fail('Expected failure but got success'),
      );
    });
  });
}
