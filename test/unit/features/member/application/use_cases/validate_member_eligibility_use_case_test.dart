import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/member/application/use_cases/validate_member_eligibility_use_case.dart';
import 'package:app/features/member/services/member_auth_service.dart';

import 'validate_member_eligibility_use_case_test.mocks.dart';

@GenerateMocks([MemberAuthService])
void main() {
  late ValidateMemberEligibilityUseCase useCase;
  late MockMemberAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockMemberAuthService();
    useCase = ValidateMemberEligibilityUseCase(mockAuthService);
  });

  group('ValidateMemberEligibilityUseCase Tests', () {
    test('should validate member eligibility successfully', () async {
      // Arrange
      when(
        mockAuthService.validateEligibility(any),
      ).thenAnswer((_) async => Right(true));

      // Act
      final result = await useCase.call('BR857123');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (eligibility) => {
          expect(eligibility.isEligible, isTrue),
          expect(eligibility.memberNumber, equals('BR857123')),
          expect(eligibility.reason, isNull),
        },
      );
    });

    test('should handle ineligible member', () async {
      // Arrange
      when(
        mockAuthService.validateEligibility(any),
      ).thenAnswer((_) async => Right(false));

      // Act
      final result = await useCase.call('BR857123');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (eligibility) => {
          expect(eligibility.isEligible, isFalse),
          expect(eligibility.memberNumber, equals('BR857123')),
          expect(eligibility.reason, isNotNull),
          expect(eligibility.reason, contains('suspended')),
        },
      );
    });

    test('should handle service failure', () async {
      // Arrange
      final failure = UnknownFailure('Service unavailable');
      when(
        mockAuthService.validateEligibility(any),
      ).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase.call('BR857123');

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, equals('Service unavailable')),
        (eligibility) => fail('Expected failure but got success'),
      );
    });

    test('should handle invalid member number format', () async {
      // Act
      final result = await useCase.call('');

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure.message, contains('validate member eligibility')),
        (eligibility) => fail('Expected failure but got success'),
      );
    });
  });
}
