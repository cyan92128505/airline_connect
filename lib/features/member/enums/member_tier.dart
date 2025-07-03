enum MemberTier {
  bronze('BRONZE'),
  silver('SILVER'),
  gold('GOLD'),
  suspended('SUSPENDED');

  const MemberTier(this.value);

  final String value;

  static MemberTier fromString(String value) {
    switch (value.toUpperCase()) {
      case 'BRONZE':
        return MemberTier.bronze;
      case 'SILVER':
        return MemberTier.silver;
      case 'GOLD':
        return MemberTier.gold;
      case 'SUSPENDED':
        return MemberTier.suspended;
      default:
        throw ArgumentError('Invalid member tier: $value');
    }
  }

  String get displayName {
    switch (this) {
      case MemberTier.bronze:
        return '銅級會員';
      case MemberTier.silver:
        return '銀級會員';
      case MemberTier.gold:
        return '金級會員';
      case MemberTier.suspended:
        return '暫停會員';
    }
  }

  bool get hasPrivilege {
    return this != MemberTier.suspended;
  }

  int get priority {
    switch (this) {
      case MemberTier.bronze:
        return 1;
      case MemberTier.silver:
        return 2;
      case MemberTier.gold:
        return 3;
      case MemberTier.suspended:
        return 0;
    }
  }
}
