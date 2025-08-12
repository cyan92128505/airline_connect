import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:app/features/boarding_pass/presentation/notifiers/boarding_pass_notifier.dart';
import 'package:app/features/boarding_pass/presentation/widgets/loading_state_view.dart';
import 'package:app/features/boarding_pass/presentation/widgets/permission_error_view.dart';
import 'package:app/features/boarding_pass/presentation/widgets/qr_scanner_view.dart';
import 'package:app/features/boarding_pass/presentation/widgets/results_area_view.dart';
import 'package:app/features/boarding_pass/presentation/widgets/scanner_error_view.dart';
import 'package:app/features/boarding_pass/presentation/widgets/start_scanner_button.dart';
import 'package:app/features/shared/presentation/providers/camera_permission_provider.dart';
import 'package:app/features/shared/presentation/providers/qr_scanner_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// QR Scanner screen for validating boarding passes
class QRScannerScreen extends HookConsumerWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraPermissionState = ref.watch(cameraPermissionProvider);
    final scannerState = ref.watch(qRScannerProvider);

    final boardingPassNotifier = ref.read(
      boardingPassNotifierProvider.notifier,
    );
    final cameraPermissionNotifier = ref.read(
      cameraPermissionProvider.notifier,
    );
    final scannerNotifier = ref.read(qRScannerProvider.notifier);

    // Check permission status on mount
    // Handle QR scan results
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scannerState.scannedData != null) {
          boardingPassNotifier.handleQRScan(scannerState.scannedData!);
        }
      });
      return null;
    }, [scannerState.scannedData]);

    useEffect(() {
      return Future(() async {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await cameraPermissionNotifier.setup();
          await scannerNotifier.setupPermission();
          await scannerNotifier.setupScannerContorller();
        });
      }).ignore;
    }, []);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(scannerState.appBarTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => boardingPassNotifier.handleClearAction(),
            icon: const Icon(Icons.clear),
            tooltip: '清除結果',
          ),
        ],
      ),
      body: Column(
        children: [
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
              child: const ResultsAreaView(),
            ),
          ),
        ],
      ),
    );
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
      return const PermissionErrorView();
    }

    // Show scanner error if needed
    if (scannerState.status == ScannerStatus.error) {
      return ScannerErrorView();
    }

    // Show loading state
    if (permissionState.isRequesting || scannerState.isBusy) {
      return LoadingStateView();
    }

    // Show scanner view or start button
    if (scannerState.shouldShowCamera) {
      return QRScannerView(
        onScan: (data) {
          // QRScannerView handles scan internally via provider
        },
      );
    }

    return const StartScannerButton();
  }
}
