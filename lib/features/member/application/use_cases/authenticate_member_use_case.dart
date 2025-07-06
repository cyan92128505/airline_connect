import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/features/member/application/dtos/authentication_dto.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/services/member_auth_service.dart';
import 'package:app/features/member/value_objects/member_number.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

/// Use case for authenticating a member
/// Handles member login with member number and name suffix validation
@injectable
class AuthenticateMemberUseCase
    implements UseCase<AuthenticationResponseDTO, AuthenticationRequestDTO> {
  final MemberAuthService _memberAuthService;

  const AuthenticateMemberUseCase(this._memberAuthService);

  @override
  Future<Either<Failure, AuthenticationResponseDTO>> call(
    AuthenticationRequestDTO params,
  ) async {
    try {
      // Validate input parameters
      final validationResult = _validateInput(params);
      if (validationResult != null) {
        return Left(validationResult);
      }

      // Authenticate member using domain service
      final authResult = await _memberAuthService.authenticateMember(
        memberNumber: params.memberNumber,
        nameSuffix: params.nameSuffix,
      );

      return authResult.fold(
        (failure) => Right(
          AuthenticationResponseDTO(
            isAuthenticated: false,
            errorMessage: failure.message,
          ),
        ),
        (member) => Right(
          AuthenticationResponseDTO(
            isAuthenticated: true,
            member: MemberDTOExtensions.fromDomain(member),
          ),
        ),
      );
    } catch (e) {
      return Left(UnknownFailure('Authentication failed: $e'));
    }
  }

  /// Validate input parameters
  Failure? _validateInput(AuthenticationRequestDTO params) {
    if (params.memberNumber.trim().isEmpty) {
      return ValidationFailure('Member number cannot be empty');
    }

    if (params.nameSuffix.trim().isEmpty) {
      return ValidationFailure('Name suffix cannot be empty');
    }

    if (params.nameSuffix.length != 4) {
      return ValidationFailure('Name suffix must be exactly 4 characters');
    }

    // Validate member number format using domain logic
    try {
      MemberNumber.create(params.memberNumber);
    } catch (e) {
      return ValidationFailure('Invalid member number format: $e');
    }

    return null;
  }
}
