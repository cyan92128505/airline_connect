import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:dartz/dartz.dart';
import 'package:timezone/timezone.dart' as tz;

/// QR code validation result with detailed information
class QRCodeValidationResult {
  final bool isValid;
  final String? reason;
  final Duration? timeRemaining;
  final QRCodePayload? payload;

  const QRCodeValidationResult({
    required this.isValid,
    this.reason,
    this.timeRemaining,
    this.payload,
  });

  factory QRCodeValidationResult.valid({
    required QRCodePayload payload,
    Duration? timeRemaining,
  }) {
    return QRCodeValidationResult(
      isValid: true,
      payload: payload,
      timeRemaining: timeRemaining,
    );
  }

  factory QRCodeValidationResult.invalid(String reason) {
    return QRCodeValidationResult(isValid: false, reason: reason);
  }
}

/// Domain service for QR code operations
/// No longer depends on Repository - pure business logic
abstract class QRCodeService {
  /// Generate QR code for boarding pass
  Either<Failure, QRCodeData> generate({
    required PassId passId,
    required String flightNumber,
    required String seatNumber,
    required String memberNumber,
    required tz.TZDateTime departureTime,
  });

  /// Validate QR code format and business rules
  Either<Failure, QRCodeValidationResult> validate(QRCodeData qrCode);

  /// Decrypt and parse QR code payload
  Either<Failure, QRCodePayload> decrypt(QRCodeData qrCode);

  /// Check if QR code is expired
  bool isExpired(QRCodeData qrCode);

  /// Get remaining time until expiry
  Duration? getTimeRemaining(QRCodeData qrCode);

  /// Generate scan summary for UI display
  Either<Failure, Map<String, dynamic>> generateScanSummary(
    QRCodePayload payload,
  );
}
