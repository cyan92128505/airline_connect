import 'package:app/features/flight/domain/value_objects/airport_code.dart';
import 'package:app/features/flight/domain/value_objects/flight_schedule.dart';
import 'package:app/features/flight/domain/value_objects/gate.dart';
import 'package:timezone/timezone.dart';

class FlightScheduleSnapshot {
  final TZDateTime departureTime;
  final TZDateTime boardingTime;
  final AirportCode departure;
  final AirportCode arrival;
  final Gate gate;
  final TZDateTime snapshotTime;

  const FlightScheduleSnapshot({
    required this.departureTime,
    required this.boardingTime,
    required this.departure,
    required this.arrival,
    required this.gate,
    required this.snapshotTime,
  });

  factory FlightScheduleSnapshot.fromSchedule(
    FlightSchedule schedule, {
    required TZDateTime snapshotTime,
  }) {
    return FlightScheduleSnapshot(
      departureTime: schedule.departureTime,
      boardingTime: schedule.boardingTime,
      departure: schedule.departure,
      arrival: schedule.arrival,
      gate: schedule.gate,
      snapshotTime: snapshotTime,
    );
  }

  factory FlightScheduleSnapshot.create({
    required TZDateTime departureTime,
    required TZDateTime boardingTime,
    required String departureAirport,
    required String arrivalAirport,
    required String gateNumber,
    required TZDateTime snapshotTime,
  }) {
    return FlightScheduleSnapshot(
      departureTime: departureTime,
      boardingTime: boardingTime,
      departure: AirportCode.create(departureAirport),
      arrival: AirportCode.create(arrivalAirport),
      gate: Gate.create(gateNumber),
      snapshotTime: snapshotTime,
    );
  }

  bool isStale({Duration threshold = const Duration(hours: 6)}) {
    final now = TZDateTime.now(local);
    return now.difference(snapshotTime) > threshold;
  }

  String get routeDescription {
    return '${departure.displayName} → ${arrival.displayName}';
  }

  String get formattedDepartureTime {
    return '${departureTime.hour.toString().padLeft(2, '0')}:'
        '${departureTime.minute.toString().padLeft(2, '0')}';
  }

  String get formattedBoardingTime {
    return '${boardingTime.hour.toString().padLeft(2, '0')}:'
        '${boardingTime.minute.toString().padLeft(2, '0')}';
  }

  bool get isInBoardingWindow {
    final now = TZDateTime.now(local);
    return now.isAfter(boardingTime) && now.isBefore(departureTime);
  }

  bool get hasDeparted {
    return TZDateTime.now(local).isAfter(departureTime);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlightScheduleSnapshot &&
        other.departureTime == departureTime &&
        other.boardingTime == boardingTime &&
        other.departure == departure &&
        other.arrival == arrival &&
        other.gate == gate &&
        other.snapshotTime == snapshotTime;
  }

  @override
  int get hashCode => Object.hash(
    departureTime,
    boardingTime,
    departure,
    arrival,
    gate,
    snapshotTime,
  );

  @override
  String toString() {
    return 'FlightScheduleSnapshot(${departure.value} -> ${arrival.value}, '
        'departure: $formattedDepartureTime, gate: ${gate.value}, '
        'snapshot: ${snapshotTime.toString()})';
  }
}
