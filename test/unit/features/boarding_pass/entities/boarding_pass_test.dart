import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/domain/value_objects/seat_number.dart';
import 'package:app/features/boarding_pass/domain/value_objects/flight_schedule_snapshot.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:app/core/exceptions/domain_exception.dart';

import '../../../../helpers/test_timezone_helper.dart';

void main() {
  setUpAll(() {
    TestTimezoneHelper.setupForTesting();
  });

  group('BoardingPass Entity Tests', () {
    late FlightScheduleSnapshot testSnapshot;
    late QRCodeData testQrCode;

    setUp(() {
      final now = TZDateTime.now(local);
      final boardingTime = now.add(const Duration(hours: 2));
      final departureTime = boardingTime.add(const Duration(hours: 1));

      testSnapshot = FlightScheduleSnapshot.create(
        departureTime: departureTime,
        boardingTime: boardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
        snapshotTime: now,
      );

      testQrCode = QRCodeData.create(
        token: 'test-token',
        signature: 'test-signature',
        generatedAt: now,
      );
    });

    test('should create valid boarding pass with correct data', () {
      final boardingPass = BoardingPass.create(
        memberNumber: MemberNumber.create('AA123456'),
        flightNumber: FlightNumber.create('BR857'),
        seatNumber: SeatNumber.create('12A'),
        scheduleSnapshot: testSnapshot,
        qrCode: testQrCode,
      );

      expect(boardingPass.memberNumber.value, equals('AA123456'));
      expect(boardingPass.flightNumber.value, equals('BR857'));
      expect(boardingPass.seatNumber.value, equals('12A'));
      expect(boardingPass.status, equals(PassStatus.issued));
      expect(boardingPass.issueTime, isNotNull);
      expect(boardingPass.activatedAt, isNull);
      expect(boardingPass.usedAt, isNull);
      expect(boardingPass.qrCode, isNotNull);
    });

    test('should activate boarding pass successfully within valid window', () {
      final now = TZDateTime.now(local);
      final departureTime = now.add(const Duration(hours: 2));
      final boardingTime = departureTime.subtract(const Duration(hours: 1));

      final snapshot = FlightScheduleSnapshot.create(
        departureTime: departureTime,
        boardingTime: boardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
        snapshotTime: now,
      );

      final boardingPass = BoardingPass.create(
        memberNumber: MemberNumber.create('AA123456'),
        flightNumber: FlightNumber.create('BR857'),
        seatNumber: SeatNumber.create('12A'),
        scheduleSnapshot: snapshot,
        qrCode: testQrCode,
      );

      final activatedPass = boardingPass.activate();

      expect(activatedPass.status, equals(PassStatus.activated));
      expect(activatedPass.activatedAt, isNotNull);
    });

    test('should throw exception when activating outside valid window', () {
      final now = TZDateTime.now(local);
      final departureTime = now.add(
        const Duration(hours: 48),
      ); // More than 24 hours
      final boardingTime = departureTime.subtract(const Duration(hours: 1));

      final snapshot = FlightScheduleSnapshot.create(
        departureTime: departureTime,
        boardingTime: boardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
        snapshotTime: now,
      );

      final boardingPass = BoardingPass.create(
        memberNumber: MemberNumber.create('AA123456'),
        flightNumber: FlightNumber.create('BR857'),
        seatNumber: SeatNumber.create('12A'),
        scheduleSnapshot: snapshot,
        qrCode: testQrCode,
      );

      expect(() => boardingPass.activate(), throwsA(isA<DomainException>()));
    });

    test('should cancel boarding pass successfully', () {
      final boardingPass = BoardingPass.create(
        memberNumber: MemberNumber.create('AA123456'),
        flightNumber: FlightNumber.create('BR857'),
        seatNumber: SeatNumber.create('12A'),
        scheduleSnapshot: testSnapshot,
        qrCode: testQrCode,
      );

      final cancelledPass = boardingPass.cancel();

      expect(cancelledPass.status, equals(PassStatus.cancelled));
    });

    test('should check if boarding pass is active', () {
      final activePass = BoardingPass.create(
        memberNumber: MemberNumber.create('AA123456'),
        flightNumber: FlightNumber.create('BR857'),
        seatNumber: SeatNumber.create('12A'),
        scheduleSnapshot: testSnapshot,
        qrCode: testQrCode,
      );

      final cancelledPass = activePass.cancel();

      expect(activePass.isActive, isTrue);
      expect(cancelledPass.isActive, isFalse);
    });
  });
}
