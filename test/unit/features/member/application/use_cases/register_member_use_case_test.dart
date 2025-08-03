import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:app/features/member/application/use_cases/register_member_use_case.dart';
import 'package:app/features/member/application/dtos/authentication_dto.dart';
import 'package:app/features/member/domain/repositories/member_repository.dart';

import '../../../../../helpers/test_timezone_helper.dart';
import 'register_member_use_case_test.mocks.dart';

@GenerateMocks([MemberRepository])
void main() {
  late RegisterMemberUseCase useCase;
  late MockMemberRepository mockRepository;

  setUpAll(() {
    TestTimezoneHelper.setupForTesting();
  });

  setUp(() {
    mockRepository = MockMemberRepository();
    useCase = RegisterMemberUseCase(mockRepository);
  });

  group('RegisterMemberUseCase Tests', () {
    test('should register member successfully', () async {
      // Arrange
      final request = MemberRegistrationDTO(
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        email: 'john.chen@example.com',
        phone: '+886912345678',
        tier: 'gold',
      );

      when(mockRepository.exists(any)).thenAnswer((_) async => Right(false));
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
          expect(dto.fullName, equals('John Chen')),
          expect(dto.email, equals('john.chen@example.com')),
        },
      );
    });

    test('should handle member already exists', () async {
      // Arrange
      final request = MemberRegistrationDTO(
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        email: 'john.chen@example.com',
        phone: '+886912345678',
        tier: 'gold',
      );

      when(mockRepository.exists(any)).thenAnswer((_) async => Right(true));

      // Act
      final result = await useCase.call(request);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, contains('already exists')),
        (dto) => fail('Expected failure but got success'),
      );
    });

    test('should validate empty member number', () async {
      // Arrange
      final request = MemberRegistrationDTO(
        memberNumber: '',
        fullName: 'John Chen',
        email: 'john.chen@example.com',
        phone: '+886912345678',
        tier: 'gold',
      );

      // Act
      final result = await useCase.call(request);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure.message, contains('Member number cannot be empty')),
        (dto) => fail('Expected failure but got success'),
      );
    });

    test('should validate invalid email format', () async {
      // Arrange
      final request = MemberRegistrationDTO(
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        email: 'invalid-email',
        phone: '+886912345678',
        tier: 'gold',
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
