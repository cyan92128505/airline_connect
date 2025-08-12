import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:app/core/presentation/widgets/error_display.dart';
import 'package:app/core/presentation/widgets/loading_indicator.dart';
import 'package:app/features/boarding_pass/presentation/notifiers/boarding_pass_notifier.dart';
import 'package:app/features/boarding_pass/presentation/widgets/instruction_item.dart';
import 'package:app/features/boarding_pass/presentation/widgets/scan_result_display.dart';
import 'package:app/features/boarding_pass/presentation/widgets/scanner_status_info.dart';
import 'package:app/features/shared/presentation/providers/qr_scanner_provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ResultsAreaView extends HookConsumerWidget {
  const ResultsAreaView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all relevant state providers
    final boardingPassState = ref.watch(boardingPassNotifierProvider);
    final scannerState = ref.watch(qRScannerProvider);

    // Get notifiers
    final boardingPassNotifier = ref.read(
      boardingPassNotifierProvider.notifier,
    );
    final scannerNotifier = ref.read(qRScannerProvider.notifier);

    // Show boarding pass validation in progress
    if (boardingPassState.isScanning) {
      return const Center(child: LoadingIndicator(message: '正在驗證 QR Code...'));
    }

    // Show boarding pass validation error
    if (boardingPassState.hasError) {
      return Center(
        child: ErrorDisplay(
          message: boardingPassState.errorMessage!,
          onRetry: () {
            boardingPassNotifier.clearError();
            scannerNotifier.clearResult();
          },
        ),
      );
    }

    // Show scan result
    if (boardingPassState.scanResult != null) {
      return ScanResultDisplay(
        result: boardingPassState.scanResult!,
        onClear: () {
          boardingPassNotifier.clearScanResult();
          scannerNotifier.clearResult();
        },
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  scannerState.instructionIcon,
                  color: AppColors.info,
                  size: 20,
                ),
                const Gap(8),
                Text(
                  scannerState.instructionTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Gap(16),

            ...scannerState.instructionItems.map(
              (item) => InstructionItem(item),
            ),

            const Gap(16),

            const ScannerStatusInfo(),
          ],
        ),
      ),
    );
  }
}
