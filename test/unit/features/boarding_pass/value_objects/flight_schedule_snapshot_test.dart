import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:app/features/boarding_pass/value_objects/flight_schedule_snapshot.dart';
import 'package:app/features/flight/value_objects/flight_schedule.dart';
import 'package:app/features/flight/value_objects/airport_code.dart';
import 'package:app/features/flight/value_objects/gate.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('FlightScheduleSnapshot Value Object Tests', () {
    late TZDateTime futureBoardingTime;
    late TZDateTime futureDepartureTime;
    late TZDateTime snapshotTime;

    setUp(() {
      final now = TZDateTime.now(local);
      snapshotTime = now;
      futureBoardingTime = now.add(const Duration(hours: 2));
      futureDepartureTime = futureBoardingTime.add(const Duration(hours: 1));
    });

    test('should create valid flight schedule snapshot', () {
      final snapshot = FlightScheduleSnapshot.create(
        departureTime: futureDepartureTime,
        boardingTime: futureBoardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
        snapshotTime: snapshotTime,
      );

      final flightSchedule = FlightSchedule(
        departureTime: futureDepartureTime,
        boardingTime: futureBoardingTime,
        departure: AirportCode.create('TPE'),
        arrival: AirportCode.create('NRT'),
        gate: Gate.create('A12'),
      );

      expect(snapshot.departureTime, equals(flightSchedule.departureTime));
      expect(snapshot.boardingTime, equals(flightSchedule.boardingTime));
      expect(snapshot.departure, equals(flightSchedule.departure));
      expect(snapshot.arrival, equals(flightSchedule.arrival));
      expect(snapshot.gate, equals(flightSchedule.gate));
      expect(snapshot.snapshotTime, equals(snapshotTime));
    });

    test('should get route description', () {
      final snapshot = FlightScheduleSnapshot.create(
        departureTime: futureDepartureTime,
        boardingTime: futureBoardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
        snapshotTime: snapshotTime,
      );

      final routeDescription = snapshot.routeDescription;

      expect(routeDescription, equals('台北桃園 → 東京成田'));
    });

    test('should format times correctly', () {
      final departureTime = TZDateTime(local, 2025, 7, 15, 14, 30);
      final boardingTime = TZDateTime(local, 2025, 7, 15, 13, 30);

      final snapshot = FlightScheduleSnapshot.create(
        departureTime: departureTime,
        boardingTime: boardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
        snapshotTime: snapshotTime,
      );

      expect(snapshot.formattedDepartureTime, equals('14:30'));
      expect(snapshot.formattedBoardingTime, equals('13:30'));
    });

    test('should check if snapshot is stale', () {
      final oldSnapshotTime = TZDateTime.now(
        local,
      ).subtract(const Duration(hours: 8));
      final snapshot = FlightScheduleSnapshot.create(
        departureTime: futureDepartureTime,
        boardingTime: futureBoardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
        snapshotTime: oldSnapshotTime,
      );

      expect(snapshot.isStale(), isTrue);
    });
  });
}
