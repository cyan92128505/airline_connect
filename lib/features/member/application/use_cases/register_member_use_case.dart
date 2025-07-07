import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/features/member/application/dtos/authentication_dto.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:app/features/member/domain/repositories/member_repository.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

/// Use case for registering a new member
@injectable
class RegisterMemberUseCase
    implements UseCase<MemberDTO, MemberRegistrationDTO> {
  final MemberRepository _memberRepository;

  const RegisterMemberUseCase(this._memberRepository);

  @override
  Future<Either<Failure, MemberDTO>> call(MemberRegistrationDTO params) async {
    try {
      // Validate input parameters
      final validationResult = _validateInput(params);
      if (validationResult != null) {
        return Left(validationResult);
      }

      // Check if member already exists
      final memberNumberVO = MemberNumber.create(params.memberNumber);
      final existsResult = await _memberRepository.exists(memberNumberVO);

      return existsResult.fold((failure) => Left(failure), (exists) async {
        if (exists) {
          return Left(
            ValidationFailure(
              'Member with number ${params.memberNumber} already exists',
            ),
          );
        }

        // Parse tier
        final tier = MemberTier.fromString(params.tier);

        // Create new member
        final member = Member.create(
          memberNumber: params.memberNumber,
          fullName: params.fullName,
          tier: tier,
          email: params.email,
          phone: params.phone,
        );

        // Save member
        final saveResult = await _memberRepository.save(member);

        return saveResult.fold(
          (failure) => Left(failure),
          (_) => Right(MemberDTOExtensions.fromDomain(member)),
        );
      });
    } catch (e) {
      return Left(UnknownFailure('Failed to register member: $e'));
    }
  }

  /// Validate input parameters
  Failure? _validateInput(MemberRegistrationDTO params) {
    if (params.memberNumber.trim().isEmpty) {
      return ValidationFailure('Member number cannot be empty');
    }

    if (params.fullName.trim().isEmpty) {
      return ValidationFailure('Full name cannot be empty');
    }

    if (params.email.trim().isEmpty) {
      return ValidationFailure('Email cannot be empty');
    }

    if (params.phone.trim().isEmpty) {
      return ValidationFailure('Phone cannot be empty');
    }

    if (params.tier.trim().isEmpty) {
      return ValidationFailure('Member tier cannot be empty');
    }

    // Validate email format (basic check)
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(params.email.trim())) {
      return ValidationFailure('Invalid email format');
    }

    // Validate member tier
    try {
      MemberTier.fromString(params.tier);
    } catch (e) {
      return ValidationFailure('Invalid member tier: ${params.tier}');
    }

    return null;
  }
}
