import 'package:app/di/dependency_injection.dart';
import 'package:app/features/shared/domain/services/scanner_service.dart';
import 'package:app/features/shared/presentation/providers/qr_scanner_provider.dart';
import 'package:app/features/shared/infrastructure/services/mobile_scanner_service_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app/core/presentation/theme/app_colors.dart';

class QRScannerView extends HookConsumerWidget {
  final Function(String) onScan;

  const QRScannerView({super.key, required this.onScan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(qRScannerProvider);
    final scannerNotifier = ref.read(qRScannerProvider.notifier);
    final scannerService = ref.watch(scannerServiceProvider);

    // Animation controller for scanning line
    final animationController = useAnimationController(
      duration: const Duration(seconds: 2),
    );

    final animation = useAnimation(
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
      ),
    );

    // Start animation when scanning
    useEffect(() {
      if (scannerState.status == ScannerStatus.scanning ||
          scannerState.status == ScannerStatus.ready) {
        animationController.repeat(reverse: true);
      } else {
        animationController.stop();
      }
      return null;
    }, [scannerState.status]);

    // Listen for scan results
    useEffect(() {
      if (scannerState.scannedData != null) {
        onScan(scannerState.scannedData!);
        scannerNotifier.clearResult();
      }
      return null;
    }, [scannerState.scannedData]);
    // Auto-start scanner when view is mounted
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (scannerNotifier.canStart) {
          await scannerNotifier.setupScannerContorller();
        }
      });

      return () {
        // Cleanup when widget is disposed
        scannerNotifier.stopScanner();
      };
    }, []);
    return Stack(
      children: [
        // Camera view or placeholder
        _buildCameraView(context, scannerState, scannerService, ref),

        // Scanning overlay frame
        _buildScanningOverlay(context, animation, scannerState),

        // Status overlay
        _buildStatusOverlay(context, scannerState),
      ],
    );
  }

  /// Build camera view based on environment and scanner state
  Widget _buildCameraView(
    BuildContext context,
    QRScannerState scannerState,
    ScannerService scannerService,
    WidgetRef ref,
  ) {
    if (scannerService is MobileScannerServiceImpl) {
      return _buildRealCameraView(context, scannerState, scannerService, ref);
    } else {
      return _buildMockCameraView(context, scannerState);
    }
  }

  /// Build real camera view using MobileScanner
  Widget _buildRealCameraView(
    BuildContext context,
    QRScannerState scannerState,
    MobileScannerServiceImpl scannerService,
    WidgetRef ref,
  ) {
    return Stack(
      children: [
        MobileScanner(
          controller: scannerService.controller,
          fit: BoxFit.cover,
          useAppLifecycleState: false,
          errorBuilder: (context, error) {
            return _buildCameraError(context, error.toString());
          },
        ),

        if (!scannerState.shouldShowCamera)
          _buildCameraPlaceholder(context, scannerState),
      ],
    );
  }

  /// Build mock camera view for testing
  Widget _buildMockCameraView(
    BuildContext context,
    QRScannerState scannerState,
  ) {
    if (!scannerState.shouldShowCamera) {
      return _buildCameraPlaceholder(context, scannerState);
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Mock camera feed (animated gradient to simulate movement)
          _buildMockCameraFeed(),

          // Mock scanning indicator
          if (scannerState.status == ScannerStatus.scanning)
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(108),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '模擬相機掃描中...',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build mock camera feed with animated background
  Widget _buildMockCameraFeed() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 3),
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, value, 1.0],
              colors: [Colors.grey[900]!, Colors.grey[800]!, Colors.grey[900]!],
            ),
          ),
        );
      },
    );
  }

  /// Build camera placeholder
  Widget _buildCameraPlaceholder(
    BuildContext context,
    QRScannerState scannerState,
  ) {
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

  /// Build camera error view
  Widget _buildCameraError(BuildContext context, String error) {
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
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                '相機錯誤',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white..withAlpha(128),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build scanning overlay frame
  Widget _buildScanningOverlay(
    BuildContext context,
    double animation,
    QRScannerState scannerState,
  ) {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Corner indicators
            ...List.generate(4, (index) {
              return Positioned(
                top: index < 2 ? 8 : null,
                bottom: index >= 2 ? 8 : null,
                left: index % 2 == 0 ? 8 : null,
                right: index % 2 == 1 ? 8 : null,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.primary, width: 3),
                      left: BorderSide(color: AppColors.primary, width: 3),
                    ),
                  ),
                  transform: Matrix4.identity()
                    ..rotateZ(index * 1.5708), // 90 degrees rotation per corner
                ),
              );
            }),

            // Animated scanning line (only when actively scanning)
            if (scannerState.status == ScannerStatus.scanning ||
                scannerState.status == ScannerStatus.ready)
              Positioned(
                left: 0,
                right: 0,
                top: animation * 220 + 15,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success..withAlpha(128),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build status overlay
  Widget _buildStatusOverlay(
    BuildContext context,
    QRScannerState scannerState,
  ) {
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
          _getStatusMessage(scannerState),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  /// Get status message based on scanner state
  String _getStatusMessage(QRScannerState scannerState) {
    return switch (scannerState.status) {
      ScannerStatus.ready => '將 QR Code 對準掃描框\n保持穩定等待掃描',
      ScannerStatus.scanning => '正在掃描 QR Code...',
      ScannerStatus.processing => '正在處理掃描結果...',
      ScannerStatus.initializing => '正在初始化相機，請稍候...',
      ScannerStatus.permissionRequired => '需要相機權限才能掃描',
      ScannerStatus.error => scannerState.errorMessage ?? '掃描器發生錯誤',
      ScannerStatus.completed => '掃描完成！',
      ScannerStatus.inactive => '點擊開始掃描按鈕開始掃描',
    };
  }
}
