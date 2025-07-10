import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:app/features/shared/presentation/theme/app_colors.dart';
import 'dart:async';

/// Mock QR Scanner View Widget
/// In production, this would integrate with qr_code_scanner package
class QRScannerView extends HookWidget {
  final Function(String) onScan;

  const QRScannerView({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(seconds: 2),
    );
    final animation = useAnimation(
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
      ),
    );

    // Start animation
    useEffect(() {
      animationController.repeat(reverse: true);
      return () => animationController.dispose();
    }, []);

    // Mock scan after 3 seconds
    useEffect(() {
      final timer = Timer(const Duration(seconds: 3), () {
        // Mock QR data for demo
        onScan(
          'MOCK_ENCRYPTED_PAYLOAD|ABC123DEF456|${DateTime.now().toIso8601String()}|2',
        );
      });
      return timer.cancel;
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

        // Scan overlay
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
                // Corner decorations
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
                        ..rotateZ(index * 1.5708), // 90 degrees * index
                    ),
                  );
                }),

                // Scanning line animation
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

        // Instructions
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
            child: Text(
              '將 QR Code 對準掃描框\n保持穩定等待掃描',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
