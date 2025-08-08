import 'package:app/core/presentation/widgets/error_display.dart';
import 'package:app/features/shared/presentation/providers/camera_permission_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PermissionErrorView extends HookConsumerWidget {
  const PermissionErrorView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(cameraPermissionProvider);

    final permissionNotifier = ref.read(cameraPermissionProvider.notifier);

    return ErrorDisplay.permission(
      message: permissionState.errorMessage ?? '需要相機權限才能掃描 QR Code',
      onRetry: () async {
        await permissionNotifier.requestPermission();
      },
      onOpenSettings: permissionState.shouldShowSettings
          ? () async {
              await permissionNotifier.openSettings();
            }
          : null,
    );
  }
}
