import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/domain/value_objects/seat_number.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';

import '../../../../helpers/test_timezone_helper.dart';

void main() {
  setUpAll(() {
    TestTimezoneHelper.setupForTesting();
  });

  group('QRCodeData Value Object Tests', () {
    test('should generate valid QR code data', () {
      final passId = PassId.generate();
      final flightNumber = FlightNumber.create('BR857');
      final seatNumber = SeatNumber.create('12A');
      final memberNumber = MemberNumber.create('AA123456');
      final departureTime = TimezoneTestDataFactory.createTaipeiTime(
        2025,
        7,
        15,
        14,
        30,
      );

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
      final departureTime = TimezoneTestDataFactory.createTaipeiTime(
        2025,
        7,
        15,
        14,
        30,
      );

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

    group('Cross-timezone QR Code Tests', () {
      test('should decrypt QR code generated in different timezone', () {
        final passId = PassId.generate();
        final flightNumber = FlightNumber.create('BR857');
        final seatNumber = SeatNumber.create('12A');
        final memberNumber = MemberNumber.create('AA123456');
        final departureTime = TimezoneTestDataFactory.createTokyoTime(
          2025,
          7,
          15,
          14,
          30,
        );

        // Generate QR code in Taipei timezone
        TestTimezoneHelper.setupForTesting('Asia/Taipei');
        final qrCode = QRCodeData.generate(
          passId: passId,
          flightNumber: flightNumber,
          seatNumber: seatNumber,
          memberNumber: memberNumber,
          departureTime: departureTime,
        );

        // Switch to Tokyo timezone and try to decrypt
        TestTimezoneHelper.setupForTesting('Asia/Tokyo');
        final payload = qrCode.decryptPayload();

        expect(payload, isNotNull);
        expect(payload!.passId, equals(passId.value));

        // Reset to default timezone for other tests
        TestTimezoneHelper.setupForTesting();
      });

      test('should validate QR code consistently across timezones', () {
        final times = TimezoneTestDataFactory.createBoardingWindowTimes();
        final qrCode = QRCodeData.generate(
          passId: PassId.generate(),
          flightNumber: FlightNumber.create('BR857'),
          seatNumber: SeatNumber.create('12A'),
          memberNumber: MemberNumber.create('AA123456'),
          departureTime: times['departureTime']!,
        );

        // Should be valid in Taipei timezone
        TestTimezoneHelper.setupForTesting('Asia/Taipei');
        final validInTaipei = qrCode.isValid;

        // Should be valid in UTC timezone
        TestTimezoneHelper.setupForUtcTesting();
        final validInUtc = qrCode.isValid;

        // Should be consistent regardless of validation timezone
        expect(validInTaipei, equals(validInUtc));

        // Reset to default
        TestTimezoneHelper.setupForTesting();
      });
    });

    group('DST Transition Tests', () {
      test('should handle QR code validation during DST transition', () {
        // Test during US DST "spring forward"
        TestTimezoneHelper.setupForTesting('America/Los_Angeles');

        // Create QR code just before DST transition (2:00 AM becomes 3:00 AM)
        final dstTransitionTime = TimezoneTestDataFactory.createLosAngelesTime(
          2025,
          3,
          9,
          1,
          30, // 1:30 AM on DST transition day
        );

        final qrCode = QRCodeData.generate(
          passId: PassId.generate(),
          flightNumber: FlightNumber.create('UA123'),
          seatNumber: SeatNumber.create('12A'),
          memberNumber: MemberNumber.create('AA123456'),
          departureTime: dstTransitionTime.add(Duration(hours: 4)),
        );

        expect(qrCode.isValid, isTrue);

        // Reset to default
        TestTimezoneHelper.setupForTesting();
      });
    });
  });
}
