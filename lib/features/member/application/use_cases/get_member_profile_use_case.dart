import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/domain/repositories/member_repository.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

/// Use case for getting member profile information
@injectable
class GetMemberProfileUseCase implements UseCase<MemberDTO, String> {
  final MemberRepository _memberRepository;

  const GetMemberProfileUseCase(this._memberRepository);

  @override
  Future<Either<Failure, MemberDTO>> call(String memberNumber) async {
    try {
      // Validate member number format
      final memberNumberVO = MemberNumber.create(memberNumber);

      // Retrieve member from repository
      final memberResult = await _memberRepository.findByMemberNumber(
        memberNumberVO,
      );

      return memberResult.fold((failure) => Left(failure), (member) {
        if (member == null) {
          return Left(NotFoundFailure('Member not found: $memberNumber'));
        }

        // Convert to DTO
        final memberDTO = MemberDTOExtensions.fromDomain(member);
        return Right(memberDTO);
      });
    } catch (e) {
      return Left(UnknownFailure('Failed to get member profile: $e'));
    }
  }
}
