import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/domain/value_objects/seat_number.dart';
import 'package:app/features/boarding_pass/domain/value_objects/flight_schedule_snapshot.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:app/core/exceptions/domain_exception.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('BoardingPass Entity Tests', () {
    late FlightScheduleSnapshot testSnapshot;

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
    });

    test('should create valid boarding pass with correct data', () {
      final boardingPass = BoardingPass.create(
        memberNumber: MemberNumber.create('AA123456'),
        flightNumber: FlightNumber.create('BR857'),
        seatNumber: SeatNumber.create('12A'),
        scheduleSnapshot: testSnapshot,
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
      );

      expect(() => boardingPass.activate(), throwsA(isA<DomainException>()));
    });

    test('should use boarding pass successfully when activated', () {
      final now = TZDateTime.now(local);
      final boardingTime = now.subtract(const Duration(minutes: 30));
      final departureTime = now.add(const Duration(minutes: 30));

      final snapshot = FlightScheduleSnapshot.create(
        departureTime: departureTime,
        boardingTime: boardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
        snapshotTime: now.subtract(const Duration(hours: 1)),
      );

      final boardingPass = BoardingPass.create(
        memberNumber: MemberNumber.create('AA123456'),
        flightNumber: FlightNumber.create('BR857'),
        seatNumber: SeatNumber.create('12A'),
        scheduleSnapshot: snapshot,
      ).activate();

      final usedPass = boardingPass.use();

      expect(usedPass.status, equals(PassStatus.used));
      expect(usedPass.usedAt, isNotNull);
    });

    test('should throw exception when using non-activated pass', () {
      final boardingPass = BoardingPass.create(
        memberNumber: MemberNumber.create('AA123456'),
        flightNumber: FlightNumber.create('BR857'),
        seatNumber: SeatNumber.create('12A'),
        scheduleSnapshot: testSnapshot,
      );

      expect(() => boardingPass.use(), throwsA(isA<DomainException>()));
    });

    test('should update seat number successfully', () {
      final boardingPass = BoardingPass.create(
        memberNumber: MemberNumber.create('AA123456'),
        flightNumber: FlightNumber.create('BR857'),
        seatNumber: SeatNumber.create('12A'),
        scheduleSnapshot: testSnapshot,
      );

      final updatedPass = boardingPass.updateSeat(SeatNumber.create('15B'));

      expect(updatedPass.seatNumber.value, equals('15B'));
    });

    test('should cancel boarding pass successfully', () {
      final boardingPass = BoardingPass.create(
        memberNumber: MemberNumber.create('AA123456'),
        flightNumber: FlightNumber.create('BR857'),
        seatNumber: SeatNumber.create('12A'),
        scheduleSnapshot: testSnapshot,
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
      );

      final cancelledPass = activePass.cancel();

      expect(activePass.isActive, isTrue);
      expect(cancelledPass.isActive, isFalse);
    });
  });
}
