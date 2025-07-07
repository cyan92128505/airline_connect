import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/member/application/dtos/authentication_dto.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';

void main() {
  group('AuthenticationRequestDTO Tests', () {
    test('should create valid authentication request', () {
      // Arrange & Act
      final dto = AuthenticationRequestDTO(
        memberNumber: 'BR857123',
        nameSuffix: 'CHEN',
      );

      // Assert
      expect(dto.memberNumber, equals('BR857123'));
      expect(dto.nameSuffix, equals('CHEN'));
    });

    test('should serialize to/from JSON correctly', () {
      // Arrange
      final dto = AuthenticationRequestDTO(
        memberNumber: 'BR857123',
        nameSuffix: 'CHEN',
      );

      // Act
      final json = dto.toJson();
      final fromJson = AuthenticationRequestDTO.fromJson(json);

      // Assert
      expect(fromJson.memberNumber, equals(dto.memberNumber));
      expect(fromJson.nameSuffix, equals(dto.nameSuffix));
    });
  });

  group('AuthenticationResponseDTO Tests', () {
    test('should create successful authentication response', () {
      // Arrange
      final memberDto = MemberDTO(
        memberId: 'member-001',
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        email: 'john.chen@example.com',
        phone: '+886912345678',
        tier: MemberTier.gold,
      );

      // Act
      final response = AuthenticationResponseDTO(
        isAuthenticated: true,
        member: memberDto,
      );

      // Assert
      expect(response.isAuthenticated, isTrue);
      expect(response.member, isNotNull);
      expect(response.errorMessage, isNull);
    });

    test('should create failed authentication response', () {
      // Act
      final response = AuthenticationResponseDTO(
        isAuthenticated: false,
        errorMessage: 'Invalid credentials',
      );

      // Assert
      expect(response.isAuthenticated, isFalse);
      expect(response.member, isNull);
      expect(response.errorMessage, equals('Invalid credentials'));
    });
  });

  group('MemberRegistrationDTO Tests', () {
    test('should create valid member registration', () {
      // Arrange & Act
      final dto = MemberRegistrationDTO(
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        email: 'john.chen@example.com',
        phone: '+886912345678',
        tier: 'gold',
      );

      // Assert
      expect(dto.memberNumber, equals('BR857123'));
      expect(dto.fullName, equals('John Chen'));
      expect(dto.email, equals('john.chen@example.com'));
      expect(dto.phone, equals('+886912345678'));
      expect(dto.tier, equals('gold'));
    });

    test('should serialize to/from JSON correctly', () {
      // Arrange
      final dto = MemberRegistrationDTO(
        memberNumber: 'BR857123',
        fullName: 'John Chen',
        email: 'john.chen@example.com',
        phone: '+886912345678',
        tier: 'gold',
      );

      // Act
      final json = dto.toJson();
      final fromJson = MemberRegistrationDTO.fromJson(json);

      // Assert
      expect(fromJson.memberNumber, equals(dto.memberNumber));
      expect(fromJson.fullName, equals(dto.fullName));
      expect(fromJson.email, equals(dto.email));
      expect(fromJson.phone, equals(dto.phone));
      expect(fromJson.tier, equals(dto.tier));
    });
  });
}
