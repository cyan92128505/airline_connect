import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:app/features/member/domain/value_objects/contact_info.dart';
import 'package:app/features/member/domain/value_objects/full_name.dart';
import 'package:app/features/member/domain/value_objects/member_id.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:timezone/timezone.dart';

class Member {
  final MemberId memberId;
  final MemberNumber memberNumber;
  final FullName fullName;
  final MemberTier tier;
  final ContactInfo contactInfo;
  final TZDateTime? createdAt;
  final TZDateTime? lastLoginAt;

  const Member._({
    required this.memberId,
    required this.memberNumber,
    required this.fullName,
    required this.tier,
    required this.contactInfo,
    this.createdAt,
    this.lastLoginAt,
  });

  factory Member.create({
    required String memberNumber,
    required String fullName,
    required MemberTier tier,
    required String email,
    required String phone,
  }) {
    return Member._(
      memberId: MemberId.generate(),
      memberNumber: MemberNumber.create(memberNumber),
      fullName: FullName(fullName),
      tier: tier,
      contactInfo: ContactInfo(email: email, phone: phone),
      createdAt: TZDateTime.now(local),
    );
  }

  factory Member.fromPersistence({
    required String memberId,
    required String memberNumber,
    required String fullName,
    required MemberTier tier,
    required String email,
    required String phone,
    TZDateTime? createdAt,
    TZDateTime? lastLoginAt,
  }) {
    return Member._(
      memberId: MemberId(memberId),
      memberNumber: MemberNumber(memberNumber),
      fullName: FullName(fullName),
      tier: tier,
      contactInfo: ContactInfo(email: email, phone: phone),
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  Member updateLastLogin() {
    return Member._(
      memberId: memberId,
      memberNumber: memberNumber,
      fullName: fullName,
      tier: tier,
      contactInfo: contactInfo,
      createdAt: createdAt,
      lastLoginAt: TZDateTime.now(local),
    );
  }

  Member updateContactInfo({String? email, String? phone}) {
    return Member._(
      memberId: memberId,
      memberNumber: memberNumber,
      fullName: fullName,
      tier: tier,
      contactInfo: contactInfo.update(email: email, phone: phone),
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  Member upgradeTier(MemberTier newTier) {
    if (!_canUpgradeTo(newTier)) {
      throw DomainException(
        'Cannot upgrade from ${tier.name} to ${newTier.name}',
      );
    }

    return Member._(
      memberId: memberId,
      memberNumber: memberNumber,
      fullName: fullName,
      tier: newTier,
      contactInfo: contactInfo,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  bool isEligibleForBoardingPass() {
    return tier != MemberTier.suspended;
  }

  bool validateNameSuffix(String nameSuffix) {
    if (nameSuffix.length != 4) return false;

    final fullNameValue = fullName.value;
    if (fullNameValue.length < 4) return false;

    return fullNameValue.substring(fullNameValue.length - 4) == nameSuffix;
  }

  bool _canUpgradeTo(MemberTier targetTier) {
    const upgradeOrder = [
      MemberTier.bronze,
      MemberTier.silver,
      MemberTier.gold,
    ];

    final currentIndex = upgradeOrder.indexOf(tier);
    final targetIndex = upgradeOrder.indexOf(targetTier);

    if (tier == MemberTier.suspended || targetTier == MemberTier.suspended) {
      return false;
    }

    return targetIndex > currentIndex;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Member && other.memberId == memberId;
  }

  @override
  int get hashCode => memberId.hashCode;

  @override
  String toString() {
    return 'Member(memberId: ${memberId.value}, memberNumber: ${memberNumber.value}, '
        'fullName: ${fullName.value}, tier: ${tier.name})';
  }
}
