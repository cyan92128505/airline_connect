import 'package:app/core/failures/failure.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:app/features/member/domain/repositories/member_repository.dart';
import 'package:app/features/member/domain/services/member_auth_service.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'member_auth_service_test.mocks.dart';

@GenerateMocks([MemberRepository])
void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('MemberAuthService Tests', () {
    late MemberAuthService authService;
    late MockMemberRepository mockRepository;

    setUp(() {
      mockRepository = MockMemberRepository();
      authService = MemberAuthService(mockRepository);
    });

    test('should authenticate member successfully', () async {
      final member = Member.create(
        memberNumber: 'AA123456',
        fullName: '王小明1234',
        tier: MemberTier.gold,
        email: 'test@example.com',
        phone: '+886912345678',
      );

      when(
        mockRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => Right(member));
      when(mockRepository.save(any)).thenAnswer((_) async => const Right(null));

      final result = await authService.authenticateMember(
        memberNumber: 'AA123456',
        nameSuffix: '1234',
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (authenticatedMember) {
        expect(authenticatedMember.memberNumber.value, equals('AA123456'));
        expect(authenticatedMember.lastLoginAt, isNotNull);
      });

      verify(mockRepository.findByMemberNumber(any)).called(1);
      verify(mockRepository.save(any)).called(1);
    });

    test('should fail authentication for wrong name suffix', () async {
      final member = Member.create(
        memberNumber: 'AA123456',
        fullName: '王小明1234',
        tier: MemberTier.gold,
        email: 'test@example.com',
        phone: '+886912345678',
      );

      when(
        mockRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => Right(member));

      final result = await authService.authenticateMember(
        memberNumber: 'AA123456',
        nameSuffix: '5678', // Wrong suffix
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<AuthenticationFailure>()),
        (member) => fail('Should fail'),
      );
    });

    test('should fail authentication for suspended member', () async {
      final suspendedMember = Member.create(
        memberNumber: 'AA123456',
        fullName: '王小明1234',
        tier: MemberTier.suspended,
        email: 'test@example.com',
        phone: '+886912345678',
      );

      when(
        mockRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => Right(suspendedMember));

      final result = await authService.authenticateMember(
        memberNumber: 'AA123456',
        nameSuffix: '1234',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<AuthenticationFailure>()),
        (member) => fail('Should fail'),
      );
    });

    test('should fail authentication for non-existent member', () async {
      when(
        mockRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => const Right(null));

      final result = await authService.authenticateMember(
        memberNumber: 'AA123456',
        nameSuffix: '1234',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (member) => fail('Should fail'),
      );
    });

    test(
      'should fail authentication for invalid member number format',
      () async {
        final result = await authService.authenticateMember(
          memberNumber: 'INVALID',
          nameSuffix: '1234',
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (member) => fail('Should fail'),
        );
      },
    );

    test('should fail authentication for invalid name suffix length', () async {
      final result = await authService.authenticateMember(
        memberNumber: 'AA123456',
        nameSuffix: '12', // Too short
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (member) => fail('Should fail'),
      );
    });

    test('should validate member eligibility successfully', () async {
      final member = Member.create(
        memberNumber: 'AA123456',
        fullName: '王小明',
        tier: MemberTier.gold,
        email: 'test@example.com',
        phone: '+886912345678',
      );

      when(
        mockRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => Right(member));

      final result = await authService.validateEligibility(
        MemberNumber.create('AA123456'),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not fail'),
        (isEligible) => expect(isEligible, isTrue),
      );
    });

    test('should fail eligibility validation for suspended member', () async {
      final suspendedMember = Member.create(
        memberNumber: 'AA123456',
        fullName: '王小明',
        tier: MemberTier.suspended,
        email: 'test@example.com',
        phone: '+886912345678',
      );

      when(
        mockRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => Right(suspendedMember));

      final result = await authService.validateEligibility(
        MemberNumber.create('AA123456'),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not fail'),
        (isEligible) => expect(isEligible, isFalse),
      );
    });

    test('should handle repository failure', () async {
      when(
        mockRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

      final result = await authService.authenticateMember(
        memberNumber: 'AA123456',
        nameSuffix: '1234',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (member) => fail('Should fail'),
      );
    });
  });
}
