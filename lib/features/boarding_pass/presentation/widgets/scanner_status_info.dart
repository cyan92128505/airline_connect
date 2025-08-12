import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:app/features/shared/presentation/providers/camera_permission_provider.dart';
import 'package:app/features/shared/presentation/providers/qr_scanner_provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ScannerStatusInfo extends HookConsumerWidget {
  const ScannerStatusInfo({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(cameraPermissionProvider);
    final scannerState = ref.watch(qRScannerProvider);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!permissionState.isGranted) {
      statusColor = AppColors.warning;
      statusText = '相機權限：${permissionState.statusDescription}';
      statusIcon = Icons.camera_alt_outlined;
    } else if (scannerState.status == ScannerStatus.error) {
      statusColor = AppColors.error;
      statusText = '掃描器狀態：錯誤';
      statusIcon = Icons.error_outline;
    } else {
      statusColor = AppColors.success;
      statusText = '系統狀態：正常';
      statusIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const Gap(8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
