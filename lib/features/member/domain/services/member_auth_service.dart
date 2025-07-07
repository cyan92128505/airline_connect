import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/repositories/member_repository.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:dartz/dartz.dart';

/// Member authentication domain service
/// Coordinates member identity verification process
class MemberAuthService {
  final MemberRepository _memberRepository;

  const MemberAuthService(this._memberRepository);

  /// Authenticate member with member number and name suffix
  Future<Either<Failure, Member>> authenticateMember({
    required String memberNumber,
    required String nameSuffix,
  }) async {
    try {
      // Validate input format
      final memberNumberVO = MemberNumber.create(memberNumber);

      if (nameSuffix.length != 4) {
        return Left(ValidationFailure('Name suffix must be 4 characters'));
      }

      // Find member by number
      final memberResult = await _memberRepository.findByMemberNumber(
        memberNumberVO,
      );

      return memberResult.fold((failure) => Left(failure), (member) {
        if (member == null) {
          return Left(NotFoundFailure('Member not found'));
        }

        // Validate name suffix
        if (!member.validateNameSuffix(nameSuffix)) {
          return Left(AuthenticationFailure('Invalid name suffix'));
        }

        // Check if member is eligible
        if (!member.isEligibleForBoardingPass()) {
          return Left(AuthenticationFailure('Member account is suspended'));
        }

        // Update last login and return
        final updatedMember = member.updateLastLogin();
        _memberRepository.save(updatedMember); // Fire and forget

        return Right(updatedMember);
      });
    } on DomainException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Authentication failed: $e'));
    }
  }

  /// Validate member eligibility for boarding pass
  Future<Either<Failure, bool>> validateEligibility(
    MemberNumber memberNumber,
  ) async {
    final memberResult = await _memberRepository.findByMemberNumber(
      memberNumber,
    );

    return memberResult.fold((failure) => Left(failure), (member) {
      if (member == null) {
        return Left(NotFoundFailure('Member not found'));
      }

      return Right(member.isEligibleForBoardingPass());
    });
  }
}
