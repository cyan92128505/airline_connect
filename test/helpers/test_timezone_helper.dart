// test/helpers/timezone_test_helper.dart
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Unified timezone setup for all tests
/// Ensures test environment matches production timezone behavior
class TestTimezoneHelper {
  /// Setup timezone for testing with consistent behavior
  /// Default timezone matches production default ('Asia/Taipei')
  static void setupForTesting([String timezoneName = 'Asia/Taipei']) {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(timezoneName));
  }

  /// Setup timezone for UTC-based testing
  /// Useful for testing QR code validation and cross-timezone scenarios
  static void setupForUtcTesting() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
  }

  /// Setup timezone for specific timezone testing
  /// Useful for testing different airport timezones
  static void setupForSpecificTimezone(String timezoneName) {
    tz.initializeTimeZones();

    try {
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (e) {
      // Fallback to UTC if timezone not found
      tz.setLocalLocation(tz.UTC);
      throw ArgumentError('Timezone $timezoneName not found, using UTC');
    }
  }

  /// Get current timezone info for debugging
  static String getCurrentTimezoneInfo() {
    return 'Current timezone: ${tz.local.name}';
  }

  /// Restore timezone to system default (cleanup)
  static void cleanup() {
    // Reset to system timezone if needed
    // Note: In tests, this is usually not necessary
  }
}

/// Mixin for test classes that need timezone setup
/// Usage: class MyTest extends TestCase with TimezoneTestMixin
mixin TimezoneTestMixin {
  /// Setup timezone before all tests in the class
  void setupTimezoneForTesting([String timezoneName = 'Asia/Taipei']) {
    TestTimezoneHelper.setupForTesting(timezoneName);
  }
}

/// Test helper for creating TZDateTime instances in specific timezones
class TimezoneTestDataFactory {
  /// Create TZDateTime in Taipei timezone (production default)
  static tz.TZDateTime createTaipeiTime(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
    int second = 0,
  ]) {
    final location = tz.getLocation('Asia/Taipei');
    return tz.TZDateTime(location, year, month, day, hour, minute, second);
  }

  /// Create TZDateTime in Tokyo timezone (for cross-timezone testing)
  static tz.TZDateTime createTokyoTime(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
    int second = 0,
  ]) {
    final location = tz.getLocation('Asia/Tokyo');
    return tz.TZDateTime(location, year, month, day, hour, minute, second);
  }

  /// Create TZDateTime in Los Angeles timezone (for DST testing)
  static tz.TZDateTime createLosAngelesTime(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
    int second = 0,
  ]) {
    final location = tz.getLocation('America/Los_Angeles');
    return tz.TZDateTime(location, year, month, day, hour, minute, second);
  }

  /// Create UTC TZDateTime
  static tz.TZDateTime createUtcTime(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
    int second = 0,
  ]) {
    return tz.TZDateTime.utc(year, month, day, hour, minute, second);
  }

  /// Create TZDateTime for testing boarding window scenarios
  static Map<String, tz.TZDateTime> createBoardingWindowTimes({
    tz.Location? location,
    Duration boardingDuration = const Duration(hours: 1),
  }) {
    location ??= tz.local;
    final now = tz.TZDateTime.now(location);
    final boardingTime = now.add(const Duration(hours: 2));
    final departureTime = boardingTime.add(boardingDuration);

    return {
      'now': now,
      'boardingTime': boardingTime,
      'departureTime': departureTime,
    };
  }
}
