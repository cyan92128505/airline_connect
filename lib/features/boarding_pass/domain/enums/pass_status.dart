import 'package:flutter/material.dart';
import 'package:app/core/presentation/theme/app_colors.dart';

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

  bool get canActivate => this == PassStatus.issued;

  bool get canUse => this == PassStatus.activated;

  List<PassStatus> get nextPossibleStatuses {
    switch (this) {
      case PassStatus.issued:
        return [PassStatus.activated, PassStatus.cancelled];
      case PassStatus.activated:
        return [PassStatus.used, PassStatus.expired];
      case PassStatus.used:
      case PassStatus.expired:
      case PassStatus.cancelled:
        return []; // Terminal states
    }
  }

  // UI presentation helpers
  Color get displayColor {
    switch (this) {
      case PassStatus.issued:
        return AppColors.issued;
      case PassStatus.activated:
        return AppColors.activated;
      case PassStatus.used:
        return AppColors.used;
      case PassStatus.expired:
        return AppColors.expired;
      case PassStatus.cancelled:
        return AppColors.cancelled;
    }
  }

  IconData get displayIcon {
    switch (this) {
      case PassStatus.issued:
        return Icons.receipt_outlined;
      case PassStatus.activated:
        return Icons.check_circle_outline;
      case PassStatus.used:
        return Icons.airplane_ticket;
      case PassStatus.expired:
        return Icons.schedule;
      case PassStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String? get actionText {
    switch (this) {
      case PassStatus.issued:
        return '啟用登機證';
      case PassStatus.activated:
        return '顯示 QR Code';
      case PassStatus.used:
      case PassStatus.expired:
      case PassStatus.cancelled:
        return null; // No action available
    }
  }

  String get description {
    switch (this) {
      case PassStatus.issued:
        return '登機證已發行，請啟用後使用';
      case PassStatus.activated:
        return '登機證已啟用，可用於登機';
      case PassStatus.used:
        return '登機證已使用，祝您旅途愉快';
      case PassStatus.expired:
        return '登機證已過期，請聯繫客服';
      case PassStatus.cancelled:
        return '登機證已取消，請聯繫客服';
    }
  }
}
