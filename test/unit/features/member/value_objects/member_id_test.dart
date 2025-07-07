import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/member/domain/value_objects/member_id.dart';
import 'package:app/core/exceptions/domain_exception.dart';

void main() {
  group('MemberId Value Object Tests', () {
    test('should generate valid UUID', () {
      final memberId = MemberId.generate();

      expect(memberId.value, isNotEmpty);
      expect(memberId.value.length, equals(36));
      expect(memberId.value, contains('-'));
    });

    test('should create from valid UUID string', () {
      const validUuid = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

      final memberId = MemberId.fromString(validUuid);

      expect(memberId.value, equals(validUuid));
    });

    test('should throw exception for invalid UUID format', () {
      const invalidUuid = 'invalid-uuid';

      expect(
        () => MemberId.fromString(invalidUuid),
        throwsA(isA<DomainException>()),
      );
    });

    test('should throw exception for empty string', () {
      expect(() => MemberId.fromString(''), throwsA(isA<DomainException>()));
    });
  });
}
