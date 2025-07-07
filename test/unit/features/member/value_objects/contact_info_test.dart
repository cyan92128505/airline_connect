import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/member/domain/value_objects/contact_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContactInfo Value Object Tests', () {
    test('should create valid contact info', () {
      final contactInfo = ContactInfo.create(
        email: 'test@example.com',
        phone: '+886912345678',
      );

      expect(contactInfo.email, equals('test@example.com'));
      expect(contactInfo.phone, equals('+886912345678'));
    });

    test('should normalize email to lowercase', () {
      final contactInfo = ContactInfo.create(
        email: 'TEST@EXAMPLE.COM',
        phone: '+886912345678',
      );

      expect(contactInfo.email, equals('test@example.com'));
    });

    test('should update contact information', () {
      final contactInfo = ContactInfo.create(
        email: 'old@example.com',
        phone: '+886912345678',
      );

      final updatedInfo = contactInfo.update(email: 'new@example.com');

      expect(updatedInfo.email, equals('new@example.com'));
      expect(updatedInfo.phone, equals('+886912345678'));
    });

    test('should throw exception for invalid email', () {
      expect(
        () =>
            ContactInfo.create(email: 'invalid-email', phone: '+886912345678'),
        throwsA(isA<DomainException>()),
      );
    });

    test('should throw exception for invalid phone', () {
      expect(
        () => ContactInfo.create(
          email: 'test@example.com',
          phone: 'invalid-phone',
        ),
        throwsA(isA<DomainException>()),
      );
    });

    test('should throw exception for empty email', () {
      expect(
        () => ContactInfo.create(email: '', phone: '+886912345678'),
        throwsA(isA<DomainException>()),
      );
    });

    test('should throw exception for empty phone', () {
      expect(
        () => ContactInfo.create(email: 'test@example.com', phone: ''),
        throwsA(isA<DomainException>()),
      );
    });
  });
}
