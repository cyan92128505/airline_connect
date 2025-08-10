abstract class CryptoService {
  /// Encrypt plaintext using AES-256-GCM
  String encrypt(
    String plaintext,
    String key, {
    Map<String, dynamic>? metadata,
  });

  /// Decrypt ciphertext using AES-256-GCM
  String decrypt(
    String ciphertext,
    String key, {
    Map<String, dynamic>? metadata,
  });

  /// Generate HMAC-SHA256 signature
  String generateSignature(String data, String secret);

  /// Verify HMAC-SHA256 signature
  bool verifySignature(String data, String signature, String secret);

  /// Generate cryptographically secure random nonce
  String generateNonce();

  /// Generate secure random key
  String generateKey();
}

/// QR code configuration interface
abstract class QRCodeConfig {
  Duration get validityDuration;
  String get encryptionKey;
  String get signingSecret;
  int get currentVersion;
  String get issuer;
}
