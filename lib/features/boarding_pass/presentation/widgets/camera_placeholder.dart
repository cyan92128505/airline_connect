import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:app/features/shared/presentation/providers/qr_scanner_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CameraPlaceholder extends HookConsumerWidget {
  const CameraPlaceholder({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(qRScannerProvider);

    IconData icon;
    String title;
    String subtitle;
    Color iconColor;

    switch (scannerState.status) {
      case ScannerStatus.permissionRequired:
        icon = Icons.camera_alt_outlined;
        title = '需要相機權限';
        subtitle = scannerState.errorMessage ?? '請允許使用相機以掃描 QR Code';
        iconColor = AppColors.warning;
        break;
      case ScannerStatus.initializing:
        icon = Icons.camera_enhance_outlined;
        title = '正在初始化';
        subtitle = '請稍候，正在啟動相機...';
        iconColor = AppColors.primary;
        break;
      case ScannerStatus.error:
        icon = Icons.error_outline;
        title = '相機錯誤';
        subtitle = scannerState.errorMessage ?? '無法啟動相機掃描器';
        iconColor = AppColors.error;
        break;
      default:
        icon = Icons.qr_code_scanner;
        title = '準備掃描';
        subtitle = '正在準備 QR Code 掃描器...';
        iconColor = AppColors.primary;
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: iconColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(128),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
