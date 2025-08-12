import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'boarding_pass_operation_dto.freezed.dart';
part 'boarding_pass_operation_dto.g.dart';

/// DTO for creating boarding pass request
@freezed
abstract class CreateBoardingPassDTO with _$CreateBoardingPassDTO {
  const factory CreateBoardingPassDTO({
    required String memberNumber,
    required String flightNumber,
    required String seatNumber,
  }) = _CreateBoardingPassDTO;

  factory CreateBoardingPassDTO.fromJson(Map<String, Object?> json) =>
      _$CreateBoardingPassDTOFromJson(json);
}

/// DTO for boarding pass operation response
@freezed
abstract class BoardingPassOperationResponseDTO
    with _$BoardingPassOperationResponseDTO {
  const factory BoardingPassOperationResponseDTO({
    required bool success,
    BoardingPassDTO? boardingPass,
    String? errorMessage,
    String? errorCode,
    Map<String, dynamic>? metadata,
  }) = _BoardingPassOperationResponseDTO;

  factory BoardingPassOperationResponseDTO.fromJson(
    Map<String, Object?> json,
  ) => _$BoardingPassOperationResponseDTOFromJson(json);

  factory BoardingPassOperationResponseDTO.success({
    required BoardingPassDTO boardingPass,
    Map<String, dynamic>? metadata,
  }) {
    return BoardingPassOperationResponseDTO(
      success: true,
      boardingPass: boardingPass,
      metadata: metadata,
    );
  }

  factory BoardingPassOperationResponseDTO.error({
    required String errorMessage,
    required String errorCode,
    Map<String, dynamic>? metadata,
  }) {
    return BoardingPassOperationResponseDTO(
      success: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
      metadata: metadata,
    );
  }
}

/// DTO for seat update request
@freezed
abstract class UpdateSeatDTO with _$UpdateSeatDTO {
  const factory UpdateSeatDTO({
    required String passId,
    required String newSeatNumber,
  }) = _UpdateSeatDTO;

  factory UpdateSeatDTO.fromJson(Map<String, Object?> json) =>
      _$UpdateSeatDTOFromJson(json);
}

/// DTO for QR code validation request
@freezed
abstract class QRCodeValidationDTO with _$QRCodeValidationDTO {
  const factory QRCodeValidationDTO({required String qrCodeString}) =
      _QRCodeValidationDTO;

  factory QRCodeValidationDTO.fromJson(Map<String, Object?> json) =>
      _$QRCodeValidationDTOFromJson(json);
}

/// DTO for QR code validation response
@freezed
abstract class QRCodeValidationResponseDTO with _$QRCodeValidationResponseDTO {
  const factory QRCodeValidationResponseDTO({
    required bool isValid,
    String? passId,
    String? flightNumber,
    String? seatNumber,
    String? memberNumber,
    String? departureTime,
    String? errorMessage,
    String? errorCode,
    BoardingPassDTO? boardingPass,
    QRCodePayloadDTO? payload,
    int? timeRemainingMinutes,
    Map<String, dynamic>? metadata,
  }) = _QRCodeValidationResponseDTO;

  factory QRCodeValidationResponseDTO.fromJson(Map<String, Object?> json) =>
      _$QRCodeValidationResponseDTOFromJson(json);

  factory QRCodeValidationResponseDTO.valid({
    required String passId,
    required String flightNumber,
    required String seatNumber,
    required String memberNumber,
    required String departureTime,
    BoardingPassDTO? boardingPass,
    QRCodePayloadDTO? payload,
    int? timeRemainingMinutes,
    Map<String, dynamic>? metadata,
  }) {
    return QRCodeValidationResponseDTO(
      isValid: true,
      passId: passId,
      flightNumber: flightNumber,
      seatNumber: seatNumber,
      memberNumber: memberNumber,
      departureTime: departureTime,
      boardingPass: boardingPass,
      payload: payload,
      timeRemainingMinutes: timeRemainingMinutes,
      metadata: metadata,
    );
  }

  factory QRCodeValidationResponseDTO.invalid({
    required String errorMessage,
    String? errorCode,
    Map<String, dynamic>? metadata,
  }) {
    return QRCodeValidationResponseDTO(
      isValid: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
      metadata: metadata,
    );
  }
}

/// DTO for QR Code Payload - 新增
@freezed
abstract class QRCodePayloadDTO with _$QRCodePayloadDTO {
  const factory QRCodePayloadDTO({
    required String passId,
    required String flightNumber,
    required String seatNumber,
    required String memberNumber,
    required String departureTime,
    required String generatedAt,
    required String nonce,
    required String issuer,
    bool? isExpired,
    int? timeRemainingMinutes,
  }) = _QRCodePayloadDTO;

  factory QRCodePayloadDTO.fromJson(Map<String, Object?> json) =>
      _$QRCodePayloadDTOFromJson(json);

  /// 從 Domain QRCodePayload 轉換
  static QRCodePayloadDTO fromDomain(QRCodePayload payload) {
    return QRCodePayloadDTO(
      passId: payload.passId,
      flightNumber: payload.flightNumber,
      seatNumber: payload.seatNumber,
      memberNumber: payload.memberNumber,
      departureTime: payload.departureTime.toIso8601String(),
      generatedAt: payload.generatedAt.toIso8601String(),
      nonce: payload.nonce,
      issuer: payload.issuer,
      isExpired: payload.isExpired,
      timeRemainingMinutes: payload.timeRemaining?.inMinutes,
    );
  }
}

/// DTO for boarding pass search criteria
@freezed
abstract class BoardingPassSearchDTO with _$BoardingPassSearchDTO {
  const factory BoardingPassSearchDTO({
    String? memberNumber,
    String? flightNumber,
    PassStatus? status,
    bool? activeOnly,
    String? departureDate,
    String? departureFromDate,
    String? departureToDate,
    int? limit,
    int? offset,
  }) = _BoardingPassSearchDTO;

