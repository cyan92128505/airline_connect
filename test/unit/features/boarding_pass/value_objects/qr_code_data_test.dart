import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:app/features/boarding_pass/value_objects/qr_code_data.dart';
import 'package:app/features/boarding_pass/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/value_objects/seat_number.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('QRCodeData Value Object Tests', () {
    test('should generate valid QR code data', () {
      final passId = PassId.generate();
      final flightNumber = FlightNumber.create('BR857');
      final seatNumber = SeatNumber.create('12A');
      final memberNumber = MemberNumber.create('AA123456');
      final departureTime = TZDateTime.now(local).add(const Duration(hours: 2));

      final qrCode = QRCodeData.generate(
        passId: passId,
        flightNumber: flightNumber,
        seatNumber: seatNumber,
        memberNumber: memberNumber,
        departureTime: departureTime,
      );

      expect(qrCode.encryptedPayload, isNotEmpty);
      expect(qrCode.checksum, isNotEmpty);
      expect(qrCode.generatedAt, isNotNull);
      expect(qrCode.version, equals(1));
    });

    test('should decrypt payload correctly', () {
      final passId = PassId.generate();
      final flightNumber = FlightNumber.create('BR857');
      final seatNumber = SeatNumber.create('12A');
      final memberNumber = MemberNumber.create('AA123456');
      final departureTime = TZDateTime.now(local).add(const Duration(hours: 2));

      final qrCode = QRCodeData.generate(
        passId: passId,
        flightNumber: flightNumber,
        seatNumber: seatNumber,
        memberNumber: memberNumber,
        departureTime: departureTime,
      );

      final payload = qrCode.decryptPayload();

      expect(payload, isNotNull);
      expect(payload!.passId, equals(passId.value));
      expect(payload.flightNumber, equals(flightNumber.value));
      expect(payload.seatNumber, equals(seatNumber.value));
      expect(payload.memberNumber, equals(memberNumber.value));
    });

    test('should validate QR code correctly when fresh', () {
      final passId = PassId.generate();
      final flightNumber = FlightNumber.create('BR857');
      final seatNumber = SeatNumber.create('12A');
      final memberNumber = MemberNumber.create('AA123456');
      final departureTime = TZDateTime.now(local).add(const Duration(hours: 2));

      final qrCode = QRCodeData.generate(
        passId: passId,
        flightNumber: flightNumber,
        seatNumber: seatNumber,
        memberNumber: memberNumber,
        departureTime: departureTime,
      );

      expect(qrCode.isValid, isTrue);
      expect(qrCode.timeRemaining, isNotNull);
    });

    test('should return false for expired QR code', () {
      final oldGeneratedAt = TZDateTime.now(
        local,
      ).subtract(const Duration(hours: 3));
      final qrCode = QRCodeData(
        encryptedPayload: 'test',
        checksum: 'test',
        generatedAt: oldGeneratedAt,
        version: 1,
      );

      expect(qrCode.isValid, isFalse);
      expect(qrCode.timeRemaining, isNull);
    });
  });
}
