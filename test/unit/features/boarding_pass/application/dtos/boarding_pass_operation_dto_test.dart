import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';

void main() {
  group('CreateBoardingPassDTO', () {
    test('should create CreateBoardingPassDTO with valid data', () {
      // Arrange & Act
      final dto = CreateBoardingPassDTO(
        memberNumber: 'M1001',
        flightNumber: 'BR857',
        seatNumber: '12A',
      );

      // Assert
      expect(dto.memberNumber, equals('M1001'));
      expect(dto.flightNumber, equals('BR857'));
      expect(dto.seatNumber, equals('12A'));
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final dto = CreateBoardingPassDTO(
        memberNumber: 'M1001',
        flightNumber: 'BR857',
        seatNumber: '12A',
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['memberNumber'], equals('M1001'));
      expect(json['flightNumber'], equals('BR857'));
      expect(json['seatNumber'], equals('12A'));
    });
  });

  group('BoardingPassOperationResponseDTO', () {
    final sampleBoardingPass = BoardingPassDTO(
      passId: 'BP123456789',
      memberNumber: 'M1001',
      flightNumber: 'BR857',
      seatNumber: '12A',
      scheduleSnapshot: FlightScheduleSnapshotDTO(
        departureTime: '2025-07-17T10:30:00Z',
        boardingTime: '2025-07-17T10:00:00Z',
        departure: 'TPE',
        arrival: 'NRT',
        gate: 'A12',
        snapshotTime: '2025-07-17T08:00:00Z',
      ),
      status: PassStatus.activated,
      qrCode: QRCodeDataDTO(
        token: 'encrypted_token_123',
        signature: 'signature_abc',
        generatedAt: '2025-07-17T09:00:00Z',
        version: 1,
        isValid: true,
      ),
      issueTime: '2025-07-17T08:30:00Z',
    );

    test('should create success response correctly', () {
      // Act
      final response = BoardingPassOperationResponseDTO.success(
        boardingPass: sampleBoardingPass,
        metadata: {'operation': 'create'},
      );

      // Assert
      expect(response.success, isTrue);
      expect(response.boardingPass, equals(sampleBoardingPass));
      expect(response.errorMessage, isNull);
      expect(response.metadata?['operation'], equals('create'));
    });

    test('should create error response correctly', () {
      // Act
      final response = BoardingPassOperationResponseDTO.error(
        errorMessage: 'Flight not found',
        errorCode: 'FLIGHT_NOT_FOUND',
        metadata: {'requestId': '12345'},
      );

      // Assert
      expect(response.success, isFalse);
      expect(response.boardingPass, isNull);
      expect(response.errorMessage, equals('Flight not found'));
      expect(response.errorCode, equals('FLIGHT_NOT_FOUND'));
      expect(response.metadata?['requestId'], equals('12345'));
    });
  });

  group('UpdateSeatDTO', () {
    test('should create UpdateSeatDTO with valid data', () {
      // Arrange & Act
      final dto = UpdateSeatDTO(passId: 'BP123456789', newSeatNumber: '15B');

      // Assert
      expect(dto.passId, equals('BP123456789'));
      expect(dto.newSeatNumber, equals('15B'));
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final dto = UpdateSeatDTO(passId: 'BP123456789', newSeatNumber: '15B');

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['passId'], equals('BP123456789'));
      expect(json['newSeatNumber'], equals('15B'));
    });
  });

  group('QRCodeValidationDTO', () {
    test('should create QRCodeValidationDTO with valid data', () {
      // Arrange & Act
      final dto = QRCodeValidationDTO(
        qrCodeString: '1.MTY4OTU4ODAwMDAwMA.encrypted_token_123.signature_abc',
      );

      // Assert
      expect(
        dto.qrCodeString,
        equals('1.MTY4OTU4ODAwMDAwMA.encrypted_token_123.signature_abc'),
      );
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'qrCodeString':
            '1.MTY4OTU4ODAwMDAwMA.encrypted_token_123.signature_abc',
      };

      // Act
      final dto = QRCodeValidationDTO.fromJson(json);

      // Assert
      expect(
        dto.qrCodeString,
        equals('1.MTY4OTU4ODAwMDAwMA.encrypted_token_123.signature_abc'),
      );
    });
  });

  group('QRCodeValidationResponseDTO', () {
    test('should create valid QR code response correctly', () {
      // Act
      final response = QRCodeValidationResponseDTO.valid(
        passId: 'BP123456789',
        flightNumber: 'BR857',
        seatNumber: '12A',
        memberNumber: 'M1001',
        departureTime: '2025-07-17T10:30:00Z',
        metadata: {'gate': 'A12'},
      );

      // Assert
      expect(response.isValid, isTrue);
      expect(response.passId, equals('BP123456789'));
      expect(response.flightNumber, equals('BR857'));
      expect(response.seatNumber, equals('12A'));
      expect(response.errorMessage, isNull);
      expect(response.metadata?['gate'], equals('A12'));
    });

    test('should create invalid QR code response correctly', () {
      // Act
      final response = QRCodeValidationResponseDTO.invalid(
        errorMessage: 'QR code expired',
        errorCode: 'QR_EXPIRED',
      );

      // Assert
      expect(response.isValid, isFalse);
      expect(response.passId, isNull);
      expect(response.flightNumber, isNull);
      expect(response.seatNumber, isNull);
      expect(response.errorMessage, equals('QR code expired'));
      expect(response.errorCode, equals('QR_EXPIRED'));
    });
  });

  group('QRCodePayloadDTO', () {
    test('should create QRCodePayloadDTO with valid data', () {
      // Arrange & Act
      final dto = QRCodePayloadDTO(
        passId: 'BP123456789',
        flightNumber: 'BR857',
        seatNumber: '12A',
        memberNumber: 'M1001',
        departureTime: '2025-07-17T10:30:00Z',
        generatedAt: '2025-07-17T09:00:00Z',
        nonce: 'random_nonce_123',
        issuer: 'airline-connect',
        isExpired: false,
        timeRemainingMinutes: 90,
      );

      // Assert
      expect(dto.passId, equals('BP123456789'));
      expect(dto.flightNumber, equals('BR857'));
      expect(dto.seatNumber, equals('12A'));
      expect(dto.memberNumber, equals('M1001'));
      expect(dto.issuer, equals('airline-connect'));
      expect(dto.isExpired, isFalse);
      expect(dto.timeRemainingMinutes, equals(90));
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final dto = QRCodePayloadDTO(
        passId: 'BP123456789',
        flightNumber: 'BR857',
        seatNumber: '12A',
        memberNumber: 'M1001',
        departureTime: '2025-07-17T10:30:00Z',
        generatedAt: '2025-07-17T09:00:00Z',
        nonce: 'random_nonce_123',
        issuer: 'airline-connect',
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['passId'], equals('BP123456789'));
      expect(json['flightNumber'], equals('BR857'));
      expect(json['seatNumber'], equals('12A'));
      expect(json['memberNumber'], equals('M1001'));
      expect(json['issuer'], equals('airline-connect'));
    });
  });

  group('BoardingPassSearchDTO', () {
    test('should create BoardingPassSearchDTO with filters', () {
      // Arrange & Act
      final dto = BoardingPassSearchDTO(
        memberNumber: 'M1001',
        flightNumber: 'BR857',
        status: PassStatus.activated,
        activeOnly: true,
        departureDate: '2025-07-17',
        limit: 10,
        offset: 0,
      );

      // Assert
      expect(dto.memberNumber, equals('M1001'));
      expect(dto.flightNumber, equals('BR857'));
      expect(dto.status, equals(PassStatus.activated));
      expect(dto.activeOnly, isTrue);
      expect(dto.limit, equals(10));
    });

    test('should create activeForMember search correctly', () {
      // Act
      final dto = BoardingPassSearchDTO.activeForMember('M1001');

      // Assert
      expect(dto.memberNumber, equals('M1001'));
      expect(dto.activeOnly, isTrue);
    });

    test('should create memberByStatus search correctly', () {
      // Act
      final dto = BoardingPassSearchDTO.memberByStatus(
        memberNumber: 'M1001',
        status: PassStatus.used,
      );

      // Assert
      expect(dto.memberNumber, equals('M1001'));
      expect(dto.status, equals(PassStatus.used));
    });

    test('should create todayForMember search correctly', () {
      // Act
      final dto = BoardingPassSearchDTO.todayForMember('M1001');

      // Assert
      expect(dto.memberNumber, equals('M1001'));
      expect(dto.departureDate, isNotNull);
      // Should contain today's date in YYYY-MM-DD format
      expect(dto.departureDate, matches(r'^\d{4}-\d{2}-\d{2}$'));
    });
  });

  group('BoardingEligibilityResponseDTO', () {
    test('should create eligible response correctly', () {
      // Act
      final response = BoardingEligibilityResponseDTO.eligible(
        passId: 'BP123456789',
        timeUntilDepartureMinutes: 90,
        isInBoardingWindow: true,
        additionalInfo: {'gate': 'A12'},
      );

      // Assert
      expect(response.isEligible, isTrue);
      expect(response.passId, equals('BP123456789'));
      expect(response.timeUntilDepartureMinutes, equals(90));
      expect(response.isInBoardingWindow, isTrue);
      expect(response.isQRCodeValid, isTrue);
      expect(response.reason, isNull);
    });

    test('should create ineligible response correctly', () {
      // Act
      final response = BoardingEligibilityResponseDTO.ineligible(
        passId: 'BP123456789',
        reason: 'Not in boarding window',
        currentStatus: PassStatus.expired,
        isQRCodeValid: false,
      );

      // Assert
      expect(response.isEligible, isFalse);
      expect(response.passId, equals('BP123456789'));
      expect(response.reason, equals('Not in boarding window'));
      expect(response.currentStatus, equals(PassStatus.expired));
      expect(response.isQRCodeValid, isFalse);
    });
  });

  group('QRCodeScanResultDTO', () {
    final sampleBoardingPass = BoardingPassDTO(
      passId: 'BP123456789',
      memberNumber: 'M1001',
      flightNumber: 'BR857',
      seatNumber: '12A',
      scheduleSnapshot: FlightScheduleSnapshotDTO(
        departureTime: '2025-07-17T10:30:00Z',
        boardingTime: '2025-07-17T10:00:00Z',
        departure: 'TPE',
        arrival: 'NRT',
        gate: 'A12',
        snapshotTime: '2025-07-17T08:00:00Z',
      ),
      status: PassStatus.activated,
      qrCode: QRCodeDataDTO(
        token: 'encrypted_token_123',
        signature: 'signature_abc',
        generatedAt: '2025-07-17T09:00:00Z',
        version: 1,
        isValid: true,
      ),
      issueTime: '2025-07-17T08:30:00Z',
    );

    final samplePayload = QRCodePayloadDTO(
      passId: 'BP123456789',
      flightNumber: 'BR857',
      seatNumber: '12A',
      memberNumber: 'M1001',
      departureTime: '2025-07-17T10:30:00Z',
      generatedAt: '2025-07-17T09:00:00Z',
      nonce: 'random_nonce_123',
      issuer: 'airline-connect',
    );

    test('should create valid scan result correctly', () {
      // Act
      final result = QRCodeScanResultDTO.valid(
        boardingPass: sampleBoardingPass,
        payload: samplePayload,
        timeRemainingMinutes: 90,
        summary: {'status': 'valid'},
      );

      // Assert
      expect(result.isValid, isTrue);
      expect(result.boardingPass, equals(sampleBoardingPass));
      expect(result.payload, equals(samplePayload));
      expect(result.timeRemainingMinutes, equals(90));
      expect(result.reason, isNull);
    });

    test('should create invalid scan result correctly', () {
      // Act
      final result = QRCodeScanResultDTO.invalid('QR code expired');

      // Assert
      expect(result.isValid, isFalse);
      expect(result.reason, equals('QR code expired'));
      expect(result.boardingPass, isNull);
      expect(result.payload, isNull);
    });
  });

  group('GateBoardingRequestDTO', () {
    test('should create GateBoardingRequestDTO with valid data', () {
      // Arrange & Act
      final dto = GateBoardingRequestDTO(
        qrCodeString: '1.MTY4OTU4ODAwMDAwMA.encrypted_token_123.signature_abc',
        gateCode: 'A12',
        operatorId: 'OP001',
        metadata: {'terminal': 'T1'},
      );

      // Assert
      expect(
        dto.qrCodeString,
        equals('1.MTY4OTU4ODAwMDAwMA.encrypted_token_123.signature_abc'),
      );
      expect(dto.gateCode, equals('A12'));
      expect(dto.operatorId, equals('OP001'));
      expect(dto.metadata?['terminal'], equals('T1'));
    });
  });

  group('GateBoardingResponseDTO', () {
    final sampleBoardingPass = BoardingPassDTO(
      passId: 'BP123456789',
      memberNumber: 'M1001',
      flightNumber: 'BR857',
      seatNumber: '12A',
      scheduleSnapshot: FlightScheduleSnapshotDTO(
        departureTime: '2025-07-17T10:30:00Z',
        boardingTime: '2025-07-17T10:00:00Z',
        departure: 'TPE',
        arrival: 'NRT',
        gate: 'A12',
        snapshotTime: '2025-07-17T08:00:00Z',
      ),
      status: PassStatus.activated,
      qrCode: QRCodeDataDTO(
        token: 'encrypted_token_123',
        signature: 'signature_abc',
        generatedAt: '2025-07-17T09:00:00Z',
        version: 1,
        isValid: true,
      ),
      issueTime: '2025-07-17T08:30:00Z',
    );

    test('should create approved response correctly', () {
      // Act
      final response = GateBoardingResponseDTO.approved(
        boardingPass: sampleBoardingPass,
        gateCode: 'A12',
        operatorId: 'OP001',
        metadata: {'terminal': 'T1'},
      );

      // Assert
      expect(response.isApproved, isTrue);
      expect(response.reason, equals('Boarding approved'));
      expect(response.boardingPass, equals(sampleBoardingPass));
      expect(response.gateCode, equals('A12'));
      expect(response.operatorId, equals('OP001'));
      expect(response.validatedAt, isNotNull);
      expect(response.metadata?['terminal'], equals('T1'));
    });

    test('should create rejected response correctly', () {
      // Act
      final response = GateBoardingResponseDTO.rejected(
        reason: 'QR code expired',
        gateCode: 'A12',
        operatorId: 'OP001',
        metadata: {'errorCode': 'QR_EXPIRED'},
      );

      // Assert
      expect(response.isApproved, isFalse);
      expect(response.reason, equals('QR code expired'));
      expect(response.boardingPass, isNull);
      expect(response.gateCode, equals('A12'));
      expect(response.operatorId, equals('OP001'));
      expect(response.validatedAt, isNotNull);
      expect(response.metadata?['errorCode'], equals('QR_EXPIRED'));
    });
  });
}