  factory BoardingPassSearchDTO.fromJson(Map<String, Object?> json) =>
      _$BoardingPassSearchDTOFromJson(json);

  factory BoardingPassSearchDTO.activeForMember(String memberNumber) {
    return BoardingPassSearchDTO(memberNumber: memberNumber, activeOnly: true);
  }

  factory BoardingPassSearchDTO.memberByStatus({
    required String memberNumber,
    required PassStatus status,
  }) {
    return BoardingPassSearchDTO(memberNumber: memberNumber, status: status);
  }

  factory BoardingPassSearchDTO.todayForMember(String memberNumber) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return BoardingPassSearchDTO(
      memberNumber: memberNumber,
      departureDate: today,
    );
  }
}

/// DTO for boarding eligibility validation response
@freezed
abstract class BoardingEligibilityResponseDTO
    with _$BoardingEligibilityResponseDTO {
  const factory BoardingEligibilityResponseDTO({
    required bool isEligible,
    required String passId,
    String? reason,
    int? timeUntilDepartureMinutes,
    bool? isInBoardingWindow,
    bool? isQRCodeValid,
    PassStatus? currentStatus,
    Map<String, dynamic>? additionalInfo,
  }) = _BoardingEligibilityResponseDTO;

  factory BoardingEligibilityResponseDTO.fromJson(Map<String, Object?> json) =>
      _$BoardingEligibilityResponseDTOFromJson(json);

  factory BoardingEligibilityResponseDTO.eligible({
    required String passId,
    int? timeUntilDepartureMinutes,
    bool? isInBoardingWindow,
    Map<String, dynamic>? additionalInfo,
  }) {
    return BoardingEligibilityResponseDTO(
      isEligible: true,
      passId: passId,
      timeUntilDepartureMinutes: timeUntilDepartureMinutes,
      isInBoardingWindow: isInBoardingWindow,
      isQRCodeValid: true,
      additionalInfo: additionalInfo,
    );
  }

  factory BoardingEligibilityResponseDTO.ineligible({
    required String passId,
    required String reason,
    PassStatus? currentStatus,
    bool? isQRCodeValid,
    Map<String, dynamic>? additionalInfo,
  }) {
    return BoardingEligibilityResponseDTO(
      isEligible: false,
      passId: passId,
      reason: reason,
      currentStatus: currentStatus,
      isQRCodeValid: isQRCodeValid,
      additionalInfo: additionalInfo,
    );
  }
}

/// DTO for QR code scan result
@freezed
abstract class QRCodeScanResultDTO with _$QRCodeScanResultDTO {
  const factory QRCodeScanResultDTO({
    required bool isValid,
    String? reason,
    BoardingPassDTO? boardingPass,
    QRCodePayloadDTO? payload,
    int? timeRemainingMinutes,
    Map<String, dynamic>? summary,
  }) = _QRCodeScanResultDTO;

  factory QRCodeScanResultDTO.fromJson(Map<String, Object?> json) =>
      _$QRCodeScanResultDTOFromJson(json);

  factory QRCodeScanResultDTO.valid({
    required BoardingPassDTO boardingPass,
    required QRCodePayloadDTO payload,
    int? timeRemainingMinutes,
    Map<String, dynamic>? summary,
  }) {
    return QRCodeScanResultDTO(
      isValid: true,
      boardingPass: boardingPass,
      payload: payload,
      timeRemainingMinutes: timeRemainingMinutes,
      summary: summary,
    );
  }

  factory QRCodeScanResultDTO.invalid(String reason) {
    return QRCodeScanResultDTO(isValid: false, reason: reason);
  }
}

/// DTO for gate boarding validation request
@freezed
abstract class GateBoardingRequestDTO with _$GateBoardingRequestDTO {
  const factory GateBoardingRequestDTO({
    required String qrCodeString,
    required String gateCode,
    String? operatorId,
    Map<String, dynamic>? metadata,
  }) = _GateBoardingRequestDTO;

  factory GateBoardingRequestDTO.fromJson(Map<String, Object?> json) =>
      _$GateBoardingRequestDTOFromJson(json);
}

/// DTO for gate boarding validation response
@freezed
abstract class GateBoardingResponseDTO with _$GateBoardingResponseDTO {
  const factory GateBoardingResponseDTO({
    required bool isApproved,
    required String reason,
    BoardingPassDTO? boardingPass,
    String? gateCode,
    String? operatorId,
    String? validatedAt,
    Map<String, dynamic>? metadata,
  }) = _GateBoardingResponseDTO;

  factory GateBoardingResponseDTO.fromJson(Map<String, Object?> json) =>
      _$GateBoardingResponseDTOFromJson(json);

  factory GateBoardingResponseDTO.approved({
    required BoardingPassDTO boardingPass,
    required String gateCode,
    String? operatorId,
    Map<String, dynamic>? metadata,
  }) {
    return GateBoardingResponseDTO(
      isApproved: true,
      reason: 'Boarding approved',
      boardingPass: boardingPass,
      gateCode: gateCode,
      operatorId: operatorId,
      validatedAt: DateTime.now().toIso8601String(),
      metadata: metadata,
    );
  }

  factory GateBoardingResponseDTO.rejected({
    required String reason,
    String? gateCode,
    String? operatorId,
    Map<String, dynamic>? metadata,
  }) {
    return GateBoardingResponseDTO(
      isApproved: false,
      reason: reason,
      gateCode: gateCode,
      operatorId: operatorId,
      validatedAt: DateTime.now().toIso8601String(),
      metadata: metadata,
    );
  }
}
