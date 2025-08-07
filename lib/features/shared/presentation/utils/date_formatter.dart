import 'package:intl/intl.dart';

/// Utility class for date and time formatting
/// Provides consistent date/time display across the application
abstract class DateFormatter {
  // Date format patterns
  static const String _datePattern = 'yyyy年MM月dd日';
  static const String _timePattern = 'HH:mm';
  static const String _dateTimePattern = 'yyyy年MM月dd日 HH:mm';
  static const String _flightTimePattern = 'MM/dd HH:mm';

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

  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) return '${duration.inDays}天';
    if (duration.inHours > 0) return '${duration.inHours}小時';
    if (duration.inMinutes > 0) return '${duration.inMinutes}分鐘';
    return '${duration.inSeconds}秒';
  }
}
