import 'package:app/di/dependency_injection.dart';
import 'package:app/features/boarding_pass/presentation/widgets/camera_error.dart';
import 'package:app/features/boarding_pass/presentation/widgets/camera_placeholder.dart';
import 'package:app/features/boarding_pass/presentation/widgets/qr_scanning_overlay.dart';
import 'package:app/features/boarding_pass/presentation/widgets/qr_status_overlay.dart';
import 'package:app/features/shared/domain/services/scanner_service.dart';
import 'package:app/features/shared/presentation/providers/qr_scanner_provider.dart';
import 'package:app/features/shared/infrastructure/services/mobile_scanner_service_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (scannerState.status == ScannerStatus.scanning ||
            scannerState.status == ScannerStatus.ready) {
          animationController.repeat(reverse: true);
        } else {
          animationController.stop();
        }
      });

      return null;
    }, [scannerState.status]);

    // Listen for scan results
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (scannerState.scannedData != null) {
          onScan(scannerState.scannedData!);
          scannerNotifier.clearResult();
        }
      });

      return null;
    }, [scannerState.scannedData]);
    // Auto-start scanner when view is mounted
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (scannerNotifier.canStart) {
          await scannerNotifier.startScanner();
        }
      });

      return () {
        scannerNotifier.stopScanner();
      };
    }, []);

    return Stack(
      children: [
        // Camera view or placeholder
        _buildCameraView(context, scannerState, scannerService, ref),

        // Scanning overlay frame
        QRScanningOverlay(animation),

        // Status overlay
        QRStatusOverlay(),
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
        if (scannerService.controller != null)
          MobileScanner(
            controller: scannerService.controller!,
            fit: BoxFit.cover,
            useAppLifecycleState: false,
            errorBuilder: (context, error) {
              return CameraError(error.toString());
            },
          ),

        if (!scannerState.shouldShowCamera) const CameraPlaceholder(),
      ],
    );
  }

  /// Build mock camera view for testing
  Widget _buildMockCameraView(
    BuildContext context,
    QRScannerState scannerState,
  ) {
    if (!scannerState.shouldShowCamera) {
      return const CameraPlaceholder();
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
}
