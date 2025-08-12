import 'dart:convert';
import 'package:app/core/exceptions/domain_exception.dart';
import 'package:timezone/timezone.dart';

class QRCodeData {
  final String token;
  final String signature;
  final TZDateTime generatedAt;
  final int version;

  const QRCodeData._({
    required this.token,
    required this.signature,
    required this.generatedAt,
    required this.version,
  });

  factory QRCodeData.create({
    required String token,
    required String signature,
    required TZDateTime generatedAt,
    int version = 1,
  }) {
    if (token.isEmpty) {
      throw DomainException('QR code token cannot be empty');
    }
    if (signature.isEmpty) {
      throw DomainException('QR code signature cannot be empty');
    }

    return QRCodeData._(
      token: token,
      signature: signature,
      generatedAt: generatedAt,
      version: version,
    );
  }

  /// Parse QR code from scanned string
  factory QRCodeData.fromQRString(String qrString) {
    try {
      final parts = qrString.split('.');
      if (parts.length != 4) {
        throw const FormatException('Invalid QR code format');
      }

      final versionData = _decodeBase64Url(parts[0]);
      final version = int.parse(utf8.decode(versionData));

      final timestampData = _decodeBase64Url(parts[1]);
      final timestamp = int.parse(utf8.decode(timestampData));
      final generatedAt = TZDateTime.fromMillisecondsSinceEpoch(
        local,
        timestamp,
      );

      return QRCodeData._(
        version: version,
        generatedAt: generatedAt,
        token: parts[2],
        signature: parts[3],
      );
    } catch (e) {
      throw DomainException('Invalid QR code format: ${e.toString()}');
    }
  }

  /// Convert to QR code string for display/scanning
  String toQRString() {
    final versionEncoded = _encodeBase64Url(utf8.encode(version.toString()));
    final timestampEncoded = _encodeBase64Url(
      utf8.encode(generatedAt.millisecondsSinceEpoch.toString()),
    );

    final result = '$versionEncoded.$timestampEncoded.$token.$signature';

    return result;
  }

  static String _encodeBase64Url(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static List<int> _decodeBase64Url(String str) {
    String normalized = str;
    switch (str.length % 4) {
      case 1:
        throw const FormatException('Invalid base64url string');
      case 2:
        normalized += '==';
        break;
      case 3:
        normalized += '=';
        break;
    }
    return base64Url.decode(normalized);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QRCodeData &&
        other.token == token &&
        other.signature == signature &&
        other.generatedAt == generatedAt &&
        other.version == version;
  }

  @override
  int get hashCode => Object.hash(token, signature, generatedAt, version);

  @override
  String toString() => 'QRCodeData(version: $version, generated: $generatedAt)';
}

/// QR Code payload for internal processing
class QRCodePayload {
  final String passId;
  final String flightNumber;
  final String seatNumber;
  final String memberNumber;
  final TZDateTime departureTime;
  final TZDateTime generatedAt;
  final String nonce;
  final String issuer;

  const QRCodePayload({
    required this.passId,
    required this.flightNumber,
    required this.seatNumber,
    required this.memberNumber,
    required this.departureTime,
    required this.generatedAt,
    required this.nonce,
    required this.issuer,
  });

  /// JWT-like claims structure
  Map<String, dynamic> toJson() {
    return {
      'iss': issuer, // Issuer
      'sub': passId, // Subject (Pass ID)
      'iat': generatedAt.millisecondsSinceEpoch, // Issued At
      'exp': generatedAt
          .add(const Duration(hours: 24))
          .millisecondsSinceEpoch, // Expires
      'flt': flightNumber,
      'seat': seatNumber,
      'mbr': memberNumber,
      'dep': departureTime.millisecondsSinceEpoch,
      'nonce': nonce,
      'ver': 1,
    };
  }

  factory QRCodePayload.fromJson(Map<String, dynamic> json) {
    return QRCodePayload(
      issuer: json['iss'] as String,
      passId: json['sub'] as String,
      flightNumber: json['flt'] as String,
      seatNumber: json['seat'] as String,
      memberNumber: json['mbr'] as String,
      departureTime: TZDateTime.fromMillisecondsSinceEpoch(
        local,
        json['dep'] as int,
      ),
      generatedAt: TZDateTime.fromMillisecondsSinceEpoch(
        local,
        json['iat'] as int,
      ),
      nonce: json['nonce'] as String,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory QRCodePayload.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return QRCodePayload.fromJson(json);
  }

  /// Check if payload is expired
  bool get isExpired {
    final now = TZDateTime.now(local);
    final expiryTime = generatedAt.add(const Duration(hours: 24));
    return now.isAfter(expiryTime);
  }

  Duration? get timeRemaining {
    final now = TZDateTime.now(local);
    final expiryTime = generatedAt.add(const Duration(hours: 24));

    if (now.isAfter(expiryTime)) {
      return null;
    }

    return expiryTime.difference(now);
  }
}
