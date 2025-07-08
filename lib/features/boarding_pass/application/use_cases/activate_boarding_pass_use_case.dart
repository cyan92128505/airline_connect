import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/boarding_pass/domain/services/boarding_pass_service.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';

/// Use case for activating a boarding pass
@injectable
class ActivateBoardingPassUseCase
    implements UseCase<BoardingPassOperationResponseDTO, String> {
  final BoardingPassService _boardingPassService;

  const ActivateBoardingPassUseCase(this._boardingPassService);

  @override
  Future<Either<Failure, BoardingPassOperationResponseDTO>> call(
    String passId,
  ) async {
    try {
      // Validate pass ID format
      if (passId.trim().isEmpty) {
        return Right(
          BoardingPassOperationResponseDTO.error(
            errorMessage: 'Pass ID cannot be empty',
            errorCode: 'VALIDATION_ERROR',
          ),
        );
      }

      final passIdVO = PassId.fromString(passId);

      // Activate boarding pass using domain service
      final activateResult = await _boardingPassService.activateBoardingPass(
        passIdVO,
      );

      return activateResult.fold(
        (failure) => Right(
          BoardingPassOperationResponseDTO.error(
            errorMessage: failure.message,
            errorCode: _mapFailureToErrorCode(failure),
          ),
        ),
        (activatedPass) => Right(
          BoardingPassOperationResponseDTO.success(
            boardingPass: BoardingPassDTOExtensions.fromDomain(activatedPass),
            metadata: {
              'activatedAt': DateTime.now().toIso8601String(),
              'timeUntilDeparture': activatedPass.timeUntilDeparture?.inMinutes,
              'isInBoardingWindow':
                  activatedPass.scheduleSnapshot.isInBoardingWindow,
            },
          ),
        ),
      );
    } on DomainException catch (e) {
      return Right(
        BoardingPassOperationResponseDTO.error(
          errorMessage: e.message,
          errorCode: 'DOMAIN_VALIDATION_ERROR',
        ),
      );
    } catch (e) {
      return Left(UnknownFailure('Failed to activate boarding pass: $e'));
    }
  }

  String _mapFailureToErrorCode(Failure failure) {
    if (failure is ValidationFailure) return 'VALIDATION_ERROR';
    if (failure is NotFoundFailure) return 'PASS_NOT_FOUND';
    if (failure is DatabaseFailure) return 'DATABASE_ERROR';
    if (failure is NetworkFailure) return 'NETWORK_ERROR';
    return 'UNKNOWN_ERROR';
  }
}
