import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/boarding_pass/enums/pass_status.dart';

void main() {
  group('PassStatus Enum Tests', () {
    test('should create from valid string values', () {
      expect(PassStatus.fromString('ISSUED'), equals(PassStatus.issued));
      expect(PassStatus.fromString('ACTIVATED'), equals(PassStatus.activated));
      expect(PassStatus.fromString('USED'), equals(PassStatus.used));
      expect(PassStatus.fromString('EXPIRED'), equals(PassStatus.expired));
      expect(PassStatus.fromString('CANCELLED'), equals(PassStatus.cancelled));
    });

    test('should handle case insensitive input', () {
      expect(PassStatus.fromString('issued'), equals(PassStatus.issued));
      expect(PassStatus.fromString('Activated'), equals(PassStatus.activated));
    });

    test('should throw exception for invalid status', () {
      expect(
        () => PassStatus.fromString('INVALID'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should return correct display names', () {
      expect(PassStatus.issued.displayName, equals('已發行'));
      expect(PassStatus.activated.displayName, equals('已啟用'));
      expect(PassStatus.used.displayName, equals('已使用'));
      expect(PassStatus.expired.displayName, equals('已過期'));
      expect(PassStatus.cancelled.displayName, equals('已取消'));
    });

    test('should check if status is active', () {
      expect(PassStatus.issued.isActive, isTrue);
      expect(PassStatus.activated.isActive, isTrue);
      expect(PassStatus.used.isActive, isFalse);
      expect(PassStatus.expired.isActive, isFalse);
      expect(PassStatus.cancelled.isActive, isFalse);
    });

    test('should check if status is terminal', () {
      expect(PassStatus.used.isTerminal, isTrue);
      expect(PassStatus.expired.isTerminal, isTrue);
      expect(PassStatus.cancelled.isTerminal, isTrue);
      expect(PassStatus.issued.isTerminal, isFalse);
      expect(PassStatus.activated.isTerminal, isFalse);
    });

    test('should check if allows boarding', () {
      expect(PassStatus.activated.allowsBoarding, isTrue);
      expect(PassStatus.issued.allowsBoarding, isFalse);
      expect(PassStatus.used.allowsBoarding, isFalse);
      expect(PassStatus.cancelled.allowsBoarding, isFalse);
    });

    test('should return correct priority order', () {
      expect(PassStatus.activated.priority, equals(5));
      expect(PassStatus.issued.priority, equals(4));
      expect(PassStatus.used.priority, equals(3));
      expect(PassStatus.expired.priority, equals(2));
      expect(PassStatus.cancelled.priority, equals(1));
    });
  });
}
