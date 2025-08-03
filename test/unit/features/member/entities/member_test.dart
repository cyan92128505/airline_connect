import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:app/core/exceptions/domain_exception.dart';

import '../../../../helpers/test_timezone_helper.dart';

void main() {
  setUpAll(() {
    TestTimezoneHelper.setupForTesting();
  });

  group('Member Entity Tests', () {
    test('should create valid member with correct data', () {
      final member = Member.create(
        memberNumber: 'AA123456',
        fullName: '王小明',
        tier: MemberTier.gold,
        email: 'test@example.com',
        phone: '+886912345678',
      );

      expect(member.memberNumber.value, equals('AA123456'));
      expect(member.fullName.value, equals('王小明'));
      expect(member.tier, equals(MemberTier.gold));
      expect(member.contactInfo.email, equals('test@example.com'));
      expect(member.contactInfo.phone, equals('+886912345678'));
      expect(member.createdAt, isNotNull);
      expect(member.lastLoginAt, isNull);
    });

    test('should throw exception for invalid member data', () {
      expect(
        () => Member.create(
          memberNumber: 'INVALID',
          fullName: '王小明',
          tier: MemberTier.gold,
          email: 'test@example.com',
          phone: '+886912345678',
        ),
        throwsA(isA<DomainException>()),
      );
    });

    test('should validate name suffix correctly', () {
      final member = Member.create(
        memberNumber: 'AA123456',
        fullName: '王小明1234',
        tier: MemberTier.gold,
        email: 'test@example.com',
        phone: '+886912345678',
      );

      expect(member.validateNameSuffix('1234'), isTrue);
      expect(member.validateNameSuffix('5678'), isFalse);
      expect(member.validateNameSuffix('12'), isFalse);
    });

    test('should update last login timestamp', () {
      final member = Member.create(
        memberNumber: 'AA123456',
        fullName: '王小明',
        tier: MemberTier.gold,
        email: 'test@example.com',
        phone: '+886912345678',
      );

      final updatedMember = member.updateLastLogin();

      expect(updatedMember.lastLoginAt, isNotNull);
      expect(updatedMember.memberId, equals(member.memberId));
    });

    test('should upgrade tier correctly', () {
      final member = Member.create(
        memberNumber: 'AA123456',
        fullName: '王小明',
        tier: MemberTier.bronze,
        email: 'test@example.com',
        phone: '+886912345678',
      );

      final upgradedMember = member.upgradeTier(MemberTier.silver);

      expect(upgradedMember.tier, equals(MemberTier.silver));
    });

    test('should throw exception for invalid tier upgrade', () {
      final member = Member.create(
        memberNumber: 'AA123456',
        fullName: '王小明',
        tier: MemberTier.gold,
        email: 'test@example.com',
        phone: '+886912345678',
      );

      expect(
        () => member.upgradeTier(MemberTier.bronze),
        throwsA(isA<DomainException>()),
      );
    });

    test('should check eligibility for boarding pass', () {
      final activeMember = Member.create(
        memberNumber: 'AA123456',
        fullName: '王小明',
        tier: MemberTier.gold,
        email: 'test@example.com',
        phone: '+886912345678',
      );

      final suspendedMember = Member.create(
        memberNumber: 'BB123456',
        fullName: '李小華',
        tier: MemberTier.suspended,
        email: 'test2@example.com',
        phone: '+886987654321',
      );

      expect(activeMember.isEligibleForBoardingPass(), isTrue);
      expect(suspendedMember.isEligibleForBoardingPass(), isFalse);
    });
  });
}
