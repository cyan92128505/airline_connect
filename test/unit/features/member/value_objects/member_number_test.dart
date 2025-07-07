import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemberNumber Value Object Tests', () {
    test('should create valid member number', () {
      final memberNumber = MemberNumber.create('AA123456');

      expect(memberNumber.value, equals('AA123456'));
      expect(memberNumber.airlineCode, equals('AA'));
      expect(memberNumber.memberSequence, equals('123456'));
    });

    test('should convert to uppercase', () {
      final memberNumber = MemberNumber.create('aa123456');

      expect(memberNumber.value, equals('AA123456'));
    });

    test('should throw exception for invalid format', () {
      expect(
        () => MemberNumber.create('INVALID'),
        throwsA(isA<DomainException>()),
      );
    });

    test('should throw exception for wrong length', () {
      expect(
        () => MemberNumber.create('AA12345'),
        throwsA(isA<DomainException>()),
      );
    });

    test('should throw exception for empty string', () {
      expect(() => MemberNumber.create(''), throwsA(isA<DomainException>()));
    });
  });
}
