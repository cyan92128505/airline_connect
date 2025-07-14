import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:objectbox/objectbox.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

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

  /// Static helper to ensure timezone is available
  /// Call this method during app initialization
  static void ensureTimezoneInitialized() {
    try {
      // Test if timezone is accessible
      final _ = tz.local;
    } catch (e) {
      // Initialize timezone if not already done
      try {
        tz.initializeTimeZones();
      } catch (initError) {
        // Log the error but don't throw - app should continue
        throw ('Warning: Failed to initialize timezone: $initError');
      }
    }
  }

  /// Safe timezone conversion with fallback mechanism
  /// Handles cases where timezone package is not initialized
  tz.TZDateTime? _safeConvertToLocalTime(DateTime? dateTime) {
    if (dateTime == null) return null;

    try {
      // Attempt to use timezone conversion
      return tz.TZDateTime.from(dateTime, tz.local);
    } catch (e) {
      // Fallback strategies in order of preference:

      try {
        // Try to use UTC timezone if local is not available
        return tz.TZDateTime.from(dateTime, tz.UTC);
      } catch (utcError) {
        // If timezone package is completely uninitialized,
        // return the original DateTime (it's already valid)
        return null;
      }
    }
  }

  /// Convert from ObjectBox Entity to Domain Entity
  /// Enhanced with safe timezone conversion
  Member toDomain() {
    return Member.fromPersistence(
      memberId: memberId,
      memberNumber: memberNumber,
      fullName: fullName,
      tier: MemberTier.fromString(tier),
      email: email,
      phone: phone,
      createdAt: _safeConvertToLocalTime(createdAt),
      lastLoginAt: _safeConvertToLocalTime(lastLoginAt),
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
