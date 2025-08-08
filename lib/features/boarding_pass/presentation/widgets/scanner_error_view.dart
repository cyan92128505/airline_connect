import 'package:app/core/presentation/widgets/error_display.dart';
import 'package:app/features/shared/presentation/providers/qr_scanner_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ScannerErrorView extends HookConsumerWidget {
  const ScannerErrorView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(qRScannerProvider);
    final scannerNotifier = ref.read(qRScannerProvider.notifier);

    return ErrorDisplay.camera(
      message: scannerState.errorMessage ?? '掃描器發生錯誤',
      onRetry: () async {
        await scannerNotifier.reset();
        await scannerNotifier.startScanner();
      },
    );
  }
}
