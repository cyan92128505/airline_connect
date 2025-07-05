import 'package:app/features/member/entities/member.dart';
import 'package:app/features/member/enums/member_tier.dart';
import 'package:objectbox/objectbox.dart';
import 'package:timezone/timezone.dart' as tz;

/// ObjectBox entity for Member domain model
/// Follows official ObjectBox entity design patterns
@Entity()
class MemberEntity {
  /// ObjectBox required ID field - always int type, 0 for auto-assignment
  @Id()
  int id = 0;

  /// Domain member ID - unique identifier from business logic
  @Unique()
  String memberId;

  /// Member number - indexed for fast lookup (primary business key)
  /// This is the main business key, so we use replace strategy here
  @Index()
  @Unique(onConflict: ConflictStrategy.replace)
  String memberNumber;

  /// Full name - indexed for search functionality
  @Index()
  String fullName;

  /// Contact information
  String email;
  String phone;

  /// Member tier as string value
  String tier;

  /// Timestamps stored as DateTime (ObjectBox handles UTC conversion)
  @Property(type: PropertyType.date)
  DateTime? createdAt;

  @Property(type: PropertyType.date)
  DateTime? lastLoginAt;

  /// No-args constructor required by ObjectBox
  MemberEntity()
    : memberId = '',
      memberNumber = '',
      fullName = '',
      email = '',
      phone = '',
      tier = '';

  /// Parameterized constructor for convenience
  MemberEntity.create({
    required this.memberId,
    required this.memberNumber,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.tier,
    this.createdAt,
    this.lastLoginAt,
  });

  /// Convert from Domain Entity to ObjectBox Entity
  /// Factory constructor following ObjectBox best practices
  factory MemberEntity.fromDomain(Member member) {
    return MemberEntity.create(
      memberId: member.memberId.value,
      memberNumber: member.memberNumber.value,
      fullName: member.fullName.value,
      email: member.contactInfo.email,
      phone: member.contactInfo.phone,
      tier: member.tier.value,
      createdAt: member.createdAt?.toUtc(),
      lastLoginAt: member.lastLoginAt?.toUtc(),
    );
  }

  /// Convert from ObjectBox Entity to Domain Entity
  /// Handles timezone conversion properly
  Member toDomain() {
    return Member.fromPersistence(
      memberId: memberId,
      memberNumber: memberNumber,
      fullName: fullName,
      tier: MemberTier.fromString(tier),
      email: email,
      phone: phone,
      createdAt: createdAt != null
          ? tz.TZDateTime.from(createdAt!, tz.local)
          : null,
      lastLoginAt: lastLoginAt != null
          ? tz.TZDateTime.from(lastLoginAt!, tz.local)
          : null,
    );
  }

  /// Update entity from domain object while preserving ObjectBox ID
  void updateFromDomain(Member member) {
    memberId = member.memberId.value;
    memberNumber = member.memberNumber.value;
    fullName = member.fullName.value;
    email = member.contactInfo.email;
    phone = member.contactInfo.phone;
    tier = member.tier.value;
    createdAt = member.createdAt?.toUtc();
    lastLoginAt = member.lastLoginAt?.toUtc();
  }
}
