import 'package:app/core/exceptions/domain_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/boarding_pass/infrastructure/services/crypto_service_impl.dart';

void main() {
  late CryptoServiceImpl cryptoService;

  setUp(() {
    cryptoService = CryptoServiceImpl();
  });

  group('CryptoService', () {
    group('generateKey', () {
      test('should generate 256-bit key', () {
        final key = cryptoService.generateKey();

        expect(key, isNotEmpty);
        expect(key.length, greaterThan(40)); // Base64URL encoded 256-bit key
      });

      test('should generate different keys each time', () {
        final key1 = cryptoService.generateKey();
        final key2 = cryptoService.generateKey();

        expect(key1, isNot(equals(key2)));
      });
    });

    group('encrypt/decrypt', () {
      test('should encrypt and decrypt correctly', () {
        const plaintext = 'test message';
        final key = cryptoService.generateKey();

        final encrypted = cryptoService.encrypt(plaintext, key);
        final decrypted = cryptoService.decrypt(encrypted, key);

        expect(decrypted, equals(plaintext));
      });

      test('should produce different ciphertexts for same plaintext', () {
        const plaintext = 'test message';
        final key = cryptoService.generateKey();

        final encrypted1 = cryptoService.encrypt(plaintext, key);
        final encrypted2 = cryptoService.encrypt(plaintext, key);

        expect(encrypted1, isNot(equals(encrypted2)));
      });

      test('should throw on invalid key', () {
        const plaintext = 'test message';
        const invalidKey = 'invalid-key';

        expect(
          () => cryptoService.encrypt(plaintext, invalidKey),
          throwsA(isA<DomainException>()),
        );
      });
    });

    group('signature', () {
      test('should generate and verify signature correctly', () {
        const data = 'test data';
        const secret = 'test secret';

        final signature = cryptoService.generateSignature(data, secret);
        final isValid = cryptoService.verifySignature(data, signature, secret);

        expect(isValid, isTrue);
      });

      test('should reject tampered data', () {
        const data = 'test data';
        const tamperedData = 'tampered data';
        const secret = 'test secret';

        final signature = cryptoService.generateSignature(data, secret);
        final isValid = cryptoService.verifySignature(
          tamperedData,
          signature,
          secret,
        );

        expect(isValid, isFalse);
      });

      test('should reject wrong secret', () {
        const data = 'test data';
        const secret = 'test secret';
        const wrongSecret = 'wrong secret';

        final signature = cryptoService.generateSignature(data, secret);
        final isValid = cryptoService.verifySignature(
          data,
          signature,
          wrongSecret,
        );

        expect(isValid, isFalse);
      });
    });
  });
}
