import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/boarding_pass/domain/services/boarding_pass_service.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';

/// Use case for using a boarding pass (at boarding gate)
@injectable
class UseBoardingPassUseCase
    implements UseCase<BoardingPassOperationResponseDTO, String> {
  final BoardingPassService _boardingPassService;

  const UseBoardingPassUseCase(this._boardingPassService);

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

      // Use boarding pass using domain service
      final useResult = await _boardingPassService.useBoardingPass(passIdVO);

      return useResult.fold(
        (failure) => Right(
          BoardingPassOperationResponseDTO.error(
            errorMessage: failure.message,
            errorCode: _mapFailureToErrorCode(failure),
          ),
        ),
        (usedPass) => Right(
          BoardingPassOperationResponseDTO.success(
            boardingPass: BoardingPassDTOExtensions.fromDomain(usedPass),
            metadata: {
              'usedAt': DateTime.now().toIso8601String(),
              'gate': usedPass.scheduleSnapshot.gate.value,
              'flightNumber': usedPass.flightNumber.value,
              'seatNumber': usedPass.seatNumber.value,
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
      return Left(UnknownFailure('Failed to use boarding pass: $e'));
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
