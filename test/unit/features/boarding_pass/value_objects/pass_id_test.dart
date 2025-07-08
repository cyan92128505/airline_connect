import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/core/exceptions/domain_exception.dart';

void main() {
  group('PassId Value Object Tests', () {
    test('should generate valid pass ID with BP prefix', () {
      final passId = PassId.generate();

      expect(passId.value, startsWith('BP'));
      expect(passId.value.length, equals(10));
      expect(passId.value, matches(RegExp(r'^BP[A-Z0-9]{8}$')));
    });

    test('should create from valid string', () {
      final passId = PassId.fromString('BP12345678');

      expect(passId.value, equals('BP12345678'));
    });

    test('should throw exception for invalid format', () {
      expect(
        () => PassId.fromString('INVALID'),
        throwsA(isA<DomainException>()),
      );
    });

    test('should throw exception for wrong prefix', () {
      expect(
        () => PassId.fromString('AA12345678'),
        throwsA(isA<DomainException>()),
      );
    });

    test('should throw exception for wrong length', () {
      expect(() => PassId.fromString('BP123'), throwsA(isA<DomainException>()));
    });

    test('should throw exception for empty string', () {
      expect(() => PassId.fromString(''), throwsA(isA<DomainException>()));
    });
  });
}
