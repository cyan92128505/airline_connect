import 'package:intl/intl.dart';

/// Utility class for date and time formatting
/// Provides consistent date/time display across the application
abstract class DateFormatter {
  // Date format patterns
  static const String _datePattern = 'yyyy年MM月dd日';
  static const String _timePattern = 'HH:mm';
  static const String _dateTimePattern = 'yyyy年MM月dd日 HH:mm';
  static const String _flightTimePattern = 'MM/dd HH:mm';
  static const String _shortDatePattern = 'MM/dd';

  /// Format date to Chinese format (2025年07月22日)
  static String formatDate(String isoDateString) {
    try {
      final date = DateTime.parse(isoDateString);
      return DateFormat(_datePattern, 'zh_TW').format(date);
    } catch (e) {
      return isoDateString;
    }
  }

  /// Format time to 24-hour format (14:30)
  static String formatTime(String isoDateString) {
    try {
      final dateTime = DateTime.parse(isoDateString);
      return DateFormat(_timePattern).format(dateTime);
    } catch (e) {
      return isoDateString;
    }
  }

  /// Format date and time (2025年07月22日 14:30)
  static String formatDateTime(String isoDateString) {
    try {
      final dateTime = DateTime.parse(isoDateString);
      return DateFormat(_dateTimePattern, 'zh_TW').format(dateTime);
    } catch (e) {
      return isoDateString;
    }
  }

  /// Format flight time for boarding pass (07/22 14:30)
  static String formatFlightTime(String isoDateString) {
    try {
      final dateTime = DateTime.parse(isoDateString);
      return DateFormat(_flightTimePattern).format(dateTime);
    } catch (e) {
      return isoDateString;
    }
  }

  /// Format short date for compact display (07/22)
  static String formatShortDate(String isoDateString) {
    try {
      final date = DateTime.parse(isoDateString);
      return DateFormat(_shortDatePattern).format(date);
    } catch (e) {
      return isoDateString;
    }
  }

  /// Get relative time description (今天、明天、後天、etc.)
  static String getRelativeDate(String isoDateString) {
    try {
      final targetDate = DateTime.parse(isoDateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );

      final difference = target.difference(today).inDays;

      switch (difference) {
        case 0:
          return '今天';
        case 1:
          return '明天';
        case 2:
          return '後天';
        case -1:
          return '昨天';
        case -2:
          return '前天';
        default:
          if (difference > 0) {
            return '$difference天後';
          } else {
            return '${difference.abs()}天前';
          }
      }
    } catch (e) {
      return formatShortDate(isoDateString);
    }
  }

  /// Check if date is today
  static bool isToday(String isoDateString) {
    try {
      final targetDate = DateTime.parse(isoDateString);
      final now = DateTime.now();
      return targetDate.year == now.year &&
          targetDate.month == now.month &&
          targetDate.day == now.day;
    } catch (e) {
      return false;
    }
  }

  /// Check if date is in future
  static bool isFuture(String isoDateString) {
    try {
      final targetDate = DateTime.parse(isoDateString);
      return targetDate.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Get time until departure in minutes
  static int? getMinutesUntilDeparture(String isoDateString) {
    try {
      final departureTime = DateTime.parse(isoDateString);
      final now = DateTime.now();
      final difference = departureTime.difference(now);
      return difference.inMinutes;
    } catch (e) {
      return null;
    }
  }

  /// Format duration in human readable format
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}天 ${duration.inHours % 24}小時';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}小時 ${duration.inMinutes % 60}分鐘';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分鐘';
    } else {
      return '即將起飛';
    }
  }
}
