import 'package:app/core/bootstrap/contracts/initialization_context.dart';
import 'package:app/core/bootstrap/initialization_step.dart';
import 'package:logger/logger.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final Logger _logger = Logger();

/// Initialize timezone database before any DateTime operations
class TimezoneInitializationStep extends InitializationStep {
  const TimezoneInitializationStep(this.timezoneName)
    : super(name: 'Timezone Initialization', isCritical: false);

  final String timezoneName;

  @override
  Future<void> execute(InitializationContext context) async {
    // Initialize timezone database
    tz.initializeTimeZones();

    // Set local timezone - fallback to UTC if timezone not found
    try {
      tz.setLocalLocation(tz.getLocation(timezoneName));
      _logger.i('Timezone set to: $timezoneName');
    } catch (e) {
      _logger.w('Failed to set timezone $timezoneName, using UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }
  }
}
