import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/flight/enums/flight_status.dart';

void main() {
  group('FlightStatus Enum Tests', () {
    test('should create from valid string values', () {
      expect(
        FlightStatus.fromString('SCHEDULED'),
        equals(FlightStatus.scheduled),
      );
      expect(FlightStatus.fromString('DELAYED'), equals(FlightStatus.delayed));
      expect(
        FlightStatus.fromString('BOARDING'),
        equals(FlightStatus.boarding),
      );
      expect(
        FlightStatus.fromString('DEPARTED'),
        equals(FlightStatus.departed),
      );
      expect(FlightStatus.fromString('ARRIVED'), equals(FlightStatus.arrived));
      expect(
        FlightStatus.fromString('CANCELLED'),
        equals(FlightStatus.cancelled),
      );
      expect(
        FlightStatus.fromString('DIVERTED'),
        equals(FlightStatus.diverted),
      );
    });

    test('should handle case insensitive input', () {
      expect(
        FlightStatus.fromString('scheduled'),
        equals(FlightStatus.scheduled),
      );
      expect(
        FlightStatus.fromString('Boarding'),
        equals(FlightStatus.boarding),
      );
    });

    test('should throw exception for invalid status', () {
      expect(
        () => FlightStatus.fromString('INVALID'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should return correct display names', () {
      expect(FlightStatus.scheduled.displayName, equals('已排班'));
      expect(FlightStatus.delayed.displayName, equals('延誤'));
      expect(FlightStatus.boarding.displayName, equals('登機中'));
      expect(FlightStatus.departed.displayName, equals('已起飛'));
      expect(FlightStatus.arrived.displayName, equals('已抵達'));
      expect(FlightStatus.cancelled.displayName, equals('已取消'));
      expect(FlightStatus.diverted.displayName, equals('改降'));
    });

    test('should check if status is active', () {
      expect(FlightStatus.scheduled.isActive, isTrue);
      expect(FlightStatus.delayed.isActive, isTrue);
      expect(FlightStatus.boarding.isActive, isTrue);
      expect(FlightStatus.departed.isActive, isTrue);
      expect(FlightStatus.arrived.isActive, isFalse);
      expect(FlightStatus.cancelled.isActive, isFalse);
      expect(FlightStatus.diverted.isActive, isFalse);
    });

    test('should check if status allows boarding', () {
      expect(FlightStatus.scheduled.allowsBoarding, isTrue);
      expect(FlightStatus.delayed.allowsBoarding, isTrue);
      expect(FlightStatus.boarding.allowsBoarding, isTrue);
      expect(FlightStatus.departed.allowsBoarding, isFalse);
      expect(FlightStatus.cancelled.allowsBoarding, isFalse);
    });

    test('should check if status is terminal', () {
      expect(FlightStatus.arrived.isTerminal, isTrue);
      expect(FlightStatus.cancelled.isTerminal, isTrue);
      expect(FlightStatus.diverted.isTerminal, isTrue);
      expect(FlightStatus.scheduled.isTerminal, isFalse);
      expect(FlightStatus.boarding.isTerminal, isFalse);
    });

    test('should return correct priority order', () {
      expect(FlightStatus.boarding.priority, equals(5));
      expect(FlightStatus.delayed.priority, equals(4));
      expect(FlightStatus.scheduled.priority, equals(3));
      expect(FlightStatus.departed.priority, equals(2));
      expect(FlightStatus.cancelled.priority, equals(1));
      expect(FlightStatus.arrived.priority, equals(0));
    });
  });
}
