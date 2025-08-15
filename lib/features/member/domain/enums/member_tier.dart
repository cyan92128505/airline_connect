import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';

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

  IconData get icon {
    switch (this) {
      case MemberTier.bronze:
        return Icons.workspace_premium;
      case MemberTier.silver:
        return Icons.military_tech;
      case MemberTier.gold:
        return Icons.diamond;
      case MemberTier.suspended:
        return Icons.block;
    }
  }

  /// Get tier gradient colors
  List<Color> get gradientColors {
    switch (this) {
      case MemberTier.bronze:
        return [const Color(0xFFCD7F32), const Color(0xFFA0522D)];
      case MemberTier.silver:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
      case MemberTier.gold:
        return [const Color(0xFFFFD700), const Color(0xFFB8860B)];
      case MemberTier.suspended:
        return [AppColors.error, const Color(0xFFC62828)];
    }
  }
}
