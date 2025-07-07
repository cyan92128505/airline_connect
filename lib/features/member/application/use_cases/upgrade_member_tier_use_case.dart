import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:app/features/member/domain/repositories/member_repository.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'upgrade_member_tier_use_case.freezed.dart';

/// DTO for upgrading member tier
@freezed
abstract class UpgradeTierRequestDTO with _$UpgradeTierRequestDTO {
  const factory UpgradeTierRequestDTO({
    required String memberNumber,
    required String newTier,
  }) = _UpgradeTierRequestDTO;
}

/// Use case for upgrading member tier
@injectable
class UpgradeMemberTierUseCase
    implements UseCase<MemberDTO, UpgradeTierRequestDTO> {
  final MemberRepository _memberRepository;

  const UpgradeMemberTierUseCase(this._memberRepository);

  @override
  Future<Either<Failure, MemberDTO>> call(UpgradeTierRequestDTO params) async {
    try {
      // Validate input
      final validationResult = _validateInput(params);
      if (validationResult != null) {
        return Left(validationResult);
      }

      // Find existing member
      final memberNumberVO = MemberNumber.create(params.memberNumber);
      final memberResult = await _memberRepository.findByMemberNumber(
        memberNumberVO,
      );

      return memberResult.fold((failure) => Left(failure), (member) async {
        if (member == null) {
          return Left(
            NotFoundFailure('Member not found: ${params.memberNumber}'),
          );
        }

        // Parse new tier
        final newTier = MemberTier.fromString(params.newTier);

        // Upgrade member tier (domain logic validates the upgrade path)
        final upgradedMember = member.upgradeTier(newTier);

        // Save upgraded member
        final saveResult = await _memberRepository.save(upgradedMember);

        return saveResult.fold(
          (failure) => Left(failure),
          (_) => Right(MemberDTOExtensions.fromDomain(upgradedMember)),
        );
      });
    } catch (e) {
      return Left(UnknownFailure('Failed to upgrade member tier: $e'));
    }
  }

  /// Validate input parameters
  Failure? _validateInput(UpgradeTierRequestDTO params) {
    if (params.memberNumber.trim().isEmpty) {
      return ValidationFailure('Member number cannot be empty');
    }

    if (params.newTier.trim().isEmpty) {
      return ValidationFailure('New tier cannot be empty');
    }

    // Validate tier format
    try {
      MemberTier.fromString(params.newTier);
    } catch (e) {
      return ValidationFailure('Invalid member tier: ${params.newTier}');
    }

    return null;
  }
}
