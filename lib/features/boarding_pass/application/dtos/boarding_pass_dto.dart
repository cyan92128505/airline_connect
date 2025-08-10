import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';

part 'boarding_pass_dto.freezed.dart';
part 'boarding_pass_dto.g.dart';

/// Data Transfer Object for BoardingPass
@freezed
abstract class BoardingPassDTO with _$BoardingPassDTO {
  const factory BoardingPassDTO({
    required String passId,
    required String memberNumber,
    required String flightNumber,
    required String seatNumber,
    required FlightScheduleSnapshotDTO scheduleSnapshot,
    required PassStatus status,
    required QRCodeDataDTO qrCode,
    required String issueTime,
    String? activatedAt,
    String? usedAt,
    bool? isValidForBoarding,
    bool? isActive,
    int? timeUntilDepartureMinutes,
  }) = _BoardingPassDTO;

  factory BoardingPassDTO.fromJson(Map<String, Object?> json) =>
      _$BoardingPassDTOFromJson(json);
}

/// Data Transfer Object for Flight Schedule Snapshot
@freezed
abstract class FlightScheduleSnapshotDTO with _$FlightScheduleSnapshotDTO {
  const factory FlightScheduleSnapshotDTO({
    required String departureTime,
    required String boardingTime,
    required String departure,
    required String arrival,
    required String gate,
    required String snapshotTime,
    String? routeDescription,
    String? formattedDepartureTime,
    String? formattedBoardingTime,
    bool? isInBoardingWindow,
    bool? hasDeparted,
  }) = _FlightScheduleSnapshotDTO;

  factory FlightScheduleSnapshotDTO.fromJson(Map<String, Object?> json) =>
      _$FlightScheduleSnapshotDTOFromJson(json);
}

/// Data Transfer Object for QR Code Data
@freezed
abstract class QRCodeDataDTO with _$QRCodeDataDTO {
  const factory QRCodeDataDTO({
    required String token,
    required String signature,
    required String generatedAt,
    required int version,
    required bool isValid,
    int? timeRemainingMinutes,
    String? qrString,
  }) = _QRCodeDataDTO;

  factory QRCodeDataDTO.fromJson(Map<String, Object?> json) =>
      _$QRCodeDataDTOFromJson(json);
}

extension BoardingPassDTOExtensions on BoardingPassDTO {
  /// Convert from Domain Entity to DTO
  static BoardingPassDTO fromDomain(BoardingPass boardingPass) {
    return BoardingPassDTO(
      passId: boardingPass.passId.value,
      memberNumber: boardingPass.memberNumber.value,
      flightNumber: boardingPass.flightNumber.value,
      seatNumber: boardingPass.seatNumber.value,
      scheduleSnapshot: FlightScheduleSnapshotDTO(
        departureTime: boardingPass.scheduleSnapshot.departureTime
            .toIso8601String(),
        boardingTime: boardingPass.scheduleSnapshot.boardingTime
            .toIso8601String(),
        departure: boardingPass.scheduleSnapshot.departure.value,
        arrival: boardingPass.scheduleSnapshot.arrival.value,
        gate: boardingPass.scheduleSnapshot.gate.value,
        snapshotTime: boardingPass.scheduleSnapshot.snapshotTime
            .toIso8601String(),
        routeDescription: boardingPass.scheduleSnapshot.routeDescription,
        formattedDepartureTime:
            boardingPass.scheduleSnapshot.formattedDepartureTime,
        formattedBoardingTime:
            boardingPass.scheduleSnapshot.formattedBoardingTime,
        isInBoardingWindow: boardingPass.scheduleSnapshot.isInBoardingWindow,
        hasDeparted: boardingPass.scheduleSnapshot.hasDeparted,
      ),
      status: boardingPass.status,
      qrCode: QRCodeDataDTO(
        token: boardingPass.qrCode.token,
        signature: boardingPass.qrCode.signature,
        generatedAt: boardingPass.qrCode.generatedAt.toIso8601String(),
        version: boardingPass.qrCode.version,
        isValid: boardingPass.qrCode.isValid,
        timeRemainingMinutes: boardingPass.qrCode.timeRemaining?.inMinutes,
        qrString: boardingPass.qrCode.toQRString(),
      ),
      issueTime: boardingPass.issueTime.toIso8601String(),
      activatedAt: boardingPass.activatedAt?.toIso8601String(),
      usedAt: boardingPass.usedAt?.toIso8601String(),
      isValidForBoarding: boardingPass.isValidForBoarding,
      isActive: boardingPass.isActive,
      timeUntilDepartureMinutes: boardingPass.timeUntilDeparture?.inMinutes,
    );
  }

  /// Validate DTO data integrity
  bool isValid() {
    try {
      if (passId.trim().isEmpty) return false;
      if (memberNumber.trim().isEmpty) return false;
      if (flightNumber.trim().isEmpty) return false;
      if (seatNumber.trim().isEmpty) return false;

      // Validate date formats
      DateTime.parse(issueTime);
      DateTime.parse(scheduleSnapshot.departureTime);
      DateTime.parse(scheduleSnapshot.boardingTime);

      if (activatedAt != null) {
        DateTime.parse(activatedAt!);
      }

      if (usedAt != null) {
        DateTime.parse(usedAt!);
      }

      // Validate QR code data
      if (qrCode.token.trim().isEmpty) return false;
      if (qrCode.signature.trim().isEmpty) return false;
      DateTime.parse(qrCode.generatedAt);

      return true;
    } catch (e) {
      return false;
    }
  }
}
