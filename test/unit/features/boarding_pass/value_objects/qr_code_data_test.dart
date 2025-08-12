import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:app/core/exceptions/domain_exception.dart';
import 'package:timezone/timezone.dart';
import 'dart:convert';

import '../../../../helpers/test_timezone_helper.dart';

void main() {
  setUpAll(() {
    TestTimezoneHelper.setupForTesting();
  });

  group('QRCodePayload - Data Transfer Object Tests', () {
    late QRCodePayload validPayload;
    late TZDateTime testDepartureTime;
    late TZDateTime testGeneratedAt;

    setUp(() {
      testGeneratedAt = TZDateTime.now(local);
      testDepartureTime = testGeneratedAt.add(const Duration(hours: 4));

      validPayload = QRCodePayload(
        passId: 'PASS_12345',
        flightNumber: 'BR857',
        seatNumber: '12A',
        memberNumber: 'AA123456',
        departureTime: testDepartureTime,
        generatedAt: testGeneratedAt,
        nonce: 'random_nonce_123',
        issuer: 'airline.app',
      );
    });

    group('JSON serialization', () {
      test('should convert to JSON correctly', () {
        final json = validPayload.toJson();

        expect(json['iss'], equals('airline.app'));
        expect(json['sub'], equals('PASS_12345'));
        expect(json['iat'], equals(testGeneratedAt.millisecondsSinceEpoch));
        expect(json['flt'], equals('BR857'));
        expect(json['seat'], equals('12A'));
        expect(json['mbr'], equals('AA123456'));
        expect(json['dep'], equals(testDepartureTime.millisecondsSinceEpoch));
        expect(json['nonce'], equals('random_nonce_123'));
        expect(json['ver'], equals(1));
        expect(
          json['exp'],
          equals(
            testGeneratedAt
                .add(const Duration(hours: 24))
                .millisecondsSinceEpoch,
          ),
        );
      });

      test('should handle round-trip JSON conversion', () {
        final jsonString = validPayload.toJsonString();
        final reconstructed = QRCodePayload.fromJsonString(jsonString);

        expect(reconstructed.passId, equals(validPayload.passId));
        expect(reconstructed.flightNumber, equals(validPayload.flightNumber));
        expect(reconstructed.seatNumber, equals(validPayload.seatNumber));
        expect(reconstructed.memberNumber, equals(validPayload.memberNumber));
        expect(reconstructed.nonce, equals(validPayload.nonce));
        expect(reconstructed.issuer, equals(validPayload.issuer));
        expect(
          reconstructed.generatedAt.millisecondsSinceEpoch,
          equals(validPayload.generatedAt.millisecondsSinceEpoch),
        );
        expect(
          reconstructed.departureTime.millisecondsSinceEpoch,
          equals(validPayload.departureTime.millisecondsSinceEpoch),
        );
      });
    });

    group('expiration logic', () {
      test('should not be expired when created', () {
        expect(validPayload.isExpired, isFalse);
      });

      test('should be expired after 24 hours', () {
        final oldGeneratedAt = testGeneratedAt.subtract(
          const Duration(hours: 25),
        );
        final expiredPayload = QRCodePayload(
          passId: 'PASS_123',
          flightNumber: 'BR857',
          seatNumber: '12A',
          memberNumber: 'AA123456',
          departureTime: testDepartureTime,
          generatedAt: oldGeneratedAt,
          nonce: 'nonce',
          issuer: 'airline.app',
        );

        expect(expiredPayload.isExpired, isTrue);
      });

      test('should return correct time remaining', () {
        final timeRemaining = validPayload.timeRemaining;

        expect(timeRemaining, isNotNull);
        expect(timeRemaining!.inHours, lessThanOrEqualTo(24));
        expect(timeRemaining.inHours, greaterThanOrEqualTo(23));
      });

      test('should return null time remaining when expired', () {
        final oldGeneratedAt = testGeneratedAt.subtract(
          const Duration(hours: 25),
        );
        final expiredPayload = QRCodePayload(
          passId: 'PASS_123',
          flightNumber: 'BR857',
          seatNumber: '12A',
          memberNumber: 'AA123456',
          departureTime: testDepartureTime,
          generatedAt: oldGeneratedAt,
          nonce: 'nonce',
          issuer: 'airline.app',
        );

        expect(expiredPayload.timeRemaining, isNull);
      });
    });

    group('cross-timezone compatibility', () {
      test('should maintain expiration logic across timezones', () {
        TestTimezoneHelper.setupForTesting('Asia/Taipei');
        final taipeiGeneratedAt = TZDateTime.now(getLocation('Asia/Taipei'));
        final taipeiPayload = QRCodePayload(
          passId: 'PASS_123',
          flightNumber: 'BR857',
          seatNumber: '12A',
          memberNumber: 'AA123456',
          departureTime: taipeiGeneratedAt.add(const Duration(hours: 4)),
          generatedAt: taipeiGeneratedAt,
          nonce: 'nonce',
          issuer: 'airline.app',
        );

        TestTimezoneHelper.setupForTesting('America/Los_Angeles');
        final isExpiredInLA = taipeiPayload.isExpired;

        TestTimezoneHelper.setupForTesting('Europe/London');
        final isExpiredInLondon = taipeiPayload.isExpired;

        expect(isExpiredInLA, equals(isExpiredInLondon));

        TestTimezoneHelper.setupForTesting();
      });
    });
  });

  group('QRCodeData - Value Object Tests', () {
    late QRCodeData validQRCode;
    late TZDateTime testGeneratedAt;

    setUp(() {
      testGeneratedAt = TZDateTime.now(local);
      validQRCode = QRCodeData.create(
        token: 'valid_token',
        signature: 'signature_hash_123',
        generatedAt: testGeneratedAt,
      );
    });

    group('create factory', () {
      test('should create QRCodeData with valid parameters', () {
        final qrCode = QRCodeData.create(
          token: 'valid_token',
          signature: 'valid_signature',
          generatedAt: testGeneratedAt,
          version: 2,
        );

        expect(qrCode.token, equals('valid_token'));
        expect(qrCode.signature, equals('valid_signature'));
        expect(qrCode.generatedAt, equals(testGeneratedAt));
        expect(qrCode.version, equals(2));
      });

      test('should use default version 1', () {
        final qrCode = QRCodeData.create(
          token: 'token',
          signature: 'signature',
          generatedAt: testGeneratedAt,
        );

        expect(qrCode.version, equals(1));
      });

      test('should throw DomainException when token is empty', () {
        expect(
          () => QRCodeData.create(
            token: '',
            signature: 'signature',
            generatedAt: testGeneratedAt,
          ),
          throwsA(isA<DomainException>()),
        );
      });

      test('should throw DomainException when signature is empty', () {
        expect(
          () => QRCodeData.create(
            token: 'token',
            signature: '',
            generatedAt: testGeneratedAt,
          ),
          throwsA(isA<DomainException>()),
        );
      });
    });

    group('QR string serialization', () {
      test('should convert to QR string correctly', () {
        final qrString = validQRCode.toQRString();
        final parts = qrString.split('.');

        expect(parts.length, equals(4));
        expect(parts[2], equals(validQRCode.token));
        expect(parts[3], equals(validQRCode.signature));
      });

      test('should handle different versions', () {
        final qrCodeV2 = QRCodeData.create(
          token: 'token',
          signature: 'signature',
          generatedAt: testGeneratedAt,
          version: 2,
        );

        final qrString = qrCodeV2.toQRString();
        expect(qrString, contains('Mg')); // Base64url encoded "2"
      });

      test('should handle timestamps correctly', () {
        final specificTime = TZDateTime.from(
          DateTime(2025, 7, 15, 14, 30),
          local,
        );
        final qrCode = QRCodeData.create(
          token: 'token',
          signature: 'signature',
          generatedAt: specificTime,
        );

        final qrString = qrCode.toQRString();
        final reconstructed = QRCodeData.fromQRString(qrString);

        expect(reconstructed.generatedAt, equals(specificTime));
      });

      test('should handle round-trip conversion', () {
        final originalString = validQRCode.toQRString();
        final parsed = QRCodeData.fromQRString(originalString);
        final convertedBack = parsed.toQRString();

        expect(convertedBack, equals(originalString));
      });
    });

    group('QR string parsing', () {
      test('should parse valid QR string correctly', () {
        final originalString = validQRCode.toQRString();
        final parsed = QRCodeData.fromQRString(originalString);

        expect(parsed.token, equals(validQRCode.token));
        expect(parsed.signature, equals(validQRCode.signature));
        expect(parsed.version, equals(validQRCode.version));
      });

      test(
        'should throw DomainException for invalid format - wrong part count',
        () {
          expect(
            () => QRCodeData.fromQRString('invalid.format'),
            throwsA(isA<DomainException>()),
          );

          expect(
            () => QRCodeData.fromQRString('too.many.parts.here.extra'),
            throwsA(isA<DomainException>()),
          );
        },
      );

      test('should throw DomainException for invalid base64url encoding', () {
        expect(
          () => QRCodeData.fromQRString(
            'invalid_base64.invalid_base64.token.signature',
          ),
          throwsA(isA<DomainException>()),
        );
      });

      test('should throw DomainException for invalid version format', () {
        final invalidVersionBytes = utf8.encode('invalid');
        final invalidVersionB64 = base64Url
            .encode(invalidVersionBytes)
            .replaceAll('=', '');
        final validTimestampB64 = _encodeTimestamp(testGeneratedAt);
        final invalidVersionQR =
            '$invalidVersionB64.$validTimestampB64.token.signature';

        expect(
          () => QRCodeData.fromQRString(invalidVersionQR),
          throwsA(isA<DomainException>()),
        );
      });

      test('should throw DomainException for invalid timestamp format', () {
        final invalidTimestampBytes = utf8.encode('invalid');
        final invalidTimestampB64 = base64Url
            .encode(invalidTimestampBytes)
            .replaceAll('=', '');
        final invalidTimestampQR = 'MQ.$invalidTimestampB64.token.signature';

        expect(
          () => QRCodeData.fromQRString(invalidTimestampQR),
          throwsA(isA<DomainException>()),
        );
      });
    });

    group('base64url encoding edge cases', () {
      test('should handle padding correctly', () {
        final testCases = [
          'A', // needs ==
          'AB', // needs =
          'ABC', // no padding needed
          'ABCD', // no padding needed
        ];

        for (final testCase in testCases) {
          final qrCode = QRCodeData.create(
            token: testCase,
            signature: 'signature',
            generatedAt: testGeneratedAt,
          );

          final qrString = qrCode.toQRString();
          final parsed = QRCodeData.fromQRString(qrString);

          expect(parsed.token, equals(testCase));
        }
      });

      test('should reject invalid base64url string with length % 4 == 1', () {
        expect(
          () => QRCodeData.fromQRString('Q.validTimestamp.token.signature'),
          throwsA(isA<DomainException>()),
        );
      });
    });

    group('cross-timezone compatibility', () {
      test('should parse QR code generated in different timezone', () {
        TestTimezoneHelper.setupForTesting('Asia/Taipei');
        final taipeiTime = TZDateTime.now(getLocation('Asia/Taipei'));
        final qrCode = QRCodeData.create(
          token: 'token',
          signature: 'signature',
          generatedAt: taipeiTime,
        );
        final qrString = qrCode.toQRString();

        TestTimezoneHelper.setupForTesting('Asia/Tokyo');
        final parsed = QRCodeData.fromQRString(qrString);

        expect(
          parsed.generatedAt.millisecondsSinceEpoch,
          equals(taipeiTime.millisecondsSinceEpoch),
        );

        TestTimezoneHelper.setupForTesting();
      });

      test('should handle DST transition times', () {
        TestTimezoneHelper.setupForTesting('America/Los_Angeles');

        final dstTime = TZDateTime(
          getLocation('America/Los_Angeles'),
          2025,
          3,
          9,
          1,
          30,
        );

        final qrCode = QRCodeData.create(
          token: 'token',
          signature: 'signature',
          generatedAt: dstTime,
        );

        final qrString = qrCode.toQRString();
        final parsed = QRCodeData.fromQRString(qrString);

        expect(parsed.generatedAt, equals(dstTime));

        TestTimezoneHelper.setupForTesting();
      });
    });

    group('equality and hashCode', () {
      test('should be equal for same values', () {
        final qrCode1 = QRCodeData.create(
          token: 'token',
          signature: 'signature',
          generatedAt: testGeneratedAt,
        );

        final qrCode2 = QRCodeData.create(
          token: 'token',
          signature: 'signature',
          generatedAt: testGeneratedAt,
        );

        expect(qrCode1, equals(qrCode2));
        expect(qrCode1.hashCode, equals(qrCode2.hashCode));
      });

      test('should not be equal for different values', () {
        final qrCode1 = QRCodeData.create(
          token: 'token1',
          signature: 'signature',
          generatedAt: testGeneratedAt,
        );

        final qrCode2 = QRCodeData.create(
          token: 'token2',
          signature: 'signature',
          generatedAt: testGeneratedAt,
        );

        expect(qrCode1, isNot(equals(qrCode2)));
      });

      test('should handle identical objects', () {
        expect(validQRCode, equals(validQRCode));
      });
    });

    group('toString', () {
      test('should return meaningful string representation', () {
        final toString = validQRCode.toString();

        expect(toString, contains('QRCodeData'));
        expect(toString, contains('version: 1'));
        expect(toString, contains(testGeneratedAt.toString()));
      });
    });
  });
}

String _encodeTimestamp(TZDateTime dateTime) {
  final timestampBytes = utf8.encode(
    dateTime.millisecondsSinceEpoch.toString(),
  );
  return base64Url.encode(timestampBytes).replaceAll('=', '');
}
