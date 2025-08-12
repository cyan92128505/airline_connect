import 'package:app/core/presentation/widgets/loading_indicator.dart';
import 'package:app/features/shared/presentation/providers/camera_permission_provider.dart';
import 'package:app/features/shared/presentation/providers/qr_scanner_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoadingStateView extends HookConsumerWidget {
  const LoadingStateView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(cameraPermissionProvider);
    final scannerState = ref.watch(qRScannerProvider);
    String message;

    if (permissionState.isRequesting) {
      message = '正在檢查相機權限...';
    } else if (scannerState.status == ScannerStatus.initializing) {
      message = '正在啟動相機掃描器...';
    } else if (scannerState.status == ScannerStatus.processing) {
      message = '正在處理掃描結果...';
    } else {
      message = '請稍候...';
    }

    return Center(child: LoadingIndicator(message: message));
  }
}
