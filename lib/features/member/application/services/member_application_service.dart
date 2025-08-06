import 'package:app/core/failures/failure.dart';
import 'package:app/features/member/application/dtos/authentication_dto.dart';
import 'package:app/features/member/application/use_cases/authenticate_member_use_case.dart';
import 'package:app/features/member/application/use_cases/logout_member_use_case.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

/// Application service that orchestrates member use cases
/// Provides a higher-level API for the presentation layer
@injectable
class MemberApplicationService {
  final AuthenticateMemberUseCase _authenticateMemberUseCase;
  final LogoutMemberUseCase _logoutMemberUseCase;

  const MemberApplicationService(
    this._authenticateMemberUseCase,
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

  Future<Either<Failure, bool>> logout(String memberNumber) {
    return _logoutMemberUseCase(memberNumber);
  }
}
