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
        encryptedPayload: 'encrypted_data_123',
        checksum: 'checksum_abc',
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
        encryptedPayload: 'encrypted_data_123',
        checksum: 'checksum_abc',
        generatedAt: '2025-07-17T09:00:00Z',
        version: 1,
      );

      // Assert
      expect(dto.encryptedPayload, equals('encrypted_data_123'));
      expect(dto.checksum, equals('checksum_abc'));
      expect(dto.version, equals(1));
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'encryptedPayload': 'encrypted_data_123',
        'checksum': 'checksum_abc',
        'generatedAt': '2025-07-17T09:00:00Z',
        'version': 1,
      };

      // Act
      final dto = QRCodeValidationDTO.fromJson(json);

      // Assert
      expect(dto.encryptedPayload, equals('encrypted_data_123'));
      expect(dto.checksum, equals('checksum_abc'));
      expect(dto.version, equals(1));
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
        payloadData: {'gate': 'A12'},
      );

      // Assert
      expect(response.isValid, isTrue);
      expect(response.passId, equals('BP123456789'));
      expect(response.flightNumber, equals('BR857'));
      expect(response.seatNumber, equals('12A'));
      expect(response.errorMessage, isNull);
      expect(response.payloadData?['gate'], equals('A12'));
    });

    test('should create invalid QR code response correctly', () {
      // Act
      final response = QRCodeValidationResponseDTO.invalid(
        errorMessage: 'QR code expired',
      );

      // Assert
      expect(response.isValid, isFalse);
      expect(response.passId, isNull);
      expect(response.flightNumber, isNull);
      expect(response.seatNumber, isNull);
      expect(response.errorMessage, equals('QR code expired'));
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
}
