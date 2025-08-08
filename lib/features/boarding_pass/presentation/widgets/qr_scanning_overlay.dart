import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:app/features/shared/presentation/providers/qr_scanner_provider.dart';
import 'package:app/features/shared/presentation/utils/corner_indicator_painter.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class QRScanningOverlay extends HookConsumerWidget {
  const QRScanningOverlay(this.animation, {super.key});

  final double animation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(qRScannerProvider);

    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            CornerIndicator(Alignment.topLeft, 0),
            CornerIndicator(Alignment.topRight, 1),
            CornerIndicator(Alignment.bottomRight, 2),
            CornerIndicator(Alignment.bottomLeft, 3),

            if (scannerState.status == ScannerStatus.scanning ||
                scannerState.status == ScannerStatus.ready)
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
                        color: AppColors.success.withAlpha(128),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CornerIndicator extends StatelessWidget {
  const CornerIndicator(this.alignment, this.cornerIndex, {super.key});

  final Alignment alignment;
  final int cornerIndex;

  @override
  Widget build(BuildContext context) {
    const double lineLength = 20.0;
    const double lineWidth = 3.0;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: lineLength,
        height: lineLength,
        child: Padding(
          padding: EdgeInsetsGeometry.all(8),
          child: CustomPaint(
            painter: CornerIndicatorPainter(
              color: AppColors.primary,
              lineWidth: lineWidth,
              isTopLeft: cornerIndex == 0,
              isTopRight: cornerIndex == 1,
              isBottomRight: cornerIndex == 2,
              isBottomLeft: cornerIndex == 3,
            ),
          ),
        ),
      ),
    );
  }
}
