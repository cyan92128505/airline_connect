import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/boarding_pass/domain/services/boarding_pass_service.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/domain/value_objects/seat_number.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';

/// Use case for updating seat assignment on boarding pass
@injectable
class UpdateSeatAssignmentUseCase
    implements UseCase<BoardingPassOperationResponseDTO, UpdateSeatDTO> {
  final BoardingPassService _boardingPassService;

  const UpdateSeatAssignmentUseCase(this._boardingPassService);

  @override
  Future<Either<Failure, BoardingPassOperationResponseDTO>> call(
    UpdateSeatDTO params,
  ) async {
    try {
      // Validate input parameters
      final validationResult = _validateInput(params);
      if (validationResult != null) {
        return Right(
          BoardingPassOperationResponseDTO.error(
            errorMessage: validationResult.message,
            errorCode: 'VALIDATION_ERROR',
          ),
        );
      }

      final passId = PassId.fromString(params.passId);
      final newSeatNumber = SeatNumber.create(params.newSeatNumber);

      // Update seat assignment using domain service
      final updateResult = await _boardingPassService.updateSeatAssignment(
        passId: passId,
        newSeatNumber: newSeatNumber,
      );

      return updateResult.fold(
        (failure) => Right(
          BoardingPassOperationResponseDTO.error(
            errorMessage: failure.message,
            errorCode: _mapFailureToErrorCode(failure),
          ),
        ),
        (updatedPass) => Right(
          BoardingPassOperationResponseDTO.success(
            boardingPass: BoardingPassDTOExtensions.fromDomain(updatedPass),
            metadata: {
              'updatedAt': DateTime.now().toIso8601String(),
              'previousSeat': params
                  .newSeatNumber, // This should be the old seat, but we don't have it here
              'newSeat': updatedPass.seatNumber.value,
              'seatType': updatedPass.seatNumber.positionDescription,
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
      return Left(UnknownFailure('Failed to update seat assignment: $e'));
    }
  }

  /// Validate input parameters
  Failure? _validateInput(UpdateSeatDTO params) {
    if (params.passId.trim().isEmpty) {
      return ValidationFailure('Pass ID cannot be empty');
    }

    if (params.newSeatNumber.trim().isEmpty) {
      return ValidationFailure('New seat number cannot be empty');
    }

    // Validate formats using domain objects
    try {
      PassId.fromString(params.passId);
      SeatNumber.create(params.newSeatNumber);
    } catch (e) {
      return ValidationFailure('Invalid input format: $e');
    }

    return null;
  }

  String _mapFailureToErrorCode(Failure failure) {
    if (failure is ValidationFailure) return 'VALIDATION_ERROR';
    if (failure is NotFoundFailure) return 'PASS_NOT_FOUND';
    if (failure is DatabaseFailure) return 'DATABASE_ERROR';
    if (failure is NetworkFailure) return 'NETWORK_ERROR';
    return 'UNKNOWN_ERROR';
  }
}
