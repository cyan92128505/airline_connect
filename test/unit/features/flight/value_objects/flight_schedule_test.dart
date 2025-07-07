import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:app/features/flight/domain/value_objects/flight_schedule.dart';
import 'package:app/core/exceptions/domain_exception.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('FlightSchedule Value Object Tests', () {
    late TZDateTime futureBoardingTime;
    late TZDateTime futureDepartureTime;

    setUp(() {
      final now = TZDateTime.now(local);
      futureBoardingTime = now.add(const Duration(hours: 2));
      futureDepartureTime = futureBoardingTime.add(const Duration(hours: 1));
    });

    test('should create valid flight schedule', () {
      final schedule = FlightSchedule.create(
        departureTime: futureDepartureTime,
        boardingTime: futureBoardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
      );

      expect(schedule.departureTime, equals(futureDepartureTime));
      expect(schedule.boardingTime, equals(futureBoardingTime));
      expect(schedule.departure.value, equals('TPE'));
      expect(schedule.arrival.value, equals('NRT'));
      expect(schedule.gate.value, equals('A12'));
    });

    test('should delay schedule correctly', () {
      final schedule = FlightSchedule.create(
        departureTime: futureDepartureTime,
        boardingTime: futureBoardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
      );
      const delayDuration = Duration(minutes: 30);

      final delayedSchedule = schedule.delay(delayDuration);

      expect(
        delayedSchedule.departureTime,
        equals(futureDepartureTime.add(delayDuration)),
      );
      expect(
        delayedSchedule.boardingTime,
        equals(futureBoardingTime.add(delayDuration)),
      );
    });

    test('should update gate correctly', () {
      final schedule = FlightSchedule.create(
        departureTime: futureDepartureTime,
        boardingTime: futureBoardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
      );

      final updatedSchedule = schedule.updateGate('B15');

      expect(updatedSchedule.gate.value, equals('B15'));
      expect(updatedSchedule.departureTime, equals(schedule.departureTime));
    });

    test('should throw exception for boarding after departure', () {
      expect(
        () => FlightSchedule.create(
          departureTime: futureBoardingTime,
          boardingTime: futureDepartureTime,
          departureAirport: 'TPE',
          arrivalAirport: 'NRT',
          gateNumber: 'A12',
        ),
        throwsA(isA<DomainException>()),
      );
    });

    test('should throw exception for same departure and arrival airports', () {
      expect(
        () => FlightSchedule.create(
          departureTime: futureDepartureTime,
          boardingTime: futureBoardingTime,
          departureAirport: 'TPE',
          arrivalAirport: 'TPE',
          gateNumber: 'A12',
        ),
        throwsA(isA<DomainException>()),
      );
    });

    test('should throw exception for insufficient boarding time', () {
      final shortBoardingTime = futureDepartureTime.subtract(
        const Duration(minutes: 15),
      );

      expect(
        () => FlightSchedule.create(
          departureTime: futureDepartureTime,
          boardingTime: shortBoardingTime,
          departureAirport: 'TPE',
          arrivalAirport: 'NRT',
          gateNumber: 'A12',
        ),
        throwsA(isA<DomainException>()),
      );
    });
  });
}
