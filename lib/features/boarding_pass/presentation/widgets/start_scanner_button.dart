import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:app/features/shared/presentation/providers/qr_scanner_provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class StartScannerButton extends HookConsumerWidget {
  static final widgetKey = Key('StartScannerButton');

  const StartScannerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerNotifier = ref.read(qRScannerProvider.notifier);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(45),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),

            const Gap(16), // Reduced from 24
            // Make text flexible
            Flexible(
              child: Text(
                '準備掃描 QR Code',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const Gap(6), // Reduced from 8
            // Make description text flexible
            Flexible(
              child: Text(
                '點擊下方按鈕開始掃描登機證上的 QR Code',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // Limit lines to prevent overflow
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const Gap(20), // Reduced from 32

            ElevatedButton.icon(
              key: widgetKey,
              onPressed: scannerNotifier.canStart
                  ? () async {
                      await scannerNotifier.startScanner();
                    }
                  : null,
              icon: Icon(Icons.camera_alt),
              label: Text('開始掃描'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
