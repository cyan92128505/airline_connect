import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'authentication_dto.freezed.dart';
part 'authentication_dto.g.dart';

/// DTO for member authentication request
@freezed
abstract class AuthenticationRequestDTO with _$AuthenticationRequestDTO {
  const factory AuthenticationRequestDTO({
    required String memberNumber,
    required String nameSuffix,
  }) = _AuthenticationRequestDTO;

  factory AuthenticationRequestDTO.fromJson(Map<String, Object?> json) =>
      _$AuthenticationRequestDTOFromJson(json);
}

/// DTO for member authentication response
@freezed
abstract class AuthenticationResponseDTO with _$AuthenticationResponseDTO {
  const factory AuthenticationResponseDTO({
    required bool isAuthenticated,
    MemberDTO? member,
    String? errorMessage,
  }) = _AuthenticationResponseDTO;

  factory AuthenticationResponseDTO.fromJson(Map<String, Object?> json) =>
      _$AuthenticationResponseDTOFromJson(json);
}

/// DTO for member registration
@freezed
abstract class MemberRegistrationDTO with _$MemberRegistrationDTO {
  const factory MemberRegistrationDTO({
    required String memberNumber,
    required String fullName,
    required String email,
    required String phone,
    required String tier,
  }) = _MemberRegistrationDTO;

  factory MemberRegistrationDTO.fromJson(Map<String, Object?> json) =>
      _$MemberRegistrationDTOFromJson(json);
}
