import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/application/use_cases/validate_qr_code_use_case.dart';
import 'package:app/features/boarding_pass/domain/services/qr_code_service.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../../helpers/test_timezone_helper.dart';

// Mocktail Mock classes
class MockQRCodeService extends Mock implements QRCodeService {}

void main() {
  group('ValidateQRCodeUseCase', () {
    late ValidateQRCodeUseCase useCase;
    late MockQRCodeService mockQRCodeService;
    late QRCodePayload mockPayload;
    late QRCodeValidationResult mockValidationResult;
    late String validQRString;

    setUpAll(() {
      TestTimezoneHelper.setupForTesting();

      // Register fallback values for Mocktail
      registerFallbackValue(
        QRCodeData.create(
          token: 'fallback_token',
          signature: 'fallback_signature',
          generatedAt: tz.TZDateTime.now(tz.local),
          version: 1,
        ),
      );

      registerFallbackValue(
        QRCodePayload(
          passId: 'fallback',
          flightNumber: 'fallback',
          seatNumber: 'fallback',
          memberNumber: 'fallback',
          departureTime: tz.TZDateTime.now(tz.local),
          generatedAt: tz.TZDateTime.now(tz.local),
          nonce: 'fallback',
          issuer: 'fallback',
        ),
      );
    });

    setUp(() {
      mockQRCodeService = MockQRCodeService();
      useCase = ValidateQRCodeUseCase(mockQRCodeService);

      // Create a valid QR code string for testing
      final testTime = tz.TZDateTime.now(tz.local);
      final testQRCode = QRCodeData.create(
        token:
            'dGVzdF90b2tlbl9kYXRhXzEyMw', // base64url encoded "test_token_data_123"
        signature:
            'dGVzdF9zaWduYXR1cmVfYWJj', // base64url encoded "test_signature_abc"
        generatedAt: testTime,
        version: 1,
      );
      validQRString = testQRCode.toQRString();

      // Setup default mock payload
      final departureTime = tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(hours: 2));
      final generatedAt = tz.TZDateTime.now(
        tz.local,
      ).subtract(const Duration(minutes: 30));

      mockPayload = QRCodePayload(
        passId: 'BP12345678',
        flightNumber: 'BR857',
        seatNumber: '12A',
        memberNumber: 'MB100001',
        departureTime: departureTime,
        generatedAt: generatedAt,
        nonce: 'test_nonce_123',
        issuer: 'airline-connect',
      );

      mockValidationResult = QRCodeValidationResult.valid(
        payload: mockPayload,
        timeRemaining: const Duration(hours: 1, minutes: 30),
      );
    });

    test('should validate QR code successfully with scan summary', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        qrCodeString: validQRString,
      );

      final mockScanSummary = {
        'passId': 'BP12345678',
        'flightNumber': 'BR857',
        'seatNumber': '12A',
        'memberNumber': 'MB100001',
        'departureTime': mockPayload.departureTime.toIso8601String(),
        'generatedAt': mockPayload.generatedAt.toIso8601String(),
        'issuer': 'airline-connect',
        'nonce': 'test_nonce_123',
        'isExpired': false,
        'timeRemaining': 90,
      };

      when(
        () => mockQRCodeService.validate(any()),
      ).thenReturn(Right(mockValidationResult));
      when(
        () => mockQRCodeService.generateScanSummary(any()),
      ).thenReturn(Right(mockScanSummary));

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
        expect(response.payload, isNotNull);
        expect(response.errorMessage, isNull);
      });

      verify(() => mockQRCodeService.validate(any())).called(1);
      verify(() => mockQRCodeService.generateScanSummary(any())).called(1);
    });

    test('should validate QR code successfully without scan summary', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        qrCodeString: validQRString,
      );

      when(
        () => mockQRCodeService.validate(any()),
      ).thenReturn(Right(mockValidationResult));
      when(
        () => mockQRCodeService.generateScanSummary(any()),
      ).thenReturn(Left(ValidationFailure('Summary generation failed')));

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
        expect(response.payload, isNull); // No scan summary
        expect(response.errorMessage, isNull);
      });

      verify(() => mockQRCodeService.validate(any())).called(1);
      verify(() => mockQRCodeService.generateScanSummary(any())).called(1);
    });

    test(
      'should return invalid response when QR code validation fails',
      () async {
        // Arrange - Use valid format but let service return failure
        final validationRequest = QRCodeValidationDTO(
          qrCodeString: validQRString,
        );

        when(
          () => mockQRCodeService.validate(any()),
        ).thenReturn(Left(ValidationFailure('QR code has expired')));

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
          expect(response.payload, isNull);
          expect(response.errorMessage, equals('QR code has expired'));
        });

        verify(() => mockQRCodeService.validate(any())).called(1);
        verifyNever(() => mockQRCodeService.generateScanSummary(any()));
      },
    );

    test('should handle invalid QR code format error', () async {
      // Arrange - Use actually malformed QR string
      final validationRequest = QRCodeValidationDTO(
        qrCodeString: 'malformed_qr_string',
      );

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isFalse);
        // The actual error message from QRCodeData.fromQRString
        expect(response.errorMessage, contains('Invalid QR code format'));
      });

      // Since QR parsing failed, service methods should not be called
      verifyNever(() => mockQRCodeService.validate(any()));
      verifyNever(() => mockQRCodeService.generateScanSummary(any()));
    });

    test('should handle QR code with invalid base64 encoding', () async {
      // Arrange - Invalid base64 in QR string parts
      final validationRequest = QRCodeValidationDTO(
        qrCodeString: '1.invalid=.token.signature',
      );

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isFalse);
        expect(response.errorMessage, contains('Invalid QR code format'));
      });

      verifyNever(() => mockQRCodeService.validate(any()));
      verifyNever(() => mockQRCodeService.generateScanSummary(any()));
    });

    test('should handle QR code with wrong number of parts', () async {
      // Arrange - QR string with wrong number of parts (should be 4)
      final validationRequest = QRCodeValidationDTO(
        qrCodeString: '1.MTY4OTU4ODAwMDAwMA.token', // Missing signature part
      );

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isFalse);
        expect(response.errorMessage, contains('Invalid QR code format'));
      });

      verifyNever(() => mockQRCodeService.validate(any()));
      verifyNever(() => mockQRCodeService.generateScanSummary(any()));
    });

    test('should handle validation result with null payload', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        qrCodeString: validQRString,
      );

      final invalidValidationResult = QRCodeValidationResult.invalid(
        'Payload is null',
      );
      when(
        () => mockQRCodeService.validate(any()),
      ).thenReturn(Right(invalidValidationResult));

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, equals('Failed to validate QR code'));
      }, (response) => fail('Should not return success'));
    });

    test('should handle unexpected exception from service', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        qrCodeString: validQRString,
      );

      when(
        () => mockQRCodeService.validate(any()),
      ).thenThrow(Exception('Unexpected error'));

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<UnknownFailure>());
        expect(failure.message, contains('Failed to validate QR code'));
        expect(failure.message, contains('Unexpected error'));
      }, (response) => fail('Should not return success'));
    });

    test('should handle network failure from service', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        qrCodeString: validQRString,
      );

      when(
        () => mockQRCodeService.validate(any()),
      ).thenReturn(Left(NetworkFailure('Network connection failed')));

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
        qrCodeString: validQRString,
      );

      when(
        () => mockQRCodeService.validate(any()),
      ).thenReturn(Left(DatabaseFailure('Database query failed')));

      // Act
      final result = await useCase(validationRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isFalse);
        expect(response.errorMessage, equals('Database query failed'));
      });
    });

    test(
      'should include complete payload data in successful response',
      () async {
        // Arrange
        final validationRequest = QRCodeValidationDTO(
          qrCodeString: validQRString,
        );

        final detailedScanSummary = {
          'passId': 'BP12345678',
          'flightNumber': 'BR857',
          'seatNumber': '12A',
          'memberNumber': 'MB100001',
          'departureTime': mockPayload.departureTime.toIso8601String(),
          'generatedAt': mockPayload.generatedAt.toIso8601String(),
          'issuer': 'airline-connect',
          'nonce': 'test_nonce_123',
          'isExpired': false,
          'timeRemaining': 90,
        };

        when(
          () => mockQRCodeService.validate(any()),
        ).thenReturn(Right(mockValidationResult));
        when(
          () => mockQRCodeService.generateScanSummary(any()),
        ).thenReturn(Right(detailedScanSummary));

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
          expect(response.payload, isNotNull);
          expect(response.payload?.passId, equals('BP12345678'));
          expect(response.payload?.flightNumber, equals('BR857'));
          expect(response.payload?.issuer, equals('airline-connect'));
          expect(response.payload?.nonce, equals('test_nonce_123'));
        });
      },
    );

    test('should handle empty scan summary gracefully', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        qrCodeString: validQRString,
      );

      when(
        () => mockQRCodeService.validate(any()),
      ).thenReturn(Right(mockValidationResult));
      when(
        () => mockQRCodeService.generateScanSummary(any()),
      ).thenReturn(Right(<String, dynamic>{})); // Empty map

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
        expect(response.payload, isNull);
        expect(response.metadata, isNull);
        expect(response.errorMessage, isNull);
      });
    });

    test('should handle partial scan summary gracefully', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        qrCodeString: validQRString,
      );

      final partialSummary = {
        'scanTime': DateTime.now().toIso8601String(),
        'status': 'scanned',
        // Missing required fields for QRCodePayloadDTO
      };

      when(
        () => mockQRCodeService.validate(any()),
      ).thenReturn(Right(mockValidationResult));
      when(
        () => mockQRCodeService.generateScanSummary(any()),
      ).thenReturn(Right(partialSummary));

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
        // Partial summary should not create payload but should include metadata
        expect(response.payload, isNull);
        expect(response.metadata, isNotNull);
        expect(response.metadata?['scanTime'], isNotNull);
        expect(response.metadata?['status'], equals('scanned'));
        expect(response.errorMessage, isNull);
      });
    });

    test('should create payload from complete scan summary', () async {
      // Arrange
      final validationRequest = QRCodeValidationDTO(
        qrCodeString: validQRString,
      );

      final completeSummary = {
        'passId': 'BP12345678',
        'flightNumber': 'BR857',
        'seatNumber': '12A',
        'memberNumber': 'MB100001',
        'departureTime': mockPayload.departureTime.toIso8601String(),
        'generatedAt': mockPayload.generatedAt.toIso8601String(),
        'nonce': 'test_nonce_123',
        'issuer': 'airline-connect',
        'isExpired': false,
        'timeRemaining': 90,
      };

      when(
        () => mockQRCodeService.validate(any()),
      ).thenReturn(Right(mockValidationResult));
      when(
        () => mockQRCodeService.generateScanSummary(any()),
      ).thenReturn(Right(completeSummary));

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
        // Complete summary should create payload and include metadata
        expect(response.payload, isNotNull);
        expect(response.payload?.passId, equals('BP12345678'));
        expect(response.payload?.flightNumber, equals('BR857'));
        expect(response.payload?.issuer, equals('airline-connect'));
        expect(response.metadata, isNotNull);
        expect(response.errorMessage, isNull);
      });
    });
  });
}
