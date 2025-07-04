// test/unit/features/flight/entities/flight_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:app/features/flight/entities/flight.dart';
import 'package:app/features/flight/value_objects/flight_schedule.dart';
import 'package:app/features/flight/enums/flight_status.dart';
import 'package:app/core/exceptions/domain_exception.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('Flight Entity Tests', () {
    late FlightSchedule testSchedule;

    setUp(() {
      final now = TZDateTime.now(local);
      final boardingTime = now.add(const Duration(hours: 2));
      final departureTime = boardingTime.add(const Duration(hours: 1));

      testSchedule = FlightSchedule.create(
        departureTime: departureTime,
        boardingTime: boardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
      );
    });

    test('should create valid flight with correct data', () {
      final flight = Flight.create(
        flightNumber: 'BR857',
        schedule: testSchedule,
        aircraftType: 'A350',
      );

      expect(flight.flightNumber.value, equals('BR857'));
      expect(flight.schedule, equals(testSchedule));
      expect(flight.status, equals(FlightStatus.scheduled));
      expect(flight.aircraftType, equals('A350'));
      expect(flight.createdAt, isNotNull);
      expect(flight.updatedAt, isNull);
    });

    test('should throw exception for invalid flight number', () {
      expect(
        () => Flight.create(
          flightNumber: 'INVALID',
          schedule: testSchedule,
          aircraftType: 'A350',
        ),
        throwsA(isA<DomainException>()),
      );
    });

    test('should update flight status correctly', () {
      final flight = Flight.create(
        flightNumber: 'BR857',
        schedule: testSchedule,
        aircraftType: 'A350',
      );

      final updatedFlight = flight.updateStatus(FlightStatus.boarding);

      expect(updatedFlight.status, equals(FlightStatus.boarding));
      expect(updatedFlight.updatedAt, isNotNull);
    });

    test('should throw exception for invalid status transition', () {
      final flight = Flight.create(
        flightNumber: 'BR857',
        schedule: testSchedule,
        aircraftType: 'A350',
      );

      expect(
        () => flight.updateStatus(FlightStatus.arrived),
        throwsA(isA<DomainException>()),
      );
    });

    test('should follow valid status transition path', () {
      final flight = Flight.create(
        flightNumber: 'BR857',
        schedule: testSchedule,
        aircraftType: 'A350',
      );

      final boardingFlight = flight.updateStatus(FlightStatus.boarding);
      final departedFlight = boardingFlight.updateStatus(FlightStatus.departed);
      final arrivedFlight = departedFlight.updateStatus(FlightStatus.arrived);

      expect(boardingFlight.status, equals(FlightStatus.boarding));
      expect(departedFlight.status, equals(FlightStatus.departed));
      expect(arrivedFlight.status, equals(FlightStatus.arrived));
    });

    test('should delay flight correctly', () {
      final flight = Flight.create(
        flightNumber: 'BR857',
        schedule: testSchedule,
        aircraftType: 'A350',
      );
      const delayDuration = Duration(minutes: 30);

      final delayedFlight = flight.delay(delayDuration);

      expect(delayedFlight.status, equals(FlightStatus.delayed));
      expect(
        delayedFlight.schedule.departureTime,
        equals(testSchedule.departureTime.add(delayDuration)),
      );
      expect(
        delayedFlight.schedule.boardingTime,
        equals(testSchedule.boardingTime.add(delayDuration)),
      );
    });

    test('should cancel flight correctly', () {
      final flight = Flight.create(
        flightNumber: 'BR857',
        schedule: testSchedule,
        aircraftType: 'A350',
      );

      final cancelledFlight = flight.cancel();

      expect(cancelledFlight.status, equals(FlightStatus.cancelled));
      expect(cancelledFlight.updatedAt, isNotNull);
    });

    test('should throw exception when cancelling departed flight', () {
      final flight =
          Flight.create(
                flightNumber: 'BR857',
                schedule: testSchedule,
                aircraftType: 'A350',
              )
              .updateStatus(FlightStatus.boarding) // scheduled -> boarding
              .updateStatus(FlightStatus.departed); // boarding -> departed

      expect(() => flight.cancel(), throwsA(isA<DomainException>()));
    });

    test('should check if flight is active', () {
      final activeFlight = Flight.create(
        flightNumber: 'BR857',
        schedule: testSchedule,
        aircraftType: 'A350',
      );

      final cancelledFlight = activeFlight.cancel();

      expect(activeFlight.isActive, isTrue);
      expect(cancelledFlight.isActive, isFalse);
    });
  });
}
