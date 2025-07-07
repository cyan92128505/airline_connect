import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemberTier Enum Tests', () {
    test('should create from valid string values', () {
      expect(MemberTier.fromString('BRONZE'), equals(MemberTier.bronze));
      expect(MemberTier.fromString('SILVER'), equals(MemberTier.silver));
      expect(MemberTier.fromString('GOLD'), equals(MemberTier.gold));
      expect(MemberTier.fromString('SUSPENDED'), equals(MemberTier.suspended));
    });

    test('should handle case insensitive input', () {
      expect(MemberTier.fromString('bronze'), equals(MemberTier.bronze));
      expect(MemberTier.fromString('Gold'), equals(MemberTier.gold));
    });

    test('should throw exception for invalid tier', () {
      expect(
        () => MemberTier.fromString('INVALID'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should return correct display names', () {
      expect(MemberTier.bronze.displayName, equals('銅級會員'));
      expect(MemberTier.silver.displayName, equals('銀級會員'));
      expect(MemberTier.gold.displayName, equals('金級會員'));
      expect(MemberTier.suspended.displayName, equals('暫停會員'));
    });

    test('should check privilege correctly', () {
      // Act & Assert
      expect(MemberTier.bronze.hasPrivilege, isTrue);
      expect(MemberTier.silver.hasPrivilege, isTrue);
      expect(MemberTier.gold.hasPrivilege, isTrue);
      expect(MemberTier.suspended.hasPrivilege, isFalse);
    });

    test('should return correct priority order', () {
      expect(MemberTier.suspended.priority, equals(0));
      expect(MemberTier.bronze.priority, equals(1));
      expect(MemberTier.silver.priority, equals(2));
      expect(MemberTier.gold.priority, equals(3));
    });
  });
}
