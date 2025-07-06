import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/member/application/use_cases/authenticate_member_use_case.dart';
import 'package:app/features/member/application/dtos/authentication_dto.dart';
import 'package:app/features/member/services/member_auth_service.dart';
import 'package:app/features/member/entities/member.dart';
import 'package:app/features/member/enums/member_tier.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'authenticate_member_use_case_test.mocks.dart';

@GenerateMocks([MemberAuthService])
void main() {
  late AuthenticateMemberUseCase useCase;
  late MockMemberAuthService mockAuthService;

  setUpAll(() {
    tz.initializeTimeZones();
  });

  setUp(() {
    mockAuthService = MockMemberAuthService();
    useCase = AuthenticateMemberUseCase(mockAuthService);
  });

  group('AuthenticateMemberUseCase Tests', () {
    test('should authenticate member successfully', () async {
      // Arrange
      final request = AuthenticationRequestDTO(
        memberNumber: 'BR857123',
        nameSuffix: 'CHEN',
      );

      final member = Member.create(
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        tier: MemberTier.gold,
        email: 'john.chen@example.com',
        phone: '+886912345678',
      );

      when(
        mockAuthService.authenticateMember(
          memberNumber: anyNamed('memberNumber'),
          nameSuffix: anyNamed('nameSuffix'),
        ),
      ).thenAnswer((_) async => Right(member));

      // Act
      final result = await useCase.call(request);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (response) => {
          expect(response.isAuthenticated, isTrue),
          expect(response.member, isNotNull),
          expect(response.member!.memberNumber, equals('BR857123')),
          expect(response.errorMessage, isNull),
        },
      );
    });

    test('should handle authentication failure', () async {
      // Arrange
      final request = AuthenticationRequestDTO(
        memberNumber: 'BR857123',
        nameSuffix: 'CHEN',
      );

      final failure = NotFoundFailure('Member not found');
      when(
        mockAuthService.authenticateMember(
          memberNumber: anyNamed('memberNumber'),
          nameSuffix: anyNamed('nameSuffix'),
        ),
      ).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase.call(request);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (response) => {
          expect(response.isAuthenticated, isFalse),
          expect(response.member, isNull),
          expect(response.errorMessage, equals('Member not found')),
        },
      );
    });

    test('should validate empty member number', () async {
      // Arrange
      final request = AuthenticationRequestDTO(
        memberNumber: '',
        nameSuffix: 'CHEN',
      );

      // Act
      final result = await useCase.call(request);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure.message, contains('Member number cannot be empty')),
        (response) => fail('Expected failure but got success'),
      );
    });

    test('should validate invalid name suffix length', () async {
      // Arrange
      final request = AuthenticationRequestDTO(
        memberNumber: 'BR857123',
        nameSuffix: 'CH', // Too short
      );

      // Act
      final result = await useCase.call(request);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure.message,
          contains('Name suffix must be exactly 4 characters'),
        ),
        (response) => fail('Expected failure but got success'),
      );
    });
  });
}
