import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/flight/value_objects/flight_number.dart';
import 'package:app/core/exceptions/domain_exception.dart';

void main() {
  group('FlightNumber Value Object Tests', () {
    test('should create valid flight number', () {
      final flightNumber = FlightNumber.create('BR857');

      expect(flightNumber.value, equals('BR857'));
      expect(flightNumber.airlineCode, equals('BR'));
      expect(flightNumber.flightSequence, equals('857'));
    });

    test('should convert to uppercase', () {
      final flightNumber = FlightNumber.create('br857');

      expect(flightNumber.value, equals('BR857'));
    });

    test('should handle 3-letter airline codes', () {
      final flightNumber = FlightNumber.create('SAS123');

      expect(flightNumber.value, equals('SAS123'));
      expect(flightNumber.airlineCode, equals('SAS'));
      expect(flightNumber.flightSequence, equals('123'));
    });

    test('should throw exception for invalid format', () {
      expect(
        () => FlightNumber.create('INVALID'),
        throwsA(isA<DomainException>()),
      );
    });

    test('should throw exception for wrong length', () {
      expect(
        () => FlightNumber.create('BR12'),
        throwsA(isA<DomainException>()),
      );
    });

    test('should throw exception for empty string', () {
      expect(() => FlightNumber.create(''), throwsA(isA<DomainException>()));
    });
  });
}
