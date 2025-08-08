import 'package:app/features/shared/presentation/providers/qr_scanner_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class QRStatusOverlay extends HookConsumerWidget {
  const QRStatusOverlay({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(qRScannerProvider);

    return Positioned(
      bottom: 50,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(127),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          scannerState.statusMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}
