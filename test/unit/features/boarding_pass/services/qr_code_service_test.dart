import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:app/features/boarding_pass/services/qr_code_service.dart';
import 'package:app/features/boarding_pass/repositories/boarding_pass_repository.dart';
import 'package:app/features/boarding_pass/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/value_objects/qr_code_data.dart';
import 'package:app/features/boarding_pass/value_objects/seat_number.dart';
import 'package:app/features/boarding_pass/value_objects/flight_schedule_snapshot.dart';
import 'package:app/features/member/value_objects/member_number.dart';
import 'package:app/features/flight/value_objects/flight_number.dart';
import 'package:app/core/failures/failure.dart';

import 'qr_code_service_test.mocks.dart';

@GenerateMocks([BoardingPassRepository])
void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('QRCodeService Tests', () {
    late QRCodeService service;
    late MockBoardingPassRepository mockRepository;

    setUp(() {
      mockRepository = MockBoardingPassRepository();
      service = QRCodeService(mockRepository);
    });

    test('should validate and decode QR code successfully', () async {
      final memberNumber = MemberNumber.create('AA123456');
      final flightNumber = FlightNumber.create('BR857');
      final seatNumber = SeatNumber.create('12A');
      final departureTime = TZDateTime.now(local).add(const Duration(hours: 2));

      final snapshot = FlightScheduleSnapshot.create(
        departureTime: departureTime,
        boardingTime: departureTime.subtract(const Duration(hours: 1)),
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
        snapshotTime: TZDateTime.now(local),
      );

      final boardingPass = BoardingPass.create(
        memberNumber: memberNumber,
        flightNumber: flightNumber,
        seatNumber: seatNumber,
        scheduleSnapshot: snapshot,
      );

      when(
        mockRepository.findByPassId(any),
      ).thenAnswer((_) async => Right(boardingPass));

      final result = await service.validateAndDecodeQRCode(boardingPass.qrCode);

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (payload) {
        expect(payload.passId, equals(boardingPass.passId.value));
        expect(payload.flightNumber, equals(flightNumber.value));
        expect(payload.seatNumber, equals(seatNumber.value));
        expect(payload.memberNumber, equals(memberNumber.value));
      });
    });

    test('should fail validation for invalid QR code', () async {
      final qrCode = QRCodeData(
        encryptedPayload: 'invalid_payload',
        checksum: 'invalid_checksum',
        generatedAt: TZDateTime.now(local),
        version: 1,
      );

      final result = await service.validateAndDecodeQRCode(qrCode);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (payload) => fail('Should fail'),
      );
    });

    test('should fail validation for non-existent boarding pass', () async {
      final memberNumber = MemberNumber.create('AA123456');
      final flightNumber = FlightNumber.create('BR857');
      final seatNumber = SeatNumber.create('12A');
      final departureTime = TZDateTime.now(local).add(const Duration(hours: 2));

      final snapshot = FlightScheduleSnapshot.create(
        departureTime: departureTime,
        boardingTime: departureTime.subtract(const Duration(hours: 1)),
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
        snapshotTime: TZDateTime.now(local),
      );

      final boardingPass = BoardingPass.create(
        memberNumber: memberNumber,
        flightNumber: flightNumber,
        seatNumber: seatNumber,
        scheduleSnapshot: snapshot,
      );

      when(
        mockRepository.findByPassId(any),
      ).thenAnswer((_) async => const Right(null));

      final result = await service.validateAndDecodeQRCode(boardingPass.qrCode);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (payload) => fail('Should fail'),
      );
    });

    test('should fail validation for expired QR code', () async {
      final oldGeneratedAt = TZDateTime.now(
        local,
      ).subtract(const Duration(hours: 3));
      final qrCode = QRCodeData(
        encryptedPayload: 'test_payload',
        checksum: 'test_checksum',
        generatedAt: oldGeneratedAt,
        version: 1,
      );

      final result = await service.validateAndDecodeQRCode(qrCode);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (payload) => fail('Should fail'),
      );
    });

    test('should get QR code time remaining successfully', () {
      final qrCode = QRCodeData(
        encryptedPayload: 'test_payload',
        checksum: 'test_checksum',
        generatedAt: TZDateTime.now(local),
        version: 1,
      );

      final result = service.getQRCodeTimeRemaining(qrCode);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not fail'),
        (timeRemaining) => expect(timeRemaining, isNotNull),
      );
    });

    test('should return null for expired QR code time remaining', () {
      final expiredGeneratedAt = TZDateTime.now(
        local,
      ).subtract(const Duration(hours: 3));
      final expiredQrCode = QRCodeData(
        encryptedPayload: 'test_payload',
        checksum: 'test_checksum',
        generatedAt: expiredGeneratedAt,
        version: 1,
      );

      final result = service.getQRCodeTimeRemaining(expiredQrCode);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not fail'),
        (timeRemaining) => expect(timeRemaining, isNull),
      );
    });

    test('should generate scan summary successfully', () {
      final payload = QRPayload(
        passId: 'BP12345678',
        flightNumber: 'BR857',
        seatNumber: '12A',
        memberNumber: 'AA123456',
        departureTime: TZDateTime.now(local).add(const Duration(hours: 2)),
        generatedAt: TZDateTime.now(local),
      );

      final result = service.generateScanSummary(payload);

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (summary) {
        expect(summary['passId'], equals('BP12345678'));
        expect(summary['flightNumber'], equals('BR857'));
        expect(summary['seatNumber'], equals('12A'));
        expect(summary['memberNumber'], equals('AA123456'));
        expect(summary['isValid'], equals(true));
        expect(summary['departureTime'], isNotNull);
        expect(summary['generatedAt'], isNotNull);
      });
    });

    test('should handle repository failure during validation', () async {
      final memberNumber = MemberNumber.create('AA123456');
      final flightNumber = FlightNumber.create('BR857');
      final seatNumber = SeatNumber.create('12A');
      final departureTime = TZDateTime.now(local).add(const Duration(hours: 2));

      final snapshot = FlightScheduleSnapshot.create(
        departureTime: departureTime,
        boardingTime: departureTime.subtract(const Duration(hours: 1)),
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
        snapshotTime: TZDateTime.now(local),
      );

      final boardingPass = BoardingPass.create(
        memberNumber: memberNumber,
        flightNumber: flightNumber,
        seatNumber: seatNumber,
        scheduleSnapshot: snapshot,
      );

      when(
        mockRepository.findByPassId(any),
      ).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

      final result = await service.validateAndDecodeQRCode(boardingPass.qrCode);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (payload) => fail('Should fail'),
      );
    });

    test('should fail validation when QR code data mismatch', () async {
      final memberNumber = MemberNumber.create('AA123456');
      final flightNumber = FlightNumber.create('BR857');
      final seatNumber = SeatNumber.create('12A');
      final departureTime = TZDateTime.now(local).add(const Duration(hours: 2));

      final snapshot = FlightScheduleSnapshot.create(
        departureTime: departureTime,
        boardingTime: departureTime.subtract(const Duration(hours: 1)),
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
        snapshotTime: TZDateTime.now(local),
      );

      final boardingPass = BoardingPass.create(
        memberNumber: memberNumber,
        flightNumber: flightNumber,
        seatNumber: seatNumber,
        scheduleSnapshot: snapshot,
      );

      final mismatchedBoardingPass = BoardingPass.create(
        memberNumber: MemberNumber.create(
          'BB999999',
        ), // Different member number
        flightNumber: FlightNumber.create('CI101'), // Different flight number
        seatNumber: SeatNumber.create('15B'), // Different seat
        scheduleSnapshot: snapshot,
      );

      when(
        mockRepository.findByPassId(any),
      ).thenAnswer((_) async => Right(mismatchedBoardingPass));

      final result = await service.validateAndDecodeQRCode(boardingPass.qrCode);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (payload) => fail('Should fail'),
      );
    });
  });
}
