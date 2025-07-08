enum PassStatus {
  issued('ISSUED'),
  activated('ACTIVATED'),
  used('USED'),
  expired('EXPIRED'),
  cancelled('CANCELLED');

  const PassStatus(this.value);

  final String value;

  static PassStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ISSUED':
        return PassStatus.issued;
      case 'ACTIVATED':
        return PassStatus.activated;
      case 'USED':
        return PassStatus.used;
      case 'EXPIRED':
        return PassStatus.expired;
      case 'CANCELLED':
        return PassStatus.cancelled;
      default:
        throw ArgumentError('Invalid pass status: $value');
    }
  }

  String get displayName {
    switch (this) {
      case PassStatus.issued:
        return '已發行';
      case PassStatus.activated:
        return '已啟用';
      case PassStatus.used:
        return '已使用';
      case PassStatus.expired:
        return '已過期';
      case PassStatus.cancelled:
        return '已取消';
    }
  }

  bool get isActive {
    return this == PassStatus.issued || this == PassStatus.activated;
  }

  bool get isTerminal {
    return this == PassStatus.used ||
        this == PassStatus.expired ||
        this == PassStatus.cancelled;
  }

  bool get allowsBoarding {
    return this == PassStatus.activated;
  }

  int get priority {
    switch (this) {
      case PassStatus.activated:
        return 5;
      case PassStatus.issued:
        return 4;
      case PassStatus.used:
        return 3;
      case PassStatus.expired:
        return 2;
      case PassStatus.cancelled:
        return 1;
    }
  }
}
