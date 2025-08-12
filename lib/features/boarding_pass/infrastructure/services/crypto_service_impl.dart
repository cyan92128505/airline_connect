import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/boarding_pass/domain/services/crypto_service.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/pointycastle.dart';

class CryptoServiceImpl implements CryptoService {
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 12; // 96 bits for GCM
  static const int _tagLength = 16; // 128 bits for GCM tag

  final Random _secureRandom = Random.secure();

  @override
  @override
  String encrypt(
    String plaintext,
    String key, {
    Map<String, dynamic>? metadata,
  }) {
    try {
      final keyBytes = _parseKey(key);
      final iv = _generateSecureBytes(_ivLength);
      final plaintextBytes = utf8.encode(plaintext);

      final aad = metadata != null
          ? utf8.encode(jsonEncode(metadata))
          : Uint8List(0);

      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          true,
          AEADParameters(KeyParameter(keyBytes), _tagLength * 8, iv, aad),
        );

      final ciphertext = cipher.process(plaintextBytes);
      final combined = Uint8List.fromList([...iv, ...ciphertext]);

      return base64Url.encode(combined).replaceAll('=', '');
    } catch (e) {
      throw DomainException('Encryption failed: ${e.toString()}');
    }
  }

  @override
  String decrypt(
    String ciphertext,
    String key, {
    Map<String, dynamic>? metadata,
  }) {
    try {
      final keyBytes = _parseKey(key);
      final combined = _decodeBase64Url(ciphertext);

      if (combined.length < _ivLength + _tagLength) {
        throw const FormatException('Invalid ciphertext format');
      }

      final iv = Uint8List.fromList(combined.sublist(0, _ivLength));
      final encryptedData = Uint8List.fromList(combined.sublist(_ivLength));
      final aad = metadata != null
          ? utf8.encode(jsonEncode(metadata))
          : Uint8List(0);

      // Initialize AES-GCM cipher for decryption
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(KeyParameter(keyBytes), _tagLength * 8, iv, aad),
        );

      final decrypted = cipher.process(encryptedData);
      return utf8.decode(decrypted);
    } catch (e) {
      throw DomainException('Decryption failed: ${e.toString()}');
    }
  }

  @override
  String generateSignature(String data, String secret) {
    try {
      final secretBytes = utf8.encode(secret);
      final dataBytes = utf8.encode(data);

      final hmac = Hmac(sha256, secretBytes);
      final digest = hmac.convert(dataBytes);

      return base64Url.encode(digest.bytes).replaceAll('=', '');
    } catch (e) {
      throw DomainException('Signature generation failed: ${e.toString()}');
    }
  }

  @override
  bool verifySignature(String data, String signature, String secret) {
    try {
      final expectedSignature = generateSignature(data, secret);
      return _constantTimeEquals(signature, expectedSignature);
    } catch (e) {
      return false;
    }
  }

  @override
  String generateNonce() {
    final bytes = _generateSecureBytes(16);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  @override
  String generateKey() {
    final bytes = _generateSecureBytes(_keyLength);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  Uint8List _parseKey(String key) {
    try {
      final keyBytes = _decodeBase64Url(key);
      if (keyBytes.length != _keyLength) {
        throw FormatException('Invalid key length: expected $_keyLength bytes');
      }
      return Uint8List.fromList(keyBytes);
    } catch (e) {
      throw DomainException('Invalid key format: ${e.toString()}');
    }
  }

  Uint8List _generateSecureBytes(int length) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = _secureRandom.nextInt(256);
    }
    return bytes;
  }

  List<int> _decodeBase64Url(String str) {
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

  /// Constant-time string comparison to prevent timing attacks
  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }
}

/// QR code configuration implementation
class ProductionQRCodeConfig implements QRCodeConfig {
  @override
  Duration get validityDuration => const Duration(hours: 2);

  @override
  String get encryptionKey =>
      'your-256-bit-encryption-key-here-base64url-encoded';

  @override
  String get signingSecret => 'your-signing-secret-here';

  @override
  int get currentVersion => 1;

  @override
  String get issuer => 'airline-connect';
}

class MockQRCodeConfig implements QRCodeConfig {
  @override
  Duration get validityDuration => const Duration(hours: 24);

  @override
  String get encryptionKey {
    const key32Bytes = 'demo-encryption-key-123456789012';
    final keyBytes = utf8.encode(key32Bytes);
    return base64Url.encode(keyBytes).replaceAll('=', '');
  }

  @override
  String get signingSecret => 'test-signing-secret-for-demo-app';

  @override
  String get issuer => 'airline-connect-demo';

  @override
  int get currentVersion => 1;
}
