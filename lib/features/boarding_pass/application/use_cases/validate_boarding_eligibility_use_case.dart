import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/boarding_pass/domain/services/boarding_pass_service.dart';
import 'package:app/features/boarding_pass/domain/repositories/boarding_pass_repository.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';

/// Use case for validating boarding eligibility
@injectable
class ValidateBoardingEligibilityUseCase
    implements UseCase<BoardingEligibilityResponseDTO, String> {
  final BoardingPassService _boardingPassService;
  final BoardingPassRepository _boardingPassRepository;

  const ValidateBoardingEligibilityUseCase(
    this._boardingPassService,
    this._boardingPassRepository,
  );

  @override
  Future<Either<Failure, BoardingEligibilityResponseDTO>> call(
    String passId,
  ) async {
    try {
      // Validate pass ID format
      if (passId.trim().isEmpty) {
        return Right(
          BoardingEligibilityResponseDTO.ineligible(
            passId: passId,
            reason: 'Pass ID cannot be empty',
          ),
        );
      }

      final passIdVO = PassId.fromString(passId);

      // Validate eligibility using domain service
      final eligibilityResult = await _boardingPassService
          .validateBoardingEligibility(passIdVO);

      return eligibilityResult.fold((failure) => Left(failure), (
        isEligible,
      ) async {
        // Get additional boarding pass details for context
        final passResult = await _boardingPassRepository.findByPassId(passIdVO);

        return passResult.fold(
          (failure) => Right(
            BoardingEligibilityResponseDTO.ineligible(
              passId: passId,
              reason:
                  'Unable to retrieve boarding pass details: ${failure.message}',
            ),
          ),
          (boardingPass) {
            if (boardingPass == null) {
              return Right(
                BoardingEligibilityResponseDTO.ineligible(
                  passId: passId,
                  reason: 'Boarding pass not found',
                ),
              );
            }

            final timeUntilDeparture = boardingPass.timeUntilDeparture;
            final isInBoardingWindow =
                boardingPass.scheduleSnapshot.isInBoardingWindow;

            if (isEligible) {
              return Right(
                BoardingEligibilityResponseDTO.eligible(
                  passId: passId,
                  timeUntilDepartureMinutes: timeUntilDeparture?.inMinutes,
                  isInBoardingWindow: isInBoardingWindow,
                  additionalInfo: {
                    'status': boardingPass.status.name,
                    'qrCodeValid': boardingPass.qrCode.isValid,
                    'departureTime': boardingPass.scheduleSnapshot.departureTime
                        .toIso8601String(),
                    'gate': boardingPass.scheduleSnapshot.gate.value,
                  },
                ),
              );
            } else {
              // Determine specific reason for ineligibility
              String reason;
              if (!boardingPass.isActive) {
                reason =
                    'Boarding pass is not active (status: ${boardingPass.status.name})';
              } else if (!isInBoardingWindow) {
                reason = 'Not within boarding window';
              } else if (!boardingPass.qrCode.isValid) {
                reason = 'QR code is invalid or expired';
              } else {
                reason = 'Unknown eligibility issue';
              }

              return Right(
                BoardingEligibilityResponseDTO.ineligible(
                  passId: passId,
                  reason: reason,
                  currentStatus: boardingPass.status,
                  isQRCodeValid: boardingPass.qrCode.isValid,
                  additionalInfo: {
                    'timeUntilDeparture': timeUntilDeparture?.inMinutes,
                    'isInBoardingWindow': isInBoardingWindow,
                    'departureTime': boardingPass.scheduleSnapshot.departureTime
                        .toIso8601String(),
                    'gate': boardingPass.scheduleSnapshot.gate.value,
                  },
                ),
              );
            }
          },
        );
      });
    } on DomainException catch (e) {
      return Right(
        BoardingEligibilityResponseDTO.ineligible(
          passId: passId,
          reason: e.message,
        ),
      );
    } catch (e) {
      return Left(
        UnknownFailure('Failed to validate boarding eligibility: $e'),
      );
    }
  }
}
