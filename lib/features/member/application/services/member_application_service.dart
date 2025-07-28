import 'package:app/core/failures/failure.dart';
import 'package:app/features/member/application/dtos/authentication_dto.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/application/use_cases/authenticate_member_use_case.dart';
import 'package:app/features/member/application/use_cases/get_member_profile_use_case.dart';
import 'package:app/features/member/application/use_cases/logout_member_use_case.dart';
import 'package:app/features/member/application/use_cases/register_member_use_case.dart';
import 'package:app/features/member/application/use_cases/update_member_contact_use_case.dart';
import 'package:app/features/member/application/use_cases/upgrade_member_tier_use_case.dart';
import 'package:app/features/member/application/use_cases/validate_member_eligibility_use_case.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

/// Application service that orchestrates member use cases
/// Provides a higher-level API for the presentation layer
@injectable
class MemberApplicationService {
  final AuthenticateMemberUseCase _authenticateMemberUseCase;
  final GetMemberProfileUseCase _getMemberProfileUseCase;
  final RegisterMemberUseCase _registerMemberUseCase;
  final UpdateMemberContactUseCase _updateMemberContactUseCase;
  final UpgradeMemberTierUseCase _upgradeMemberTierUseCase;
  final ValidateMemberEligibilityUseCase _validateMemberEligibilityUseCase;
  final LogoutMemberUseCase _logoutMemberUseCase;

  const MemberApplicationService(
    this._authenticateMemberUseCase,
    this._getMemberProfileUseCase,
    this._registerMemberUseCase,
    this._updateMemberContactUseCase,
    this._upgradeMemberTierUseCase,
    this._validateMemberEligibilityUseCase,
    this._logoutMemberUseCase,
  );

  /// Authenticate member with credentials
  Future<Either<Failure, AuthenticationResponseDTO>> authenticateMember({
    required String memberNumber,
    required String nameSuffix,
  }) async {
    final request = AuthenticationRequestDTO(
      memberNumber: memberNumber,
      nameSuffix: nameSuffix,
    );

    return _authenticateMemberUseCase(request);
  }

  /// Get member profile information
  Future<Either<Failure, MemberDTO>> getMemberProfile(
    String memberNumber,
  ) async {
    return _getMemberProfileUseCase(memberNumber);
  }

  /// Register a new member
  Future<Either<Failure, MemberDTO>> registerMember({
    required String memberNumber,
    required String fullName,
    required String email,
    required String phone,
    required String tier,
  }) async {
    final request = MemberRegistrationDTO(
      memberNumber: memberNumber,
      fullName: fullName,
      email: email,
      phone: phone,
      tier: tier,
    );

    return _registerMemberUseCase(request);
  }

  /// Update member contact information
  Future<Either<Failure, MemberDTO>> updateMemberContact({
    required String memberNumber,
    String? email,
    String? phone,
  }) async {
    final request = UpdateContactRequestDTO(
      memberNumber: memberNumber,
      email: email,
      phone: phone,
    );

    return _updateMemberContactUseCase(request);
  }

  /// Upgrade member tier
  Future<Either<Failure, MemberDTO>> upgradeMemberTier({
    required String memberNumber,
    required String newTier,
  }) async {
    final request = UpgradeTierRequestDTO(
      memberNumber: memberNumber,
      newTier: newTier,
    );

    return _upgradeMemberTierUseCase(request);
  }

  /// Validate member eligibility for boarding pass
  Future<Either<Failure, MemberEligibilityDTO>> validateMemberEligibility(
    String memberNumber,
  ) async {
    return _validateMemberEligibilityUseCase(memberNumber);
  }

  Future<Either<Failure, bool>> logout(String memberNumber) {
    return _logoutMemberUseCase(memberNumber);
  }
}
