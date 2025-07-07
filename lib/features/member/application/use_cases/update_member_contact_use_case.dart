import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/domain/repositories/member_repository.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'update_member_contact_use_case.freezed.dart';

/// DTO for updating member contact information
@freezed
abstract class UpdateContactRequestDTO with _$UpdateContactRequestDTO {
  const factory UpdateContactRequestDTO({
    required String memberNumber,
    String? email,
    String? phone,
  }) = _UpdateContactRequestDTO;
}

/// Use case for updating member contact information
@injectable
class UpdateMemberContactUseCase
    implements UseCase<MemberDTO, UpdateContactRequestDTO> {
  final MemberRepository _memberRepository;

  const UpdateMemberContactUseCase(this._memberRepository);

  @override
  Future<Either<Failure, MemberDTO>> call(
    UpdateContactRequestDTO params,
  ) async {
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

        // Update contact information
        final updatedMember = member.updateContactInfo(
          email: params.email,
          phone: params.phone,
        );

        // Save updated member
        final saveResult = await _memberRepository.save(updatedMember);

        return saveResult.fold(
          (failure) => Left(failure),
          (_) => Right(MemberDTOExtensions.fromDomain(updatedMember)),
        );
      });
    } catch (e) {
      return Left(UnknownFailure('Failed to update member contact: $e'));
    }
  }

  /// Validate input parameters
  Failure? _validateInput(UpdateContactRequestDTO params) {
    if (params.memberNumber.trim().isEmpty) {
      return ValidationFailure('Member number cannot be empty');
    }

    // At least one field must be provided for update
    if (params.email == null && params.phone == null) {
      return ValidationFailure(
        'At least one contact field (email or phone) must be provided',
      );
    }

    // Validate email format if provided
    if (params.email != null && params.email!.trim().isNotEmpty) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(params.email!.trim())) {
        return ValidationFailure('Invalid email format');
      }
    }

    // Validate phone format if provided
    if (params.phone != null && params.phone!.trim().isNotEmpty) {
      final phoneRegex = RegExp(r'^(\+\d{1,3})?[0-9]{9,15}$');
      final cleanPhone = params.phone!.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (!phoneRegex.hasMatch(cleanPhone)) {
        return ValidationFailure('Invalid phone number format');
      }
    }

    return null;
  }
}
