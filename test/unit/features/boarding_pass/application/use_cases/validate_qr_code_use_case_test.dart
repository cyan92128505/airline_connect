import 'package:app/features/boarding_pass/domain/services/crypto_service.dart';
import 'package:app/features/boarding_pass/infrastructure/services/Crypto_service_impl.dart';
import 'package:app/features/boarding_pass/infrastructure/services/qr_code_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/boarding_pass/application/use_cases/validate_qr_code_use_case.dart';
import 'package:app/features/boarding_pass/domain/services/qr_code_service.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../../helpers/test_timezone_helper.dart';
import 'validate_qr_code_use_case_test.mocks.dart';

@GenerateNiceMocks([MockSpec<QRCodeService>()])
@GenerateMocks([QRCodeConfig])
void main() {
  group('ValidateQRCodeUseCase', () {
    late ValidateQRCodeUseCase useCase;
    late MockQRCodeService mockQRCodeService;
    late MockQRCodeConfig mockConfig;
    late QRCodePayload mockPayload;

    setUpAll(() {
      TestTimezoneHelper.setupForTesting();
    });

    setUp(() {
      mockQRCodeService = MockQRCodeService();
      useCase = ValidateQRCodeUseCase(mockQRCodeService);
      mockConfig = MockQRCodeConfig();
      when(mockConfig.validityDuration).thenReturn(const Duration(hours: 2));
      when(mockConfig.currentVersion).thenReturn(1);
      when(mockConfig.issuer).thenReturn('airline-connect');
      when(mockConfig.encryptionKey).thenReturn('test-key');
      when(mockConfig.signingSecret).thenReturn('test-secret');

      final cryptoService = CryptoServiceImpl();
      // Setup default mock payload
      final departureTime = tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(hours: 2));
      final generatedAt = tz.TZDateTime.now(
        tz.local,
      ).subtract(const Duration(minutes: 30));

      final nonce = cryptoService.generateNonce();

      mockPayload = QRCodePayload(
        passId: 'BP12345678',
        flightNumber: 'BR857',
        seatNumber: '12A',
        memberNumber: 'MB100001',
        departureTime: departureTime,
        generatedAt: generatedAt,
        nonce: nonce,
        issuer: mockConfig.issuer,
      );
    });

    test('should validate QR code successfully without scan summary', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        encryptedPayload: 'encrypted_payload_data',
        checksum: 'checksum_value',
        generatedAt: tz.TZDateTime.now(
          tz.local,
        ).subtract(const Duration(minutes: 30)).toIso8601String(),
        version: 1,
      );

      when(
        mockQRCodeService.validate(any),
      ).thenAnswer((_) async => Right(mockPayload));

      when(
        mockQRCodeService.generateScanSummary(any),
      ).thenAnswer((_) => Left(ValidationFailure('Summary generation failed')));

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isTrue);
        expect(response.passId, equals('BP12345678'));
        expect(response.flightNumber, equals('BR857'));
        expect(response.seatNumber, equals('12A'));
        expect(response.memberNumber, equals('MB100001'));
        expect(response.departureTime, isNotNull);
        expect(response.payloadData, isNull); // No scan summary
        expect(response.errorMessage, isNull);
      });

      verify(mockQRCodeService.validate(any)).called(1);
      verify(mockQRCodeService.generateScanSummary(any)).called(1);
    });

    test('should validate QR code successfully with scan summary', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        encryptedPayload: 'encrypted_payload_data',
        checksum: 'checksum_value',
        generatedAt: TZDateTime.now(
          local,
        ).subtract(const Duration(minutes: 30)).toIso8601String(),
        version: 1,
      );

      final mockScanSummary = {
        'scanTime': DateTime.now().toIso8601String(),
        'validationStatus': 'valid',
        'additionalInfo': 'QR code scanned successfully',
      };

      when(
        mockQRCodeService.validateAndDecodeQRCode(any),
      ).thenAnswer((_) async => Right(mockPayload));

      when(
        mockQRCodeService.generateScanSummary(any),
      ).thenAnswer((_) => Right(mockScanSummary));

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isTrue);
        expect(response.passId, equals('BP12345678'));
        expect(response.flightNumber, equals('BR857'));
        expect(response.seatNumber, equals('12A'));
        expect(response.memberNumber, equals('MB100001'));
        expect(response.departureTime, isNotNull);
        expect(response.payloadData, equals(mockScanSummary));
        expect(response.errorMessage, isNull);
      });
    });

    test(
      'should return invalid response when QR code validation fails',
      () async {
        // Arrange
        final validationRequest = QRCodeValidationDTO(
          encryptedPayload: 'invalid_encrypted_payload',
          checksum: 'invalid_checksum',
          generatedAt: TZDateTime.now(
            local,
          ).subtract(const Duration(hours: 24)).toIso8601String(),
          version: 1,
        );

        when(mockQRCodeService.validateAndDecodeQRCode(any)).thenAnswer(
          (_) async => Left(ValidationFailure('QR code has expired')),
        );

        // Act
        final result = await useCase(validationRequest);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Should not return failure'), (response) {
          expect(response.isValid, isFalse);
          expect(response.passId, isNull);
          expect(response.flightNumber, isNull);
          expect(response.seatNumber, isNull);
          expect(response.memberNumber, isNull);
          expect(response.departureTime, isNull);
          expect(response.payloadData, isNull);
          expect(response.errorMessage, equals('QR code has expired'));
        });

        verify(mockQRCodeService.validateAndDecodeQRCode(any)).called(1);
        verifyNever(mockQRCodeService.generateScanSummary(any));
      },
    );

    test('should handle invalid checksum error', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        encryptedPayload: 'valid_payload',
        checksum: 'invalid_checksum',
        generatedAt: TZDateTime.now(
          local,
        ).subtract(const Duration(minutes: 5)).toIso8601String(),
        version: 1,
      );

      when(
        mockQRCodeService.validateAndDecodeQRCode(any),
      ).thenAnswer((_) async => Left(ValidationFailure('Invalid checksum')));

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isFalse);
        expect(response.errorMessage, equals('Invalid checksum'));
      });
    });

    test('should handle expired QR code error', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        encryptedPayload: 'valid_payload',
        checksum: 'valid_checksum',
        generatedAt: TZDateTime.now(
          local,
        ).subtract(const Duration(days: 1)).toIso8601String(),
        version: 1,
      );

      when(
        mockQRCodeService.validateAndDecodeQRCode(any),
      ).thenAnswer((_) async => Left(ValidationFailure('QR code has expired')));

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isFalse);
        expect(response.errorMessage, equals('QR code has expired'));
      });
    });

    test('should handle malformed payload error', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        encryptedPayload: 'malformed_payload',
        checksum: 'valid_checksum',
        generatedAt: TZDateTime.now(
          local,
        ).subtract(const Duration(minutes: 5)).toIso8601String(),
        version: 1,
      );

      when(mockQRCodeService.validateAndDecodeQRCode(any)).thenAnswer(
        (_) async => Left(ValidationFailure('Malformed payload data')),
      );

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isFalse);
        expect(response.errorMessage, equals('Malformed payload data'));
      });
    });

    test('should handle domain exception', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        encryptedPayload: 'valid_payload',
        checksum: 'valid_checksum',
        generatedAt: TZDateTime.now(
          local,
        ).subtract(const Duration(minutes: 5)).toIso8601String(),
        version: 1,
      );

      when(
        mockQRCodeService.validateAndDecodeQRCode(any),
      ).thenThrow(DomainException('Invalid QR code format'));

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isFalse);
        expect(response.errorMessage, equals('Invalid QR code format'));
      });
    });

    test('should handle unexpected exception', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        encryptedPayload: 'valid_payload',
        checksum: 'valid_checksum',
        generatedAt: TZDateTime.now(
          local,
        ).subtract(const Duration(minutes: 5)).toIso8601String(),
        version: 1,
      );

      when(
        mockQRCodeService.validateAndDecodeQRCode(any),
      ).thenThrow(Exception('Unexpected error'));

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<UnknownFailure>());
        expect(failure.message, contains('Failed to validate QR code'));
      }, (response) => fail('Should not return success'));
    });

    test('should handle network failure from service', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        encryptedPayload: 'valid_payload',
        checksum: 'valid_checksum',
        generatedAt: TZDateTime.now(
          local,
        ).subtract(const Duration(minutes: 5)).toIso8601String(),
        version: 1,
      );

      when(mockQRCodeService.validateAndDecodeQRCode(any)).thenAnswer(
        (_) async => Left(NetworkFailure('Network connection failed')),
      );

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isFalse);
        expect(response.errorMessage, equals('Network connection failed'));
      });
    });

    test('should handle database failure from service', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        encryptedPayload: 'valid_payload',
        checksum: 'valid_checksum',
        generatedAt: TZDateTime.now(
          local,
        ).subtract(const Duration(minutes: 5)).toIso8601String(),
        version: 1,
      );

      when(
        mockQRCodeService.validateAndDecodeQRCode(any),
      ).thenAnswer((_) async => Left(DatabaseFailure('Database query failed')));

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isFalse);
        expect(response.errorMessage, equals('Database query failed'));
      });
    });

    test('should correctly reconstruct QR code data from DTO', () async {
      // Arrange
      final now = TZDateTime.now(local).subtract(const Duration(minutes: 5));
      final validationRequest = QRCodeValidationDTO(
        encryptedPayload: 'test_encrypted_payload',
        checksum: 'test_checksum',
        generatedAt: now.toIso8601String(),
        version: 2,
      );

      when(
        mockQRCodeService.validateAndDecodeQRCode(any),
      ).thenAnswer((_) async => Right(mockPayload));

      when(
        mockQRCodeService.generateScanSummary(any),
      ).thenAnswer((_) => Right({'status': 'valid'}));

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isRight(), isTrue);

      // Verify that QRCodeData was constructed correctly
      verify(
        mockQRCodeService.validateAndDecodeQRCode(
          argThat(
            predicate<QRCodeData>(
              (qrCodeData) =>
                  qrCodeData.encryptedPayload == 'test_encrypted_payload' &&
                  qrCodeData.checksum == 'test_checksum' &&
                  qrCodeData.version == 2,
            ),
          ),
        ),
      ).called(1);
    });

    test('should handle invalid date format in generatedAt', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        encryptedPayload: 'valid_payload',
        checksum: 'valid_checksum',
        generatedAt: 'invalid_date_format',
        version: 1,
      );

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<UnknownFailure>());
        expect(failure.message, contains('Failed to validate QR code'));
        expect(failure.message, contains('FormatException'));
      }, (response) => fail('Should not return success'));
    });

    test('should include all payload data in successful response', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        encryptedPayload: 'valid_payload',
        checksum: 'valid_checksum',
        generatedAt: TZDateTime.now(
          local,
        ).subtract(const Duration(minutes: 5)).toIso8601String(),
        version: 1,
      );

      when(
        mockQRCodeService.validateAndDecodeQRCode(any),
      ).thenAnswer((_) async => Right(mockPayload));

      when(mockQRCodeService.generateScanSummary(any)).thenAnswer(
        (_) => Right({
          'scanTime': DateTime.now().toIso8601String(),
          'validationStatus': 'valid',
          'gate': 'A12',
          'terminal': 'Terminal 1',
        }),
      );

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isTrue);
        expect(response.passId, equals('BP12345678'));
        expect(response.flightNumber, equals('BR857'));
        expect(response.seatNumber, equals('12A'));
        expect(response.memberNumber, equals('MB100001'));
        expect(response.departureTime, isNotNull);
        expect(response.payloadData, isNotNull);
        expect(response.payloadData?['scanTime'], isNotNull);
        expect(response.payloadData?['validationStatus'], equals('valid'));
        expect(response.payloadData?['gate'], equals('A12'));
        expect(response.payloadData?['terminal'], equals('Terminal 1'));
      });
    });

    test('should handle different QR code versions', () async {
      // Arrange
      final validationRequestV2 = QRCodeValidationDTO(
        encryptedPayload: 'v2_payload',
        checksum: 'v2_checksum',
        generatedAt: TZDateTime.now(
          local,
        ).subtract(const Duration(minutes: 5)).toIso8601String(),
        version: 2,
      );

      when(
        mockQRCodeService.validateAndDecodeQRCode(any),
      ).thenAnswer((_) async => Right(mockPayload));

      when(mockQRCodeService.generateScanSummary(any)).thenAnswer(
        (_) => Right({
          'version': '2.1',
          'features': ['enhanced_security'],
        }),
      );

      // Act
      final result = await useCase(validationRequestV2);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isTrue);
        expect(response.payloadData?['version'], equals('2.1'));
        expect(response.payloadData?['features'], isNotNull);
      });
    });

    test(
      'should handle QR code validation with null optional fields',
      () async {
        // Arrange
        final validationRequest = QRCodeValidationDTO(
          encryptedPayload: 'valid_payload',
          checksum: 'valid_checksum',
          generatedAt: TZDateTime.now(
            local,
          ).subtract(const Duration(minutes: 5)).toIso8601String(),
          version: 1,
        );

        when(
          mockQRCodeService.validateAndDecodeQRCode(any),
        ).thenAnswer((_) async => Right(mockPayload));

        // Simulate scan summary generation failure (optional feature)
        when(mockQRCodeService.generateScanSummary(any)).thenAnswer(
          (_) => Left(ValidationFailure('Scan summary not available')),
        );

        // Act
        final result = await useCase(validationRequest);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Should not return failure'), (response) {
          expect(response.isValid, isTrue);
          expect(response.passId, equals('BP12345678'));
          expect(
            response.payloadData,
            isNull,
          ); // Should be null when scan summary fails
        });
      },
    );

    test(
      'should verify QRCodeData construction with correct timezone parsing',
      () async {
        // Arrange
        final specificTime = TZDateTime(local, 2024, 12, 25, 14, 30, 0);
        final validationRequest = QRCodeValidationDTO(
          encryptedPayload: 'payload_with_specific_time',
          checksum: 'time_checksum',
          generatedAt: specificTime.toIso8601String(),
          version: 1,
        );

        when(
          mockQRCodeService.validateAndDecodeQRCode(any),
        ).thenAnswer((_) async => Right(mockPayload));

        when(
          mockQRCodeService.generateScanSummary(any),
        ).thenAnswer((_) => Right({}));

        // Act
        final result = await useCase(validationRequest);

        // Assert
        expect(result.isRight(), isTrue);

        // Verify QRCodeData was constructed with correct timestamp
        verify(
          mockQRCodeService.validateAndDecodeQRCode(
            argThat(
              predicate<QRCodeData>(
                (qrCodeData) =>
                    qrCodeData.generatedAt.year == 2024 &&
                    qrCodeData.generatedAt.month == 12 &&
                    qrCodeData.generatedAt.day == 25 &&
                    qrCodeData.generatedAt.hour == 14 &&
                    qrCodeData.generatedAt.minute == 30,
              ),
            ),
          ),
        ).called(1);
      },
    );

    test('should handle QR code service returning null payload', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        encryptedPayload: 'payload_returning_null',
        checksum: 'null_checksum',
        generatedAt: TZDateTime.now(
          local,
        ).subtract(const Duration(minutes: 5)).toIso8601String(),
        version: 1,
      );

      when(mockQRCodeService.validateAndDecodeQRCode(any)).thenAnswer(
        (_) async =>
            Left(ValidationFailure('Failed to decrypt QR code payload')),
      );

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isFalse);
        expect(
          response.errorMessage,
          equals('Failed to decrypt QR code payload'),
        );
      });

      verifyNever(mockQRCodeService.generateScanSummary(any));
    });

    test('should handle empty scan summary gracefully', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        encryptedPayload: 'valid_payload',
        checksum: 'valid_checksum',
        generatedAt: TZDateTime.now(
          local,
        ).subtract(const Duration(minutes: 5)).toIso8601String(),
        version: 1,
      );

      when(
        mockQRCodeService.validateAndDecodeQRCode(any),
      ).thenAnswer((_) async => Right(mockPayload));

      when(mockQRCodeService.generateScanSummary(any)).thenAnswer(
        (_) => Right(<String, dynamic>{}), // Empty map
      );

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isTrue);
        expect(response.payloadData, isNotNull);
        expect(response.payloadData, isEmpty);
      });
    });
  });
}
