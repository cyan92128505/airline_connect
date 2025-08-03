import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';

import '../../../../../helpers/test_timezone_helper.dart';

void main() {
  setUpAll(() {
    TestTimezoneHelper.setupForTesting();
  });
  group('MemberDTO Tests', () {
    test('should create valid member DTO', () {
      // Arrange & Act
      final dto = MemberDTO(
        memberId: 'member-001',
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        email: 'john.chen@example.com',
        phone: '+886912345678',
        tier: MemberTier.gold,
        createdAt: '2024-01-01T00:00:00Z',
        lastLoginAt: '2024-01-15T12:00:00Z',
      );

      // Assert
      expect(dto.memberId, equals('member-001'));
      expect(dto.memberNumber, equals('BR857123'));
      expect(dto.fullName, equals('John Chen'));
      expect(dto.email, equals('john.chen@example.com'));
      expect(dto.phone, equals('+886912345678'));
      expect(dto.tier, equals(MemberTier.gold));
      expect(dto.createdAt, equals('2024-01-01T00:00:00Z'));
      expect(dto.lastLoginAt, equals('2024-01-15T12:00:00Z'));
    });

    test('should serialize to/from JSON correctly', () {
      // Arrange
      final dto = MemberDTO(
        memberId: 'member-001',
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        email: 'john.chen@example.com',
        phone: '+886912345678',
        tier: MemberTier.gold,
      );

      // Act
      final json = dto.toJson();
      final fromJson = MemberDTO.fromJson(json);

      // Assert
      expect(fromJson.memberId, equals(dto.memberId));
      expect(fromJson.memberNumber, equals(dto.memberNumber));
      expect(fromJson.fullName, equals(dto.fullName));
      expect(fromJson.email, equals(dto.email));
      expect(fromJson.phone, equals(dto.phone));
      expect(fromJson.tier, equals(dto.tier));
    });
  });

  group('MemberDTOExtensions Tests', () {
    test('should convert from domain entity to DTO correctly', () {
      // Arrange
      final member = Member.create(
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        tier: MemberTier.gold,
        email: 'john.chen@example.com',
        phone: '+886912345678',
      );

      // Act
      final dto = MemberDTOExtensions.fromDomain(member);

      // Assert
      expect(dto.memberNumber, equals('BR857123'));
      expect(dto.fullName, equals('John Chen'));
      expect(dto.tier, equals(MemberTier.gold));
      expect(dto.email, equals('john.chen@example.com'));
      expect(dto.phone, equals('+886912345678'));
    });

    test('should handle null datetime fields correctly', () {
      // Arrange
      final member = Member.create(
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        tier: MemberTier.gold,
        email: 'john.chen@example.com',
        phone: '+886912345678',
      );

      // Act
      final dto = MemberDTOExtensions.fromDomain(member);

      // Assert
      expect(dto.createdAt, isNotNull);
      expect(dto.lastLoginAt, isNull);
    });
  });
}
