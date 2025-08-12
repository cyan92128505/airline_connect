import 'package:app/core/constant/constant.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:timezone/timezone.dart' as tz;

part 'member_dto.freezed.dart';
part 'member_dto.g.dart';

/// Data Transfer Object for Member
/// Used for data exchange between Application and Presentation layers
@freezed
abstract class MemberDTO with _$MemberDTO {
  const MemberDTO._();
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

  String get formatCreatedAt {
    if (createdAt == null) {
      return '';
    }
    try {
      final tzDateTime = tz.TZDateTime.parse(
        tz.getLocation(AppConstants.appDefaultLocation),
        createdAt!,
      );

      return '${tzDateTime.year}/${tzDateTime.month.toString().padLeft(2, '0')}/${tzDateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  String get formatLastLoginAt {
    if (lastLoginAt == null) {
      return '';
    }
    try {
      final tzDateTime = tz.TZDateTime.parse(
        tz.getLocation(AppConstants.appDefaultLocation),
        lastLoginAt!,
      );

      return '${tzDateTime.year}/${tzDateTime.month.toString().padLeft(2, '0')}/${tzDateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

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

extension MemberDTOExtensions on MemberDTO {
  /// Create an unauthenticated marker instance
  /// This represents "initialized but not authenticated" state
  static MemberDTO unauthenticated() {
    return const MemberDTO(
      memberId: '__unauthenticated__',
      memberNumber: '',
      fullName: '',
      email: '',
      phone: '',
      tier: MemberTier.bronze,
    );
  }

  /// Check if this is an unauthenticated marker instance
  bool get isUnauthenticated => memberId == '__unauthenticated__';

  /// Check if this is a valid authenticated member
  bool get isAuthenticated => !isUnauthenticated && memberNumber.isNotEmpty;

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
