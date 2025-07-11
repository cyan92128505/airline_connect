import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:app/features/member/application/use_cases/upgrade_member_tier_use_case.dart';
import 'package:app/features/member/domain/repositories/member_repository.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'upgrade_member_tier_use_case_test.mocks.dart';

@GenerateMocks([MemberRepository])
void main() {
  late UpgradeMemberTierUseCase useCase;
  late MockMemberRepository mockRepository;

  setUpAll(() {
    tz.initializeTimeZones();
  });

  setUp(() {
    mockRepository = MockMemberRepository();
    useCase = UpgradeMemberTierUseCase(mockRepository);
  });

  group('UpgradeMemberTierUseCase Tests', () {
    test('should upgrade member tier successfully', () async {
      // Arrange
      final member = Member.create(
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        tier: MemberTier.silver,
        email: 'john.chen@example.com',
        phone: '+886912345678',
      );

      final request = UpgradeTierRequestDTO(
        memberNumber: 'BR857123',
        newTier: 'gold',
      );

      when(
        mockRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => Right(member));
      // ignore: void_checks
      when(mockRepository.save(any)).thenAnswer((_) async => Right(unit));

      // Act
      final result = await useCase.call(request);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (dto) => {
          expect(dto.memberNumber, equals('BR857123')),
          expect(dto.tier, equals(MemberTier.gold)),
        },
      );
    });

    test('should handle member not found', () async {
      // Arrange
      final request = UpgradeTierRequestDTO(
        memberNumber: 'BR857123',
        newTier: 'gold',
      );

      when(
        mockRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => Right(null));

      // Act
      final result = await useCase.call(request);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, contains('Member not found')),
        (dto) => fail('Expected failure but got success'),
      );
    });

    test('should validate invalid tier', () async {
      // Arrange
      final request = UpgradeTierRequestDTO(
        memberNumber: 'BR857123',
        newTier: 'invalid-tier',
      );

      // Act
      final result = await useCase.call(request);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, contains('Invalid member tier')),
        (dto) => fail('Expected failure but got success'),
      );
    });

    test('should validate empty tier', () async {
      // Arrange
      final request = UpgradeTierRequestDTO(
        memberNumber: 'BR857123',
        newTier: '',
      );

      // Act
      final result = await useCase.call(request);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure.message, contains('New tier cannot be empty')),
        (dto) => fail('Expected failure but got success'),
      );
    });
  });
}
