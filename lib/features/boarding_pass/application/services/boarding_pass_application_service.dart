import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/application/use_cases/activate_boarding_pass_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/validate_qr_code_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/get_boarding_passes_for_member_use_case.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';

/// Application service that orchestrates boarding pass use cases
/// Provides a higher-level API for the presentation layer
@injectable
class BoardingPassApplicationService {
  final ActivateBoardingPassUseCase _activateBoardingPassUseCase;
  final ValidateQRCodeUseCase _validateQRCodeUseCase;
  final GetBoardingPassesForMemberUseCase _getBoardingPassesForMemberUseCase;

  const BoardingPassApplicationService(
    this._activateBoardingPassUseCase,
    this._validateQRCodeUseCase,
    this._getBoardingPassesForMemberUseCase,
  );

  /// Activate a boarding pass
  Future<Either<Failure, BoardingPassOperationResponseDTO>>
  activateBoardingPass(String passId) async {
    return _activateBoardingPassUseCase(passId);
  }

  /// Validate QR code at boarding gate
  Future<Either<Failure, QRCodeValidationResponseDTO>> validateQRCode({
    required String qrCodeString,
  }) async {
    final request = QRCodeValidationDTO(qrCodeString: qrCodeString);

    return _validateQRCodeUseCase(request);
  }

  /// Get all boarding passes for a member
  Future<Either<Failure, List<BoardingPassDTO>>> getBoardingPassesForMember(
    String memberNumber, {
    bool activeOnly = false,
    int? limit,
    int? offset,
  }) async {
    final searchParams = BoardingPassSearchDTO(
      memberNumber: memberNumber,
      activeOnly: activeOnly,
      limit: limit,
      offset: offset,
    );

    return _getBoardingPassesForMemberUseCase(searchParams);
  }
}
