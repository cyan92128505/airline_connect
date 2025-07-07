import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/member/domain/value_objects/full_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FullName Value Object Tests', () {
    test('should create valid full name', () {
      final fullName = FullName.create('王小明');

      expect(fullName.value, equals('王小明'));
      expect(fullName.nameSuffix, equals('王小明'));
    });

    test('should trim whitespace', () {
      final fullName = FullName.create('  王小明  ');

      expect(fullName.value, equals('王小明'));
    });

    test('should get name suffix correctly', () {
      final fullName = FullName.create('王小明abcd');

      final suffix = fullName.nameSuffix;

      expect(suffix, equals('abcd'));
    });

    test('should handle short names for suffix', () {
      final fullName = FullName.create('王明');

      final suffix = fullName.nameSuffix;

      expect(suffix, equals('王明'));
    });

    test('should throw exception for empty name', () {
      expect(() => FullName.create(''), throwsA(isA<DomainException>()));
    });

    test('should throw exception for too short name', () {
      expect(() => FullName.create('A'), throwsA(isA<DomainException>()));
    });

    test('should throw exception for too long name', () {
      final longName = 'A' * 51;

      expect(() => FullName.create(longName), throwsA(isA<DomainException>()));
    });
  });
}
