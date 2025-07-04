import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/flight/value_objects/gate.dart';
import 'package:app/core/exceptions/domain_exception.dart';

void main() {
  group('Gate Value Object Tests', () {
    test('should create valid gate', () {
      final gate = Gate.create('A12');

      expect(gate.value, equals('A12'));
      expect(gate.section, equals('A'));
      expect(gate.number, equals('12'));
    });

    test('should convert to uppercase', () {
      final gate = Gate.create('a12');

      expect(gate.value, equals('A12'));
    });

    test('should handle terminal format', () {
      final gate = Gate.create('T1A15');

      expect(gate.value, equals('T1A15'));
      expect(gate.terminal, equals('T1'));
      expect(gate.section, equals('T'));
      expect(gate.number, equals('1'));
    });

    test('should handle simple gate numbers', () {
      final gate = Gate.create('5');

      expect(gate.value, equals('5'));
      expect(gate.number, equals('5'));
      expect(gate.section, isNull);
    });

    test('should throw exception for invalid characters', () {
      expect(() => Gate.create('A-12'), throwsA(isA<DomainException>()));
    });

    test('should throw exception for empty string', () {
      expect(() => Gate.create(''), throwsA(isA<DomainException>()));
    });

    test('should throw exception for too long gate number', () {
      expect(
        () => Gate.create('VERYLONGGATE'),
        throwsA(isA<DomainException>()),
      );
    });
  });
}
