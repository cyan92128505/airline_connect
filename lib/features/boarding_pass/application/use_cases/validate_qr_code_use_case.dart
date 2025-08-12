import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/boarding_pass/domain/services/qr_code_service.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';

/// Use case for validating QR code at boarding gate
@injectable
class ValidateQRCodeUseCase
    implements UseCase<QRCodeValidationResponseDTO, QRCodeValidationDTO> {
  final QRCodeService _qrCodeService;

  const ValidateQRCodeUseCase(this._qrCodeService);

  @override
  Future<Either<Failure, QRCodeValidationResponseDTO>> call(
    QRCodeValidationDTO params,
  ) async {
    try {
      final qrCodeData = QRCodeData.fromQRString(params.qrCodeString);

      // Validate and decode QR code using domain service
      final validationResult = _qrCodeService.validate(qrCodeData);

      return validationResult.fold(
        (failure) {
          return Right(
            QRCodeValidationResponseDTO.invalid(errorMessage: failure.message),
          );
        },
        (success) {
          if (success.payload == null) {
            return Left(ValidationFailure('Failed to validate QR code'));
          }

          // Generate scan summary for additional metadata
          final summaryResult = _qrCodeService.generateScanSummary(
            success.payload!,
          );

          return summaryResult.fold(
            // When scan summary fails, return valid response without payload
            (failure) => Right(
              QRCodeValidationResponseDTO.valid(
                passId: success.payload!.passId,
                flightNumber: success.payload!.flightNumber,
                seatNumber: success.payload!.seatNumber,
                memberNumber: success.payload!.memberNumber,
                departureTime: success.payload!.departureTime.toIso8601String(),
              ),
            ),
            // When scan summary succeeds, include payload if summary has data
            (summary) {
              QRCodePayloadDTO? payloadDTO;

              // Only create payload DTO if summary contains required data
              if (summary.isNotEmpty &&
                  summary.containsKey('passId') &&
                  summary.containsKey('flightNumber') &&
                  summary.containsKey('seatNumber') &&
                  summary.containsKey('memberNumber') &&
                  summary.containsKey('departureTime') &&
                  summary.containsKey('generatedAt') &&
                  summary.containsKey('nonce') &&
                  summary.containsKey('issuer')) {
                try {
                  payloadDTO = QRCodePayloadDTO.fromJson(summary);
                } catch (e) {
                  // If JSON parsing fails, continue without payload
                  payloadDTO = null;
                }
              }

              return Right(
                QRCodeValidationResponseDTO.valid(
                  passId: success.payload!.passId,
                  flightNumber: success.payload!.flightNumber,
                  seatNumber: success.payload!.seatNumber,
                  memberNumber: success.payload!.memberNumber,
                  departureTime: success.payload!.departureTime
                      .toIso8601String(),
                  payload: payloadDTO,
                  metadata: summary.isNotEmpty ? summary : null,
                ),
              );
            },
          );
        },
      );
    } on DomainException catch (e) {
      return Right(
        QRCodeValidationResponseDTO.invalid(errorMessage: e.message),
      );
    } catch (e) {
      return Left(UnknownFailure('Failed to validate QR code: $e'));
    }
  }
}
