import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';
import 'boarding_pass_dto.dart';

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

  /// Factory for success response
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

  /// Factory for error response
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
  const factory QRCodeValidationDTO({
    required String encryptedPayload,
    required String checksum,
    required String generatedAt,
    required int version,
  }) = _QRCodeValidationDTO;

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
    Map<String, dynamic>? payloadData,
  }) = _QRCodeValidationResponseDTO;

  factory QRCodeValidationResponseDTO.fromJson(Map<String, Object?> json) =>
      _$QRCodeValidationResponseDTOFromJson(json);

  /// Factory for valid QR code response
  factory QRCodeValidationResponseDTO.valid({
    required String passId,
    required String flightNumber,
    required String seatNumber,
    required String memberNumber,
    required String departureTime,
    Map<String, dynamic>? payloadData,
  }) {
    return QRCodeValidationResponseDTO(
      isValid: true,
      passId: passId,
      flightNumber: flightNumber,
      seatNumber: seatNumber,
      memberNumber: memberNumber,
      departureTime: departureTime,
      payloadData: payloadData,
    );
  }

  /// Factory for invalid QR code response
  factory QRCodeValidationResponseDTO.invalid({required String errorMessage}) {
    return QRCodeValidationResponseDTO(
      isValid: false,
      errorMessage: errorMessage,
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
    String? departureDate, // ISO date string (YYYY-MM-DD)
    String? departureFromDate, // ISO date string for range queries
    String? departureToDate, // ISO date string for range queries
    int? limit,
    int? offset,
  }) = _BoardingPassSearchDTO;

  factory BoardingPassSearchDTO.fromJson(Map<String, Object?> json) =>
      _$BoardingPassSearchDTOFromJson(json);

  /// Factory for member's active passes
  factory BoardingPassSearchDTO.activeForMember(String memberNumber) {
    return BoardingPassSearchDTO(memberNumber: memberNumber, activeOnly: true);
  }

  /// Factory for member's passes by status
  factory BoardingPassSearchDTO.memberByStatus({
    required String memberNumber,
    required PassStatus status,
  }) {
    return BoardingPassSearchDTO(memberNumber: memberNumber, status: status);
  }

  /// Factory for today's passes
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

  /// Factory for eligible response
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

  /// Factory for ineligible response
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
