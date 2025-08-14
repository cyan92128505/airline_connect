import 'dart:async';
import 'package:app/di/dependency_injection.dart';
import 'package:app/features/shared/infrastructure/services/mobile_scanner_service_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/services/scanner_service.dart';
import 'camera_permission_provider.dart';

part 'qr_scanner_provider.freezed.dart';
part 'qr_scanner_provider.g.dart';

/// QR Scanner status
enum ScannerStatus {
  inactive, // Scanner not initialized
  permissionRequired, // Camera permission needed
  initializing, // Scanner initializing
  ready, // Ready to scan
  scanning, // Actively scanning
  processing, // Processing scanned data
  completed, // Scan completed successfully
  error, // Error occurred
}

/// Provider for scanner service configuration
@riverpod
ScannerConfig scannerConfig(Ref<ScannerConfig> ref) {
  return const ScannerConfig(
    formats: ['qr'],
    facing: 'back',
    torchEnabled: false,
    returnImage: false,
  );
}

/// State for QR scanner management
@freezed
abstract class QRScannerState with _$QRScannerState {
  const factory QRScannerState({
    @Default(ScannerStatus.inactive) ScannerStatus status,
    @Default(false) bool isPermissionBlocked,
    String? scannedData,
    String? errorMessage,
    DateTime? lastScanTime,
    @Default(0) int scanCount,
  }) = _QRScannerState;

  const QRScannerState._();

  /// Whether scanner is actively running
  bool get isActive =>
      status == ScannerStatus.scanning || status == ScannerStatus.ready;

  /// Whether scanner can be started
  bool get canStart =>
      status == ScannerStatus.inactive || status == ScannerStatus.error;

  /// Whether we should show camera view
  bool get shouldShowCamera =>
      status == ScannerStatus.ready ||
      status == ScannerStatus.scanning ||
      status == ScannerStatus.processing;

  /// Whether we should show permission UI
  bool get shouldShowPermissionUI => status == ScannerStatus.permissionRequired;

  /// Whether scanner is busy (initializing or processing)
  bool get isBusy =>
      status == ScannerStatus.initializing ||
      status == ScannerStatus.processing;

  /// Get user-friendly status description
  String get statusDescription {
    return switch (status) {
      ScannerStatus.inactive => '掃描器未啟動',
      ScannerStatus.permissionRequired => '需要相機權限',
      ScannerStatus.initializing => '正在初始化相機...',
      ScannerStatus.ready => '準備就緒，等待掃描',
      ScannerStatus.scanning => '正在掃描 QR Code...',
      ScannerStatus.processing => '正在處理掃描結果...',
      ScannerStatus.completed => '掃描完成',
      ScannerStatus.error => '掃描器錯誤',
    };
  }

  String get appBarTitle {
    return switch (status) {
      ScannerStatus.scanning => 'QR Code 掃描中...',
      ScannerStatus.processing => '處理掃描結果...',
      ScannerStatus.completed => 'QR Code 掃描完成',
      ScannerStatus.error => 'QR Code 掃描器錯誤',
      _ => 'QR Code 掃描器',
    };
  }

  /// Get instruction icon based on scanner state
  IconData get instructionIcon {
    return switch (status) {
      ScannerStatus.ready || ScannerStatus.scanning => Icons.qr_code_scanner,
      ScannerStatus.completed => Icons.check_circle_outline,
      ScannerStatus.error => Icons.error_outline,
      _ => Icons.info_outline,
    };
  }

  /// Get instruction title based on scanner state and environment
  String get instructionTitle {
    return switch (status) {
      ScannerStatus.ready || ScannerStatus.scanning => '掃描進行中',
      ScannerStatus.completed => '掃描完成',
      ScannerStatus.error => '掃描錯誤',
      _ => '掃描說明',
    };
  }

  List<String> get instructionItems {
    final items = <String>[];

    if (status == ScannerStatus.ready || status == ScannerStatus.scanning) {
      items.addAll(['保持 QR Code 清晰可見', '將 QR Code 對準掃描框中央', '保持穩定直到掃描成功']);
    } else {
      items.addAll(['確保登機證上的 QR Code 清晰可見', '在光線充足的環境下掃描效果更佳', '掃描時請保持手機穩定']);
    }

    return items;
  }

  String get statusMessage {
    return switch (status) {
      ScannerStatus.ready => '將 QR Code 對準掃描框\n保持穩定等待掃描',
      ScannerStatus.scanning => '正在掃描 QR Code...',
      ScannerStatus.processing => '正在處理掃描結果...',
      ScannerStatus.initializing => '正在初始化相機，請稍候...',
      ScannerStatus.permissionRequired => '需要相機權限才能掃描',
      ScannerStatus.error => errorMessage ?? '掃描器發生錯誤',
      ScannerStatus.completed => '掃描完成！',
      ScannerStatus.inactive => '點擊開始掃描按鈕開始掃描',
    };
  }
}

/// Provider for QR scanner state and operations
@riverpod
class QRScanner extends _$QRScanner {
  static final Logger _logger = Logger();
  Completer? _completer;
  StreamSubscription<String>? _scanSubscription;
  StreamSubscription<ScannerError>? _errorSubscription;
  bool _isDisposed = false;

  @override
  QRScannerState build() {
    _completer = Completer();

    // Setup cleanup on dispose
    ref.onDispose(() {
      _completer = null;
      _dispose();
    });

    // Start listening to scanner service once it's available
    _setupServiceListeners();

    return const QRScannerState();
  }

