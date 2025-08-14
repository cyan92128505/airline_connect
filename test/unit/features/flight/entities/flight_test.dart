import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart';
import 'package:app/features/flight/domain/entities/flight.dart';
import 'package:app/features/flight/domain/value_objects/flight_schedule.dart';
import 'package:app/features/flight/domain/enums/flight_status.dart';
import 'package:app/core/exceptions/domain_exception.dart';

import '../../../../helpers/test_timezone_helper.dart';

void main() {
  setUpAll(() {
    TestTimezoneHelper.setupForTesting();
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
  });
}
