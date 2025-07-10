import 'package:flutter/material.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';
import 'package:app/features/shared/presentation/theme/app_colors.dart';

/// Utility class for status-related operations
/// Provides consistent status display and behavior
abstract class StatusHelpers {
  /// Get display text for boarding pass status
  static String getStatusText(PassStatus status) {
    switch (status) {
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

  /// Get color for boarding pass status
  static Color getStatusColor(PassStatus status) {
    switch (status) {
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

  /// Get icon for boarding pass status
  static IconData getStatusIcon(PassStatus status) {
    switch (status) {
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

  /// Check if status allows activation
  static bool canActivate(PassStatus status) {
    return status == PassStatus.issued;
  }

  /// Check if status allows usage
  static bool canUse(PassStatus status) {
    return status == PassStatus.activated;
  }

  /// Check if status is active (can be used for boarding)
  static bool isActiveStatus(PassStatus status) {
    return status == PassStatus.activated;
  }

  /// Check if status is terminal (cannot be changed)
  static bool isTerminalStatus(PassStatus status) {
    return status == PassStatus.used ||
        status == PassStatus.expired ||
        status == PassStatus.cancelled;
  }

  /// Get next possible status transitions
  static List<PassStatus> getNextPossibleStatuses(PassStatus currentStatus) {
    switch (currentStatus) {
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

  /// Get status priority for sorting (lower number = higher priority)
  static int getStatusPriority(PassStatus status) {
    switch (status) {
      case PassStatus.activated:
        return 1; // Highest priority - ready to use
      case PassStatus.issued:
        return 2; // Need activation
      case PassStatus.used:
        return 3; // Recently used
      case PassStatus.expired:
        return 4; // Expired
      case PassStatus.cancelled:
        return 5; // Lowest priority
    }
  }

  /// Get appropriate action text for status
  static String? getActionText(PassStatus status) {
    switch (status) {
      case PassStatus.issued:
        return '啟用登機牌';
      case PassStatus.activated:
        return '顯示 QR Code';
      case PassStatus.used:
      case PassStatus.expired:
      case PassStatus.cancelled:
        return null; // No action available
    }
  }

  /// Get status description for user
  static String getStatusDescription(PassStatus status) {
    switch (status) {
      case PassStatus.issued:
        return '登機牌已發行，請啟用後使用';
      case PassStatus.activated:
        return '登機牌已啟用，可用於登機';
      case PassStatus.used:
        return '登機牌已使用，祝您旅途愉快';
      case PassStatus.expired:
        return '登機牌已過期，請聯繫客服';
      case PassStatus.cancelled:
        return '登機牌已取消，請聯繫客服';
    }
  }

  /// Check if boarding pass is eligible for boarding
  static bool isEligibleForBoarding(PassStatus status, String? departureTime) {
    // Must be activated
    if (status != PassStatus.activated) return false;

    // Check if within boarding window
    if (departureTime != null) {
      try {
        final departure = DateTime.parse(departureTime);
        final now = DateTime.now();
        final minutesUntilDeparture = departure.difference(now).inMinutes;

        // Boarding window: 2 hours before to 30 minutes before departure
        return minutesUntilDeparture >= 30 && minutesUntilDeparture <= 120;
      } catch (e) {
        return false;
      }
    }

    return true;
  }
}
