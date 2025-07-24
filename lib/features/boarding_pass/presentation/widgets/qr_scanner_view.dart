import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:app/features/shared/presentation/theme/app_colors.dart';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:timezone/timezone.dart' as tz;

/// Mock QR Scanner View Widget
/// In production, this would integrate with qr_code_scanner package
class QRScannerView extends HookWidget {
  final Function(String) onScan;

  const QRScannerView({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    // Animation controller with automatic lifecycle management
    final animationController = useAnimationController(
      duration: const Duration(seconds: 2),
    );

    // Animation value derived from controller
    final animation = useAnimation(
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
      ),
    );

    // Start animation
    useEffect(() {
      animationController.repeat(reverse: true);
      return null;
    }, []);

    // Mock scan simulation with valid QR data
    useEffect(() {
      final timer = Timer(const Duration(seconds: 3), () {
        // Generate valid mock QR data that matches the expected format
        final mockQRData = _generateValidMockQRCode();
        onScan(mockQRData);
      });

      return () => timer.cancel();
    }, []);

    return Stack(
      children: [
        // Camera placeholder
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(204),
                Colors.black.withAlpha(153),
                Colors.black.withAlpha(204),
              ],
            ),
          ),
          child: Center(
            child: Text(
              '相機預覽\n(模擬掃描中...)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 16,
              ),
            ),
          ),
        ),

        // Scanning overlay frame
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Corner indicators
                ...List.generate(4, (index) {
                  return Positioned(
                    top: index < 2 ? 8 : null,
                    bottom: index >= 2 ? 8 : null,
                    left: index % 2 == 0 ? 8 : null,
                    right: index % 2 == 1 ? 8 : null,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.primary, width: 3),
                          left: BorderSide(color: AppColors.primary, width: 3),
                        ),
                      ),
                      transform: Matrix4.identity()
                        ..rotateZ(
                          index * 1.5708,
                        ), // 90 degrees rotation per corner
                    ),
                  );
                }),

                // Animated scanning line
                Positioned(
                  left: 0,
                  right: 0,
                  top: animation * 220 + 15,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withAlpha(127),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // User instruction overlay
        Positioned(
          bottom: 50,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(179),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '將 QR Code 對準掃描框\n保持穩定等待掃描',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  /// Generate valid mock QR code data that matches QRCodeData format
  String _generateValidMockQRCode() {
    try {
      // Create mock boarding pass payload
      final now = tz.TZDateTime.now(tz.local);
      final departureTime = now.add(Duration(hours: 2));

      final mockPayload = {
        'passId': 'BPW3AHOV29',
        'flightNumber': 'CI123',
        'seatNumber': '12A',
        'memberNumber': 'AA123456',
        'departureTime': departureTime.toIso8601String(),
        'generatedAt': now.toIso8601String(),
      };

      // Convert payload to JSON string
      final jsonPayload = jsonEncode(mockPayload);

      // Encrypt payload using the same method as QRCodeData
      final encryptedPayload = _encryptPayload(jsonPayload);

      // Generate valid checksum
      final checksum = _generateChecksum(encryptedPayload, now);

      // Return in expected format: encryptedPayload|checksum|generatedAt|version
      return '$encryptedPayload|$checksum|${now.toIso8601String()}|2';
    } catch (e) {
      // Fallback to basic mock if encryption fails
      final now = tz.TZDateTime.now(tz.local);
      return 'FALLBACK_PAYLOAD|FALLBACK_CHECKSUM|${now.toIso8601String()}|1';
    }
  }

  /// Encrypt payload using same algorithm as QRCodeData._encryptPayload
  String _encryptPayload(String payload) {
    try {
      final bytes = utf8.encode(payload);
      final encoded = base64Encode(bytes);

      // Apply Caesar cipher with shift of 3
      return encoded
          .split('')
          .map((char) {
            final charCode = char.codeUnitAt(0);
            if (charCode >= 65 && charCode <= 90) {
              // A-Z
              return String.fromCharCode(((charCode - 65 + 3) % 26) + 65);
            } else if (charCode >= 97 && charCode <= 122) {
              // a-z
              return String.fromCharCode(((charCode - 97 + 3) % 26) + 97);
            }
            return char;
          })
          .join('');
    } catch (e) {
      return 'ENCRYPTION_ERROR';
    }
  }

  /// Generate checksum using same algorithm as QRCodeData._generateChecksum
  String _generateChecksum(String payload, tz.TZDateTime timestamp) {
    try {
      final combined = '$payload${timestamp.millisecondsSinceEpoch}';
      final bytes = utf8.encode(combined);
      final digest = md5.convert(bytes);
      return digest.toString().substring(0, 12); // First 12 characters
    } catch (e) {
      return 'CHECKSUM_ERROR';
    }
  }
}
