import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';

void main() {
  group('BoardingPassDTO', () {
    final validBoardingPassDTO = BoardingPassDTO(
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
        routeDescription: 'Taipei to Tokyo Narita',
        formattedDepartureTime: '10:30',
        formattedBoardingTime: '10:00',
        isInBoardingWindow: true,
        hasDeparted: false,
      ),
      status: PassStatus.activated,
      qrCode: QRCodeDataDTO(
        encryptedPayload: 'encrypted_data_123',
        checksum: 'checksum_abc',
        generatedAt: '2025-07-17T09:00:00Z',
        version: 1,
        isValid: true,
        timeRemainingMinutes: 30,
      ),
      issueTime: '2025-07-17T08:30:00Z',
      activatedAt: '2025-07-17T09:00:00Z',
      usedAt: null,
      isValidForBoarding: true,
      isActive: true,
      timeUntilDepartureMinutes: 90,
    );

    test('should create BoardingPassDTO with valid data', () {
      // Act & Assert
      expect(validBoardingPassDTO.passId, equals('BP123456789'));
      expect(validBoardingPassDTO.memberNumber, equals('M1001'));
      expect(validBoardingPassDTO.flightNumber, equals('BR857'));
      expect(validBoardingPassDTO.status, equals(PassStatus.activated));
      expect(validBoardingPassDTO.isValidForBoarding, isTrue);
    });

    test('should serialize to JSON correctly', () {
      // Act
      final json = validBoardingPassDTO.toJson();

      // Assert
      expect(json['passId'], equals('BP123456789'));
      expect(json['memberNumber'], equals('M1001'));
      expect(json['flightNumber'], equals('BR857'));
      expect(json['status'], equals('activated'));
    });
  });

  group('FlightScheduleSnapshotDTO', () {
    test('should create FlightScheduleSnapshotDTO with valid data', () {
      // Arrange & Act
      final snapshot = FlightScheduleSnapshotDTO(
        departureTime: '2025-07-17T10:30:00Z',
        boardingTime: '2025-07-17T10:00:00Z',
        departure: 'TPE',
        arrival: 'NRT',
        gate: 'A12',
        snapshotTime: '2025-07-17T08:00:00Z',
      );

      // Assert
      expect(snapshot.departure, equals('TPE'));
      expect(snapshot.arrival, equals('NRT'));
      expect(snapshot.gate, equals('A12'));
    });

    test('should handle optional fields correctly', () {
      // Arrange & Act
      final snapshot = FlightScheduleSnapshotDTO(
        departureTime: '2025-07-17T10:30:00Z',
        boardingTime: '2025-07-17T10:00:00Z',
        departure: 'TPE',
        arrival: 'NRT',
        gate: 'A12',
        snapshotTime: '2025-07-17T08:00:00Z',
        isInBoardingWindow: true,
        hasDeparted: false,
      );

      // Assert
      expect(snapshot.isInBoardingWindow, isTrue);
      expect(snapshot.hasDeparted, isFalse);
    });
  });

  group('QRCodeDataDTO', () {
    test('should create QRCodeDataDTO with valid data', () {
      // Arrange & Act
      final qrCode = QRCodeDataDTO(
        encryptedPayload: 'encrypted_data_123',
        checksum: 'checksum_abc',
        generatedAt: '2025-07-17T09:00:00Z',
        version: 1,
        isValid: true,
      );

      // Assert
      expect(qrCode.encryptedPayload, equals('encrypted_data_123'));
      expect(qrCode.checksum, equals('checksum_abc'));
      expect(qrCode.version, equals(1));
      expect(qrCode.isValid, isTrue);
    });

    test('should handle time remaining minutes correctly', () {
      // Arrange & Act
      final qrCode = QRCodeDataDTO(
        encryptedPayload: 'encrypted_data_123',
        checksum: 'checksum_abc',
        generatedAt: '2025-07-17T09:00:00Z',
        version: 1,
        isValid: true,
        timeRemainingMinutes: 45,
      );

      // Assert
      expect(qrCode.timeRemainingMinutes, equals(45));
    });
  });

  group('BoardingPassDTOExtensions', () {
    test('should validate DTO with valid data', () {
      // Arrange
      final validDTO = BoardingPassDTO(
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

      // Act
      final isValid = validDTO.isValid();

      // Assert
      expect(isValid, isTrue);
    });

    test('should return false for invalid DTO data', () {
      // Arrange - Invalid date format
      final invalidDTO = BoardingPassDTO(
        passId: '',
        memberNumber: 'M1001',
        flightNumber: 'BR857',
        seatNumber: '12A',
        scheduleSnapshot: FlightScheduleSnapshotDTO(
          departureTime: 'invalid-date',
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

      // Act
      final isValid = invalidDTO.isValid();

      // Assert
      expect(isValid, isFalse);
    });
  });
}
