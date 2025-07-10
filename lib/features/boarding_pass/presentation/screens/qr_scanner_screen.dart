import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:app/features/boarding_pass/presentation/notifiers/boarding_pass_notifier.dart';
import 'package:app/features/boarding_pass/presentation/widgets/qr_scanner_view.dart';
import 'package:app/features/boarding_pass/presentation/widgets/scan_result_display.dart';
import 'package:app/features/shared/presentation/theme/app_colors.dart';
import 'package:app/features/shared/presentation/widgets/loading_indicator.dart';
import 'package:app/features/shared/presentation/widgets/error_display.dart';

/// QR Scanner screen for validating boarding passes
class QRScannerScreen extends HookConsumerWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardingPassState = ref.watch(boardingPassNotifierProvider);
    final boardingPassNotifier = ref.read(
      boardingPassNotifierProvider.notifier,
    );
    final isScanning = useState(false);
    final hasPermission = useState(false);

    // Check camera permission on mount
    useEffect(() {
      _checkCameraPermission().then((permission) {
        hasPermission.value = permission;
      });
      return null;
    }, []);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('QR Code 掃描器'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              boardingPassNotifier.clearScanResult();
            },
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
                  hasPermission.value,
                  isScanning.value,
                  (value) => isScanning.value = value,
                  boardingPassNotifier,
                ),
              ),
            ),
          ),

          // Results area
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: _buildResultsArea(
                context,
                boardingPassState,
                boardingPassNotifier,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build scanner content based on state
  Widget _buildScannerContent(
    BuildContext context,
    bool hasPermission,
    bool isScanning,
    ValueSetter<bool> setScanning,
    BoardingPassNotifier notifier,
  ) {
    if (!hasPermission) {
      return _buildPermissionRequest(context);
    }

    if (isScanning) {
      return QRScannerView(
        onScan: (qrData) => _handleQRScan(qrData, notifier, setScanning),
      );
    }

    return _buildScannerPlaceholder(context, () => setScanning(true));
  }

  /// Build permission request UI
  Widget _buildPermissionRequest(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: AppColors.textSecondary.withAlpha(127),
            ),
            const Gap(16),
            Text(
              '需要相機權限',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Gap(8),
            Text(
              '請允許使用相機以掃描 QR Code',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: () async {
                await _requestCameraPermission();
                // Handle permission result
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('請求權限'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build scanner placeholder
  Widget _buildScannerPlaceholder(
    BuildContext context,
    VoidCallback onStartScan,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withAlpha(77),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Icon(
                Icons.qr_code_scanner,
                size: 60,
                color: AppColors.primary,
              ),
            ),

            const Gap(24),

            Text(
              '準備掃描 QR Code',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Gap(8),

            Text(
              '點擊下方按鈕開始掃描登機牌上的 QR Code',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),

            const Gap(32),

            ElevatedButton.icon(
              onPressed: onStartScan,
              icon: const Icon(Icons.camera_alt),
              label: const Text('開始掃描'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build results area
  Widget _buildResultsArea(
    BuildContext context,
    BoardingPassState state,
    BoardingPassNotifier notifier,
  ) {
    if (state.isScanning) {
      return const Center(child: LoadingIndicator(message: '正在驗證 QR Code...'));
    }

    if (state.hasError) {
      return Center(
        child: ErrorDisplay(
          message: state.errorMessage!,
          onRetry: () => notifier.clearError(),
        ),
      );
    }

    if (state.scanResult != null) {
      return ScanResultDisplay(
        result: state.scanResult!,
        onClear: () => notifier.clearScanResult(),
      );
    }

    return _buildInstructionsCard(context);
  }

  /// Build instructions card
  Widget _buildInstructionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const Gap(8),
                Text(
                  '掃描說明',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Gap(16),

            _buildInstructionItem('1. 確保登機牌上的 QR Code 清晰可見', Icons.visibility),

            const Gap(8),

            _buildInstructionItem(
              '2. 將 QR Code 對準掃描框中央',
              Icons.center_focus_strong,
            ),

            const Gap(8),

            _buildInstructionItem('3. 保持穩定直到掃描成功', Icons.done),

            const Gap(16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withAlpha(77)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      '提示：在光線充足的環境下掃描效果更佳',
                      style: TextStyle(color: AppColors.warning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build instruction item
  Widget _buildInstructionItem(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const Gap(12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      ],
    );
  }

  /// Handle QR scan result
  void _handleQRScan(
    String qrData,
    BoardingPassNotifier notifier,
    ValueSetter<bool> setScanning,
  ) {
    setScanning(false);

    // Parse QR data (simplified implementation)
    final parts = qrData.split('|');
    if (parts.length >= 4) {
      notifier.validateQRCode(
        encryptedPayload: parts[0],
        checksum: parts[1],
        generatedAt: parts[2],
        version: int.tryParse(parts[3]) ?? 1,
      );
    } else {
      // Handle invalid QR format
      notifier.validateQRCode(
        encryptedPayload: qrData,
        checksum: 'invalid',
        generatedAt: DateTime.now().toIso8601String(),
        version: 1,
      );
    }
  }

  /// Check camera permission (mock implementation)
  Future<bool> _checkCameraPermission() async {
    // In real implementation, use permission_handler package
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Mock granted permission
  }

  /// Request camera permission (mock implementation)
  Future<bool> _requestCameraPermission() async {
    // In real implementation, use permission_handler package
    await Future.delayed(const Duration(milliseconds: 1000));
    return true; // Mock granted permission
  }
}
