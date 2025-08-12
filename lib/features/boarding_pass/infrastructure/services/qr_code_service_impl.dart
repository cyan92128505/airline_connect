import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/domain/services/crypto_service.dart';
import 'package:app/features/boarding_pass/domain/services/qr_code_service.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:dartz/dartz.dart';
import 'package:timezone/timezone.dart' as tz;

/// Default QR code service implementation
class QRCodeServiceImpl implements QRCodeService {
  final CryptoService _cryptoService;
  final QRCodeConfig _config;

  const QRCodeServiceImpl(this._cryptoService, this._config);

  @override
  Either<Failure, QRCodeData> generate({
    required PassId passId,
    required String flightNumber,
    required String seatNumber,
    required String memberNumber,
    required tz.TZDateTime departureTime,
  }) {
    try {
      final generatedAt = tz.TZDateTime.now(tz.local);
      final nonce = _cryptoService.generateNonce();

      final payload = QRCodePayload(
        passId: passId.value,
        flightNumber: flightNumber,
        seatNumber: seatNumber,
        memberNumber: memberNumber,
        departureTime: departureTime,
        generatedAt: generatedAt,
        nonce: nonce,
        issuer: _config.issuer,
      );

      final jsonPayload = payload.toJsonString();

      // Create metadata for authenticated encryption
      final metadata = {
        'version': _config.currentVersion,
        'timestamp': generatedAt.millisecondsSinceEpoch,
      };

      final encryptedToken = _cryptoService.encrypt(
        jsonPayload,
        _config.encryptionKey,
        metadata: metadata,
      );

      // Generate signature for the complete token + timestamp
      final signatureData =
          '$encryptedToken.${generatedAt.millisecondsSinceEpoch}';
      final signature = _cryptoService.generateSignature(
        signatureData,
        _config.signingSecret,
      );

      final qrCodeData = QRCodeData.create(
        token: encryptedToken,
        signature: signature,
        generatedAt: generatedAt,
        version: _config.currentVersion,
      );

      return Right(qrCodeData);
    } on DomainException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to generate QR code: $e'));
    }
  }

  @override
  Either<Failure, QRCodeValidationResult> validate(QRCodeData qrCode) {
    try {
      // Step 1: Check signature first
      final signatureData =
          '${qrCode.token}.${qrCode.generatedAt.millisecondsSinceEpoch}';
      final isSignatureValid = _cryptoService.verifySignature(
        signatureData,
        qrCode.signature,
        _config.signingSecret,
      );

      if (!isSignatureValid) {
        return Right(QRCodeValidationResult.invalid('Invalid signature'));
      }

      // Step 2: Check version compatibility
      if (qrCode.version > _config.currentVersion) {
        return Right(
          QRCodeValidationResult.invalid('Unsupported QR code version'),
        );
      }

      // Step 3: Check basic expiration
      final now = tz.TZDateTime.now(tz.local);
      final expiryTime = qrCode.generatedAt.add(_config.validityDuration);

      if (now.isAfter(expiryTime)) {
        return Right(QRCodeValidationResult.invalid('QR code has expired'));
      }

      // Step 4: Decrypt and validate payload
      final decryptResult = decrypt(qrCode);
      return decryptResult.fold((failure) => Left(failure), (payload) {
        // Step 5: Business rule validations
        final businessValidation = _validateBusinessRules(payload);
        if (businessValidation != null) {
          return Right(QRCodeValidationResult.invalid(businessValidation));
        }

        final timeRemaining = expiryTime.difference(now);
        return Right(
          QRCodeValidationResult.valid(
            payload: payload,
            timeRemaining: timeRemaining,
          ),
        );
      });
    } catch (e) {
      return Left(UnknownFailure('QR code validation failed: $e'));
    }
  }

  @override
  Either<Failure, QRCodePayload> decrypt(QRCodeData qrCode) {
    try {
      final metadata = {
        'version': qrCode.version,
        'timestamp': qrCode.generatedAt.millisecondsSinceEpoch,
      };

      final decryptedJson = _cryptoService.decrypt(
        qrCode.token,
        _config.encryptionKey,
        metadata: metadata,
      );

      final payload = QRCodePayload.fromJsonString(decryptedJson);

      // Verify payload consistency
      if (!_verifyPayloadConsistency(payload, qrCode)) {
        return Left(ValidationFailure('Payload consistency check failed'));
      }

      return Right(payload);
    } on DomainException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to decrypt QR code: $e'));
    }
  }

  @override
  bool isExpired(QRCodeData qrCode) {
    final now = tz.TZDateTime.now(tz.local);
    final expiryTime = qrCode.generatedAt.add(_config.validityDuration);
    return now.isAfter(expiryTime);
  }

  @override
  Duration? getTimeRemaining(QRCodeData qrCode) {
    if (isExpired(qrCode)) return null;

    final now = tz.TZDateTime.now(tz.local);
    final expiryTime = qrCode.generatedAt.add(_config.validityDuration);
    return expiryTime.difference(now);
  }

  @override
  Either<Failure, Map<String, dynamic>> generateScanSummary(
    QRCodePayload payload,
  ) {
    try {
      return Right({
        'passId': payload.passId,
        'flightNumber': payload.flightNumber,
        'seatNumber': payload.seatNumber,
        'memberNumber': payload.memberNumber,
        'departureTime': payload.departureTime.toIso8601String(),
        'generatedAt': payload.generatedAt.toIso8601String(),
        'issuer': payload.issuer,
        'nonce': payload.nonce,
        'isExpired': payload.isExpired,
        'timeRemaining': payload.timeRemaining?.inMinutes,
      });
    } catch (e) {
      return Left(UnknownFailure('Failed to generate scan summary: $e'));
    }
  }

  /// Validate business rules specific to QR codes
  String? _validateBusinessRules(QRCodePayload payload) {
    // Check issuer
    if (payload.issuer != _config.issuer) {
      return 'Invalid issuer: ${payload.issuer}';
    }

    // Check payload expiration (separate from QR code expiration)
    if (payload.isExpired) {
      return 'Payload has expired';
    }

    // Check generation time is not in the future
    final now = tz.TZDateTime.now(tz.local);
    if (payload.generatedAt.isAfter(now.add(const Duration(minutes: 5)))) {
      return 'QR code generated in the future';
    }

    // Check departure time is reasonable
    final maxFutureTime = now.add(const Duration(days: 365));
    if (payload.departureTime.isAfter(maxFutureTime)) {
      return 'Departure time too far in the future';
    }

    // Check nonce format
    if (payload.nonce.isEmpty || payload.nonce.length < 16) {
      return 'Invalid nonce format';
    }

    return null; // All validations passed
  }

  /// Verify payload consistency with QR code metadata
  bool _verifyPayloadConsistency(QRCodePayload payload, QRCodeData qrCode) {
    // Verify timestamps match
    final timeDifference = payload.generatedAt
        .difference(qrCode.generatedAt)
        .abs();
    if (timeDifference > const Duration(seconds: 1)) {
      return false;
    }

    // Additional consistency checks can be added here
    return true;
  }
}
