import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/timezone.dart' as tz;
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
      // Reconstruct QR code data from DTO
      final qrCodeData = QRCodeData(
        encryptedPayload: params.encryptedPayload,
        checksum: params.checksum,
        generatedAt: tz.TZDateTime.parse(tz.local, params.generatedAt),
        version: params.version,
      );

      // Validate and decode QR code using domain service
      final validationResult = await _qrCodeService.validateAndDecodeQRCode(
        qrCodeData,
      );

      return validationResult.fold(
        (failure) => Right(
          QRCodeValidationResponseDTO.invalid(errorMessage: failure.message),
        ),
        (payload) {
          // Generate scan summary for additional metadata
          final summaryResult = _qrCodeService.generateScanSummary(payload);

          return summaryResult.fold(
            (failure) => Right(
              QRCodeValidationResponseDTO.valid(
                passId: payload.passId,
                flightNumber: payload.flightNumber,
                seatNumber: payload.seatNumber,
                memberNumber: payload.memberNumber,
                departureTime: payload.departureTime.toIso8601String(),
              ),
            ),
            (summary) => Right(
              QRCodeValidationResponseDTO.valid(
                passId: payload.passId,
                flightNumber: payload.flightNumber,
                seatNumber: payload.seatNumber,
                memberNumber: payload.memberNumber,
                departureTime: payload.departureTime.toIso8601String(),
                payloadData: summary,
              ),
            ),
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