  /// Setup listeners for scanner service streams
  void _setupServiceListeners() {
    final scannerService = ref.read(scannerServiceProvider);

    // Listen for scan results
    _scanSubscription = scannerService.scanResults.listen(
      _handleScanResult,
      onError: (error, stackTrace) {
        _logger.e('Scan result stream error: $error, /n$stackTrace');
      },
    );

    // Listen for errors
    _errorSubscription = scannerService.errors.listen(
      _handleScannerError,
      onError: (error, stackTrace) {
        _logger.e('Scanner error stream error: $error/n$stackTrace');
      },
    );
  }

  /// Setup camera permission monitoring
  Future<void> setupPermission() async {
    final cameraPermission = ref.read(cameraPermissionProvider);

    // Handle permission state changes
    if (cameraPermission.isGranted) {
      if (state.isPermissionBlocked) {
        state = state.copyWith(
          status: ScannerStatus.inactive,
          isPermissionBlocked: false,
          errorMessage: null,
        );
      }
    } else if (!cameraPermission.isGranted && state.shouldShowCamera) {
      _logger.w('Camera permission lost, stopping scanner');
      await stopScanner();
      state = state.copyWith(
        status: ScannerStatus.permissionRequired,
        isPermissionBlocked: true,
        errorMessage: cameraPermission.errorMessage,
      );
    }
  }

  Future<void> setupScannerContorller() async {
    // Check camera permission first
    final cameraPermission = ref.read(cameraPermissionProvider);
    if (!cameraPermission.isGranted) {
      _logger.w('Camera permission not granted, requesting...');
      final granted = await ref
          .read(cameraPermissionProvider.notifier)
          .requestPermission();

      if (!granted) {
        _logger.w('Camera permission denied, cannot start scanner');
        state = state.copyWith(
          status: ScannerStatus.permissionRequired,
          isPermissionBlocked: true,
          errorMessage: cameraPermission.errorMessage,
        );
        return;
      }
    }

    final scannerService = ref.read(scannerServiceProvider);
    final config = ref.read(scannerConfigProvider);
    await scannerService.config(config);
    _completer!.complete();
  }

  /// Start QR scanner
  Future<bool> startScanner() async {
    state = state.copyWith(status: ScannerStatus.ready);

    final scannerService = ref.read(scannerServiceProvider);
    if (scannerService is MobileScannerServiceImpl &&
        scannerService.controller == null) {
      final config = ref.read(scannerConfigProvider);
      await scannerService.config(config);
    }

    await _completer!.future;
    return _startScannerService();
  }

  /// Stop QR scanner
  Future<void> stopScanner() async {
    final scannerService = ref.read(scannerServiceProvider);
    await scannerService.stop();

    state = state.copyWith(status: ScannerStatus.inactive, errorMessage: null);
  }

  /// Clear scan result and reset to ready state
  void clearResult() {
    state = state.copyWith(
      scannedData: null,
      errorMessage: null,
      status: state.shouldShowCamera
          ? ScannerStatus.ready
          : ScannerStatus.inactive,
    );
  }

  /// Reset scanner to initial state
  Future<void> reset() async {
    await stopScanner();
    state = const QRScannerState();
  }

  /// Start the scanner service
  Future<bool> _startScannerService() async {
    try {
      state = state.copyWith(
        status: ScannerStatus.initializing,
        errorMessage: null,
      );

      final scannerService = ref.read(scannerServiceProvider);

      final success = await scannerService.start();

      if (success && !_isDisposed) {
        state = state.copyWith(status: ScannerStatus.ready);

        // Start scanning
        await Future.delayed(const Duration(milliseconds: 200));
        if (!_isDisposed && state.status == ScannerStatus.ready) {
          state = state.copyWith(status: ScannerStatus.scanning);
        }
      }

      return success;
    } catch (e, stackTrace) {
      _logger.e('Error starting QR scanner: $e/n$stackTrace');

      if (!_isDisposed) {
        state = state.copyWith(
          status: ScannerStatus.error,
          errorMessage: 'Failed to start scanner: $e',
        );
      }

      return false;
    }
  }

  /// Handle scan result from service
  void _handleScanResult(String scanData) {
    if (_isDisposed) return;

    _logger.i(
      'QR code detected: ${scanData.substring(0, scanData.length.clamp(0, 50))}...',
    );

    state = state.copyWith(status: ScannerStatus.processing);

    // Process the scanned data
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed) {
        state = state.copyWith(
          scannedData: scanData,
          lastScanTime: DateTime.now(),
          scanCount: state.scanCount + 1,
          status: ScannerStatus.completed,
          errorMessage: null,
        );

        // Auto-stop scanning after successful scan
        stopScanner();
      }
    });
  }

  /// Handle scanner error from service
  void _handleScannerError(ScannerError error) {
    if (_isDisposed) return;

    _logger.e('Scanner service error: ${error.toString()}');

    final errorMessage = error.when(
      permission: (message, isPermanentlyDenied) => message,
      hardware: (message, details) => message,
      initialization: (message, originalError) => message,
      scanning: (message, originalError) => message,
    );

    state = state.copyWith(
      status: ScannerStatus.error,
      errorMessage: errorMessage,
    );
  }

  /// Dispose all resources
  void _dispose() {
    _isDisposed = true;
    _scanSubscription?.cancel();
    _scanSubscription = null;

    _errorSubscription?.cancel();
    _errorSubscription = null;

    // The scanner service will be disposed by Riverpod automatically
  }

  // Getter to expose canStart for external use
  bool get canStart => state.canStart;
}
