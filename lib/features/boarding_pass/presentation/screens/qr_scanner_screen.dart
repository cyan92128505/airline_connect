import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:app/core/presentation/widgets/error_display.dart';
import 'package:app/core/presentation/widgets/loading_indicator.dart';
import 'package:app/features/boarding_pass/presentation/notifiers/boarding_pass_notifier.dart';
import 'package:app/features/boarding_pass/presentation/widgets/qr_scanner_view.dart';
import 'package:app/features/boarding_pass/presentation/widgets/scan_result_display.dart';
import 'package:app/features/boarding_pass/presentation/widgets/start_scanner_button.dart';
import 'package:app/features/shared/presentation/providers/camera_permission_provider.dart';
import 'package:app/features/shared/presentation/providers/qr_scanner_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// QR Scanner screen for validating boarding passes
class QRScannerScreen extends HookConsumerWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all relevant state providers
    final boardingPassState = ref.watch(boardingPassNotifierProvider);
    final cameraPermissionState = ref.watch(cameraPermissionProvider);
    final scannerState = ref.watch(qRScannerProvider);

    // Get notifiers
    final boardingPassNotifier = ref.read(
      boardingPassNotifierProvider.notifier,
    );
    final cameraPermissionNotifier = ref.read(
      cameraPermissionProvider.notifier,
    );
    final scannerNotifier = ref.read(qRScannerProvider.notifier);

    // Check permission status on mount
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await cameraPermissionNotifier.checkPermissionStatus();
        await scannerNotifier.setupPermission();
      });
      return null;
    }, []);

    // Handle QR scan results
    useEffect(() {
      if (scannerState.scannedData != null) {
        _handleQRScan(scannerState.scannedData!, boardingPassNotifier);
      }
      return null;
    }, [scannerState.scannedData]);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_getAppBarTitle(scannerState)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Service status indicator

          // Clear/reset action
          IconButton(
            onPressed: () =>
                _handleClearAction(boardingPassNotifier, scannerNotifier),
            icon: const Icon(Icons.clear),
            tooltip: '清除結果',
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner area
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildScannerContent(
                  context,
                  cameraPermissionState,
                  scannerState,
                  cameraPermissionNotifier,
                  scannerNotifier,
                ),
              ),
            ),
          ),

          // Results area
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildResultsArea(
                context,
                boardingPassState,
                cameraPermissionState,
                scannerState,
                boardingPassNotifier,
                cameraPermissionNotifier,
                scannerNotifier,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get app bar title based on scanner state and environment
  String _getAppBarTitle(QRScannerState scannerState) {
    return switch (scannerState.status) {
      ScannerStatus.scanning => 'QR Code 掃描中...',
      ScannerStatus.processing => '處理掃描結果...',
      ScannerStatus.completed => 'QR Code 掃描完成',
      ScannerStatus.error => 'QR Code 掃描器錯誤',
      _ => 'QR Code 掃描器',
    };
  }

  /// Build scanner content based on permission and scanner state
  Widget _buildScannerContent(
    BuildContext context,
    CameraPermissionState permissionState,
    QRScannerState scannerState,
    CameraPermission permissionNotifier,
    QRScanner scannerNotifier,
  ) {
    // Show permission error if needed
    if (!permissionState.isGranted && scannerState.isPermissionBlocked) {
      return _buildPermissionError(
        context,
        permissionState,
        permissionNotifier,
      );
    }

    // Show scanner error if needed
    if (scannerState.status == ScannerStatus.error) {
      return _buildScannerError(context, scannerState, scannerNotifier);
    }

    // Show loading state
    if (permissionState.isRequesting || scannerState.isBusy) {
      return _buildLoadingState(context, permissionState, scannerState);
    }

    // Show scanner view or start button
    if (scannerState.shouldShowCamera ||
        scannerState.status == ScannerStatus.ready) {
      return QRScannerView(
        onScan: (data) {
          // QRScannerView handles scan internally via provider
        },
      );
    }

    return const StartScannerButton();
  }

  /// Build permission error UI
  Widget _buildPermissionError(
    BuildContext context,
    CameraPermissionState permissionState,
    CameraPermission permissionNotifier,
  ) {
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

  /// Build scanner error UI
  Widget _buildScannerError(
    BuildContext context,
    QRScannerState scannerState,
    QRScanner scannerNotifier,
  ) {
    return ErrorDisplay.camera(
      message: scannerState.errorMessage ?? '掃描器發生錯誤',
      onRetry: () async {
        await scannerNotifier.reset();
        await scannerNotifier.startScanner();
      },
    );
  }

  /// Build loading state UI
  Widget _buildLoadingState(
    BuildContext context,
    CameraPermissionState permissionState,
    QRScannerState scannerState,
  ) {
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

  /// Build results area based on current state
  Widget _buildResultsArea(
    BuildContext context,
    BoardingPassState boardingPassState,
    CameraPermissionState permissionState,
    QRScannerState scannerState,
    BoardingPassNotifier boardingPassNotifier,
    CameraPermission permissionNotifier,
    QRScanner scannerNotifier,
  ) {
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

    // Show instructions or status
    return _buildInstructionsCard(context, permissionState, scannerState);
  }

  /// Build instructions card
  Widget _buildInstructionsCard(
    BuildContext context,
    CameraPermissionState permissionState,
    QRScannerState scannerState,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getInstructionIcon(scannerState),
                  color: AppColors.info,
                  size: 20,
                ),
                const Gap(8),
                Text(
                  _getInstructionTitle(scannerState),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Gap(16),

            ..._getInstructionItems(scannerState),

            const Gap(16),

            _buildStatusInfo(permissionState, scannerState),
          ],
        ),
      ),
    );
  }

  /// Get instruction icon based on scanner state
  IconData _getInstructionIcon(QRScannerState scannerState) {
    return switch (scannerState.status) {
      ScannerStatus.ready || ScannerStatus.scanning => Icons.qr_code_scanner,
      ScannerStatus.completed => Icons.check_circle_outline,
      ScannerStatus.error => Icons.error_outline,
      _ => Icons.info_outline,
    };
  }

  /// Get instruction title based on scanner state and environment
  String _getInstructionTitle(QRScannerState scannerState) {
    return switch (scannerState.status) {
      ScannerStatus.ready || ScannerStatus.scanning => '掃描進行中',
      ScannerStatus.completed => '掃描完成',
      ScannerStatus.error => '掃描錯誤',
      _ => '掃描說明',
    };
  }

  /// Get instruction items based on scanner state and environment
  List<Widget> _getInstructionItems(QRScannerState scannerState) {
    final items = <String>[];

    if (scannerState.status == ScannerStatus.ready ||
        scannerState.status == ScannerStatus.scanning) {
      items.addAll(['保持 QR Code 清晰可見', '將 QR Code 對準掃描框中央', '保持穩定直到掃描成功']);
    } else {
      items.addAll(['確保登機證上的 QR Code 清晰可見', '在光線充足的環境下掃描效果更佳', '掃描時請保持手機穩定']);
    }

    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 16),
                const Gap(12),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  /// Build status info section
  Widget _buildStatusInfo(
    CameraPermissionState permissionState,
    QRScannerState scannerState,
  ) {
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

  /// Handle QR scan result
  void _handleQRScan(String qrData, BoardingPassNotifier boardingPassNotifier) {
    // Parse QR data format: encryptedPayload|checksum|generatedAt|version
    final parts = qrData.split('|');

    if (parts.length >= 4) {
      boardingPassNotifier.validateQRCode(
        encryptedPayload: parts[0],
        checksum: parts[1],
        generatedAt: parts[2],
        version: int.tryParse(parts[3]) ?? 1,
      );
    } else {
      // Handle invalid QR format
      boardingPassNotifier.validateQRCode(
        encryptedPayload: qrData,
        checksum: 'invalid',
        generatedAt: DateTime.now().toIso8601String(),
        version: 1,
      );
    }
  }

  /// Handle clear action
  void _handleClearAction(
    BoardingPassNotifier boardingPassNotifier,
    QRScanner scannerNotifier,
  ) {
    boardingPassNotifier.clearScanResult();
    boardingPassNotifier.clearError();
    scannerNotifier.clearResult();
  }
}
