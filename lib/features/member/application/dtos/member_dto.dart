import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'member_dto.freezed.dart';
part 'member_dto.g.dart';

/// Data Transfer Object for Member
/// Used for data exchange between Application and Presentation layers
@freezed
abstract class MemberDTO with _$MemberDTO {
  const factory MemberDTO({
    required String memberId,
    required String memberNumber,
    required String fullName,
    required String email,
    required String phone,
    required MemberTier tier,
    String? createdAt,
    String? lastLoginAt,
  }) = _MemberDTO;

  factory MemberDTO.fromJson(Map<String, Object?> json) =>
      _$MemberDTOFromJson(json);
}

extension MemberDTOExtensions on MemberDTO {
  /// Convert from Domain Entity to DTO
  static MemberDTO fromDomain(Member member) {
    return MemberDTO(
      memberId: member.memberId.value,
      memberNumber: member.memberNumber.value,
      fullName: member.fullName.value,
      email: member.contactInfo.email,
      phone: member.contactInfo.phone,
      tier: member.tier,
      createdAt: member.createdAt?.toIso8601String(),
      lastLoginAt: member.lastLoginAt?.toIso8601String(),
    );
  }
}
