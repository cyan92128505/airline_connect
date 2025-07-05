import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/boarding_pass/value_objects/seat_number.dart';
import 'package:app/core/exceptions/domain_exception.dart';

void main() {
  group('SeatNumber Value Object Tests', () {
    test('should create valid seat number', () {
      final seatNumber = SeatNumber.create('12A');

      expect(seatNumber.value, equals('12A'));
      expect(seatNumber.rowNumber, equals(12));
      expect(seatNumber.seatLetter, equals('A'));
    });

    test('should convert to uppercase', () {
      final seatNumber = SeatNumber.create('12a');

      expect(seatNumber.value, equals('12A'));
    });

    test('should identify window seat correctly', () {
      final windowSeat = SeatNumber.create('12A');
      final aiseSeat = SeatNumber.create('12C');

      expect(windowSeat.isWindowSeat, isTrue);
      expect(aiseSeat.isWindowSeat, isFalse);
    });

    test('should identify aisle seat correctly', () {
      final aiseSeat = SeatNumber.create('12C');
      final windowSeat = SeatNumber.create('12A');

      expect(aiseSeat.isAisleSeat, isTrue);
      expect(windowSeat.isAisleSeat, isFalse);
    });

    test('should identify middle seat correctly', () {
      final middleSeat = SeatNumber.create('12B');
      final windowSeat = SeatNumber.create('12A');

      expect(middleSeat.isMiddleSeat, isTrue);
      expect(windowSeat.isMiddleSeat, isFalse);
    });

    test('should get position description', () {
      expect(SeatNumber.create('12A').positionDescription, equals('靠窗'));
      expect(SeatNumber.create('12B').positionDescription, equals('中間'));
      expect(SeatNumber.create('12C').positionDescription, equals('靠走道'));
    });

    test('should throw exception for invalid format', () {
      expect(
        () => SeatNumber.create('INVALID'),
        throwsA(isA<DomainException>()),
      );
    });

    test('should throw exception for invalid seat letter', () {
      expect(
        () => SeatNumber.create('12I'), // I is not used in aircraft
        throwsA(isA<DomainException>()),
      );
    });

    test('should throw exception for empty string', () {
      expect(() => SeatNumber.create(''), throwsA(isA<DomainException>()));
    });

    test('should handle three-digit row numbers', () {
      final seatNumber = SeatNumber.create('123A');

      expect(seatNumber.value, equals('123A'));
      expect(seatNumber.rowNumber, equals(123));
      expect(seatNumber.seatLetter, equals('A'));
    });
  });
}
