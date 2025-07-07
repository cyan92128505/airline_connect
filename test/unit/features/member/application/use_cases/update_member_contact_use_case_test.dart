import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:app/features/member/application/use_cases/update_member_contact_use_case.dart';
import 'package:app/features/member/domain/repositories/member_repository.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'update_member_contact_use_case_test.mocks.dart';

@GenerateMocks([MemberRepository])
void main() {
  late UpdateMemberContactUseCase useCase;
  late MockMemberRepository mockRepository;

  setUpAll(() {
    tz.initializeTimeZones();
  });

  setUp(() {
    mockRepository = MockMemberRepository();
    useCase = UpdateMemberContactUseCase(mockRepository);
  });

  group('UpdateMemberContactUseCase Tests', () {
    test('should update member contact successfully', () async {
      // Arrange
      final member = Member.create(
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        tier: MemberTier.gold,
        email: 'john.chen@example.com',
        phone: '+886912345678',
      );

      final request = UpdateContactRequestDTO(
        memberNumber: 'BR857123',
        email: 'john.chen.new@example.com',
        phone: '+886987654321',
      );

      when(
        mockRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => Right(member));
      when(mockRepository.save(any)).thenAnswer((_) async => Right(unit));

      // Act
      final result = await useCase.call(request);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (dto) => {
          expect(dto.memberNumber, equals('BR857123')),
          expect(dto.email, equals('john.chen.new@example.com')),
          expect(dto.phone, equals('+886987654321')),
        },
      );
    });

    test('should handle member not found', () async {
      // Arrange
      final request = UpdateContactRequestDTO(
        memberNumber: 'BR857123',
        email: 'john.chen.new@example.com',
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

    test('should validate at least one field provided', () async {
      // Arrange
      final request = UpdateContactRequestDTO(
        memberNumber: 'BR857123',
        // No email or phone provided
      );

      // Act
      final result = await useCase.call(request);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure.message, contains('At least one contact field')),
        (dto) => fail('Expected failure but got success'),
      );
    });

    test('should validate invalid email format', () async {
      // Arrange
      final request = UpdateContactRequestDTO(
        memberNumber: 'BR857123',
        email: 'invalid-email',
      );

      // Act
      final result = await useCase.call(request);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, contains('Invalid email format')),
        (dto) => fail('Expected failure but got success'),
      );
    });
  });
}
