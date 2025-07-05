import 'dart:convert';
import 'package:app/features/flight/value_objects/flight_number.dart';
import 'package:app/features/member/value_objects/member_number.dart';
import 'package:crypto/crypto.dart';
import 'package:timezone/timezone.dart';
import 'pass_id.dart';
import 'seat_number.dart';

class QRCodeData {
  final String encryptedPayload;
  final String checksum;
  final TZDateTime generatedAt;
  final int version;

  const QRCodeData({
    required this.encryptedPayload,
    required this.checksum,
    required this.generatedAt,
    required this.version,
  });

  /// Generate QR code for boarding pass
  factory QRCodeData.generate({
    required PassId passId,
    required FlightNumber flightNumber,
    required SeatNumber seatNumber,
    required MemberNumber memberNumber,
    required TZDateTime departureTime,
    int version = 1,
  }) {
    final generatedAt = TZDateTime.now(local);

    final payload = QRPayload(
      passId: passId.value,
      flightNumber: flightNumber.value,
      seatNumber: seatNumber.value,
      memberNumber: memberNumber.value,
      departureTime: departureTime,
      generatedAt: generatedAt,
    );

    final jsonPayload = payload.toJsonString();
    final encryptedPayload = _encryptPayload(jsonPayload);

    // Generate checksum
    final checksum = _generateChecksum(encryptedPayload, generatedAt);

    return QRCodeData(
      encryptedPayload: encryptedPayload,
      checksum: checksum,
      generatedAt: generatedAt,
      version: version,
    );
  }

  QRPayload? decryptPayload() {
    try {
      if (!_verifyChecksum()) {
        return null;
      }

      final decryptedJson = _decryptPayload(encryptedPayload);

      return QRPayload.fromJsonString(decryptedJson);
    } catch (e) {
      return null; // Invalid QR code
    }
  }

  bool get isValid {
    final now = TZDateTime.now(local);
    const validityDuration = Duration(hours: 2);

    if (now.difference(generatedAt) > validityDuration) {
      return false;
    }

    return _verifyChecksum();
  }

  Duration? get timeRemaining {
    const validityDuration = Duration(hours: 2);
    final expiryTime = generatedAt.add(validityDuration);
    final now = TZDateTime.now(local);

    if (now.isAfter(expiryTime)) {
      return null;
    }

    return expiryTime.difference(now);
  }

  static String _encryptPayload(String payload) {
    final bytes = utf8.encode(payload);
    final encoded = base64Encode(bytes);
    return encoded
        .split('')
        .map((char) {
          if (char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90) {
            return String.fromCharCode(
              ((char.codeUnitAt(0) - 65 + 3) % 26) + 65,
            );
          } else if (char.codeUnitAt(0) >= 97 && char.codeUnitAt(0) <= 122) {
            return String.fromCharCode(
              ((char.codeUnitAt(0) - 97 + 3) % 26) + 97,
            );
          }
          return char;
        })
        .join('');
  }

  static String _decryptPayload(String encryptedPayload) {
    final decrypted = encryptedPayload
        .split('')
        .map((char) {
          if (char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90) {
            return String.fromCharCode(
              ((char.codeUnitAt(0) - 65 - 3 + 26) % 26) + 65,
            );
          } else if (char.codeUnitAt(0) >= 97 && char.codeUnitAt(0) <= 122) {
            return String.fromCharCode(
              ((char.codeUnitAt(0) - 97 - 3 + 26) % 26) + 97,
            );
          }
          return char;
        })
        .join('');

    final bytes = base64Decode(decrypted);
    return utf8.decode(bytes);
  }

  static String _generateChecksum(String payload, TZDateTime timestamp) {
    final combined = '$payload${timestamp.millisecondsSinceEpoch}';
    final bytes = utf8.encode(combined);
    final digest = md5.convert(bytes);
    return digest.toString().substring(0, 12); // First 12 characters
  }

  bool _verifyChecksum() {
    final expectedChecksum = _generateChecksum(encryptedPayload, generatedAt);
    return checksum == expectedChecksum;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QRCodeData &&
        other.encryptedPayload == encryptedPayload &&
        other.checksum == checksum &&
        other.generatedAt == generatedAt &&
        other.version == version;
  }

  @override
  int get hashCode =>
      Object.hash(encryptedPayload, checksum, generatedAt, version);

  @override
  String toString() => 'QRCodeData(version: $version, checksum: $checksum)';
}

class QRPayload {
  final String passId;
  final String flightNumber;
  final String seatNumber;
  final String memberNumber;
  final TZDateTime departureTime;
  final TZDateTime generatedAt;

  const QRPayload({
    required this.passId,
    required this.flightNumber,
    required this.seatNumber,
    required this.memberNumber,
    required this.departureTime,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'passId': passId,
      'flightNumber': flightNumber,
      'seatNumber': seatNumber,
      'memberNumber': memberNumber,
      'departureTime': departureTime.toIso8601String(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory QRPayload.fromJson(Map<String, dynamic> json) {
    return QRPayload(
      passId: json['passId'] as String,
      flightNumber: json['flightNumber'] as String,
      seatNumber: json['seatNumber'] as String,
      memberNumber: json['memberNumber'] as String,
      departureTime: TZDateTime.parse(local, json['departureTime'] as String),
      generatedAt: TZDateTime.parse(local, json['generatedAt'] as String),
    );
  }

  factory QRPayload.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return QRPayload.fromJson(json);
  }

  String toJsonString() => jsonEncode(toJson());

  @override
  String toString() {
    return 'QRPayload(passId: $passId, flightNumber: $flightNumber, '
        'seatNumber: $seatNumber, memberNumber: $memberNumber)';
  }
}
