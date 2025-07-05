import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/repositories/boarding_pass_repository.dart';
import 'package:app/features/boarding_pass/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/value_objects/qr_code_data.dart';
import 'package:dartz/dartz.dart';

class QRCodeService {
  final BoardingPassRepository _boardingPassRepository;

  const QRCodeService(this._boardingPassRepository);

  Future<Either<Failure, QRPayload>> validateAndDecodeQRCode(
    QRCodeData qrCode,
  ) async {
    try {
      if (!qrCode.isValid) {
        return Left(ValidationFailure('QR code is invalid or expired'));
      }

      final payload = qrCode.decryptPayload();
      if (payload == null) {
        return Left(ValidationFailure('Failed to decrypt QR code payload'));
      }

      final passId = PassId.fromString(payload.passId);
      final boardingPassResult = await _boardingPassRepository.findByPassId(
        passId,
      );

      return boardingPassResult.fold((failure) => Left(failure), (
        boardingPass,
      ) {
        if (boardingPass == null) {
          return Left(NotFoundFailure('Boarding pass not found'));
        }

        if (!_verifyQRCodeIntegrity(payload, boardingPass)) {
          return Left(
            ValidationFailure('QR code data does not match boarding pass'),
          );
        }

        return Right(payload);
      });
    } on DomainException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to validate QR code: $e'));
    }
  }

  bool _verifyQRCodeIntegrity(QRPayload payload, BoardingPass boardingPass) {
    return payload.passId == boardingPass.passId.value &&
        payload.flightNumber == boardingPass.flightNumber.value &&
        payload.seatNumber == boardingPass.seatNumber.value &&
        payload.memberNumber == boardingPass.memberNumber.value;
  }

  Either<Failure, Duration?> getQRCodeTimeRemaining(QRCodeData qrCode) {
    try {
      final timeRemaining = qrCode.timeRemaining;
      return Right(timeRemaining);
    } catch (e) {
      return Left(ValidationFailure('Failed to check QR code expiry: $e'));
    }
  }

  Either<Failure, Map<String, dynamic>> generateScanSummary(QRPayload payload) {
    try {
      return Right({
        'passId': payload.passId,
        'flightNumber': payload.flightNumber,
        'seatNumber': payload.seatNumber,
        'memberNumber': payload.memberNumber,
        'departureTime': payload.departureTime.toIso8601String(),
        'generatedAt': payload.generatedAt.toIso8601String(),
        'isValid': true,
      });
    } catch (e) {
      return Left(UnknownFailure('Failed to generate scan summary: $e'));
    }
  }
}
