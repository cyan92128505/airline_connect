import 'package:app/features/member/application/dtos/authentication_dto.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/entities/member.dart';
import 'package:app/features/member/enums/member_tier.dart';

/// Test data factory for member-related tests
/// Provides consistent test data across all test files
class MemberTestData {
  static const String validMemberNumber = 'BR857123';
  static const String validFullName = 'John Chen';
  static const String validEmail = 'john.chen@example.com';
  static const String validPhone = '+886912345678';
  static const String validNameSuffix = 'CHEN';
  static const MemberTier defaultTier = MemberTier.gold;

  /// Create a valid authentication request for testing
  static AuthenticationRequestDTO createAuthRequest({
    String? memberNumber,
    String? nameSuffix,
  }) {
    return AuthenticationRequestDTO(
      memberNumber: memberNumber ?? validMemberNumber,
      nameSuffix: nameSuffix ?? validNameSuffix,
    );
  }

  /// Create a valid member registration DTO for testing
  static MemberRegistrationDTO createRegistrationRequest({
    String? memberNumber,
    String? fullName,
    String? email,
    String? phone,
    String? tier,
  }) {
    return MemberRegistrationDTO(
      memberNumber: memberNumber ?? validMemberNumber,
      fullName: fullName ?? validFullName,
      email: email ?? validEmail,
      phone: phone ?? validPhone,
      tier: tier ?? 'gold',
    );
  }

  /// Create a valid member DTO for testing
  static MemberDTO createMemberDTO({
    String? memberId,
    String? memberNumber,
    String? fullName,
    String? email,
    String? phone,
    MemberTier? tier,
    String? createdAt,
    String? lastLoginAt,
  }) {
    return MemberDTO(
      memberId: memberId ?? 'member-001',
      memberNumber: memberNumber ?? validMemberNumber,
      fullName: fullName ?? validFullName,
      email: email ?? validEmail,
      phone: phone ?? validPhone,
      tier: tier ?? defaultTier,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  /// Create a valid member entity for testing
  static Member createMember({
    String? memberNumber,
    String? fullName,
    String? email,
    String? phone,
    MemberTier? tier,
  }) {
    return Member.create(
      memberNumber: memberNumber ?? validMemberNumber,
      fullName: fullName ?? validFullName,
      tier: tier ?? defaultTier,
      email: email ?? validEmail,
      phone: phone ?? validPhone,
    );
  }

  /// Create successful authentication response
  static AuthenticationResponseDTO createSuccessfulAuthResponse({
    MemberDTO? member,
  }) {
    return AuthenticationResponseDTO(
      isAuthenticated: true,
      member: member ?? createMemberDTO(),
    );
  }

  /// Create failed authentication response
  static AuthenticationResponseDTO createFailedAuthResponse({
    String? errorMessage,
  }) {
    return AuthenticationResponseDTO(
      isAuthenticated: false,
      errorMessage: errorMessage ?? 'Authentication failed',
    );
  }
}
