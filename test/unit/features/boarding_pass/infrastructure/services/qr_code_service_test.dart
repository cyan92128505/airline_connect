import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/domain/services/crypto_service.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:app/features/boarding_pass/infrastructure/services/qr_code_service_impl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../../helpers/test_timezone_helper.dart';
import 'qr_code_service_test.mocks.dart';

@GenerateMocks([CryptoService, QRCodeConfig])
void main() {
  late QRCodeServiceImpl qrCodeService;
  late MockCryptoService mockCryptoService;
  late MockQRCodeConfig mockConfig;

  setUpAll(() {
    TestTimezoneHelper.setupForTesting();
  });

  setUp(() {
    mockCryptoService = MockCryptoService();
    mockConfig = MockQRCodeConfig();
    qrCodeService = QRCodeServiceImpl(mockCryptoService, mockConfig);

    // Setup default mocks
    when(mockConfig.validityDuration).thenReturn(const Duration(hours: 2));
    when(mockConfig.currentVersion).thenReturn(1);
    when(mockConfig.issuer).thenReturn('airline-connect');
    when(mockConfig.encryptionKey).thenReturn('test-key');
    when(mockConfig.signingSecret).thenReturn('test-secret');
  });

  group('QRCodeService', () {
    group('generate', () {
      test('should generate valid QR code', () {
        // Arrange
        final passId = PassId.generate();
        when(mockCryptoService.generateNonce()).thenReturn('test-nonce');
        when(
          mockCryptoService.encrypt(any, any, metadata: anyNamed('metadata')),
        ).thenReturn('encrypted-token');
        when(
          mockCryptoService.generateSignature(any, any),
        ).thenReturn('test-signature');

        // Act
        final result = qrCodeService.generate(
          passId: passId,
          flightNumber: 'AA123',
          seatNumber: '12A',
          memberNumber: 'M123',
          departureTime: tz.TZDateTime.now(
            tz.local,
          ).add(const Duration(hours: 4)),
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(mockCryptoService.generateNonce()).called(1);
        verify(
          mockCryptoService.encrypt(any, any, metadata: anyNamed('metadata')),
        ).called(1);
        verify(mockCryptoService.generateSignature(any, any)).called(1);
      });

      test('should handle encryption failure gracefully', () {
        // Arrange
        final passId = PassId.generate();
        when(mockCryptoService.generateNonce()).thenReturn('test-nonce');
        when(
          mockCryptoService.encrypt(any, any, metadata: anyNamed('metadata')),
        ).thenThrow(DomainException('Encryption failed'));

        // Act
        final result = qrCodeService.generate(
          passId: passId,
          flightNumber: 'AA123',
          seatNumber: '12A',
          memberNumber: 'M123',
          departureTime: tz.TZDateTime.now(
            tz.local,
          ).add(const Duration(hours: 4)),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Expected left'),
        );
      });
    });

    group('validate', () {
      test('should validate correct QR code', () {
        // Arrange
        final qrCode = QRCodeData.create(
          token: 'valid-token',
          signature: 'valid-signature',
          generatedAt: tz.TZDateTime.now(tz.local),
        );

        when(mockCryptoService.verifySignature(any, any, any)).thenReturn(true);
        when(
          mockCryptoService.decrypt(any, any, metadata: anyNamed('metadata')),
        ).thenReturn(
          '{"iss":"airline-connect","sub":"test-pass-id","iat":${tz.TZDateTime.now(tz.local).millisecondsSinceEpoch},"exp":${tz.TZDateTime.now(tz.local).add(const Duration(hours: 24)).millisecondsSinceEpoch},"flt":"AA123","seat":"12A","mbr":"M123","dep":${tz.TZDateTime.now(tz.local).add(const Duration(hours: 4)).millisecondsSinceEpoch},"nonce":"test-nonce-12345","ver":1}',
        );

        // Act
        final result = qrCodeService.validate(qrCode);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected right'), (validationResult) {
          expect(validationResult.isValid, isTrue);
          expect(validationResult.payload, isNotNull);
        });
      });

      test('should reject QR code with invalid signature', () {
        // Arrange
        final qrCode = QRCodeData.create(
          token: 'valid-token',
          signature: 'invalid-signature',
          generatedAt: tz.TZDateTime.now(tz.local),
        );

        when(
          mockCryptoService.verifySignature(any, any, any),
        ).thenReturn(false);

        // Act
        final result = qrCodeService.validate(qrCode);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected right'), (validationResult) {
          expect(validationResult.isValid, isFalse);
          expect(validationResult.reason, equals('Invalid signature'));
        });
      });

      test('should reject expired QR code', () {
        // Arrange
        final expiredTime = tz.TZDateTime.now(
          tz.local,
        ).subtract(const Duration(hours: 3));
        final qrCode = QRCodeData.create(
          token: 'valid-token',
          signature: 'valid-signature',
          generatedAt: expiredTime,
        );

        when(mockCryptoService.verifySignature(any, any, any)).thenReturn(true);

        // Act
        final result = qrCodeService.validate(qrCode);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected right'), (validationResult) {
          expect(validationResult.isValid, isFalse);
          expect(validationResult.reason, equals('QR code has expired'));
        });
      });
    });

    group('business rules validation', () {
      test('should reject QR code with wrong issuer', () {
        // Test implementation for wrong issuer
      });

      test('should reject QR code generated in future', () {
        // Test implementation for future timestamp
      });

      test('should reject QR code with invalid nonce', () {
        // Test implementation for invalid nonce
      });
    });
  });
}
