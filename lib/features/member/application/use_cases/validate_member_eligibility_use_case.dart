import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/features/member/services/member_auth_service.dart';
import 'package:app/features/member/value_objects/member_number.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'validate_member_eligibility_use_case.freezed.dart';

/// DTO for member eligibility validation response
@freezed
abstract class MemberEligibilityDTO with _$MemberEligibilityDTO {
  const factory MemberEligibilityDTO({
    required bool isEligible,
    required String memberNumber,
    String? reason,
  }) = _MemberEligibilityDTO;
}

/// Use case for validating member eligibility for boarding pass
@injectable
class ValidateMemberEligibilityUseCase
    implements UseCase<MemberEligibilityDTO, String> {
  final MemberAuthService _memberAuthService;

  const ValidateMemberEligibilityUseCase(this._memberAuthService);

  @override
  Future<Either<Failure, MemberEligibilityDTO>> call(
    String memberNumber,
  ) async {
    try {
      // Validate member number format
      final memberNumberVO = MemberNumber.create(memberNumber);

      // Check eligibility using domain service
      final eligibilityResult = await _memberAuthService.validateEligibility(
        memberNumberVO,
      );

      return eligibilityResult.fold(
        (failure) => Left(failure),
        (isEligible) => Right(
          MemberEligibilityDTO(
            isEligible: isEligible,
            memberNumber: memberNumber,
            reason: isEligible ? null : 'Member account may be suspended',
          ),
        ),
      );
    } catch (e) {
      return Left(UnknownFailure('Failed to validate member eligibility: $e'));
    }
  }
}
