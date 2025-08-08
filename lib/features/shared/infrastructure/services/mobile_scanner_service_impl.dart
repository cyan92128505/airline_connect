import 'dart:async';
import 'package:app/features/shared/domain/services/scanner_service.dart';
import 'package:logger/logger.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Real scanner service implementation using mobile_scanner
class MobileScannerServiceImpl implements ScannerService {
  static final Logger _logger = Logger();

  final StreamController<String> _scanResultsController =
      StreamController<String>.broadcast();
  final StreamController<ScannerError> _errorsController =
      StreamController<ScannerError>.broadcast();

  MobileScannerController? _controller;
  StreamSubscription<BarcodeCapture>? _scanSubscription;
  bool _isScanning = false;
  bool _isDisposed = false;

  @override
  Stream<String> get scanResults => _scanResultsController.stream;

  @override
  Stream<ScannerError> get errors => _errorsController.stream;

  @override
  bool get isScanning => _isScanning;

  @override
  bool get isReady => _controller != null && !_isScanning && !_isDisposed;

  @override
  Future<bool> get isAvailable async {
    try {
      // Check if mobile_scanner is available on current platform
      return true; // mobile_scanner handles platform availability internally
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> config([ScannerConfig? config]) async {
    final effectiveConfig = config ?? const ScannerConfig();

    // Create controller with configuration
    _controller = MobileScannerController(
      formats: _mapFormats(effectiveConfig.formats),
      facing: _mapFacing(effectiveConfig.facing),
      torchEnabled: effectiveConfig.torchEnabled,
      returnImage: effectiveConfig.returnImage,
    );
  }

  @override
  Future<bool> start() async {
    if (_isDisposed) {
      _logger.w('Cannot start disposed scanner service');
      return false;
    }

    if (_isScanning) {
      _logger.w('Scanner already running');
      return true;
    }

    try {
      _logger.d('Starting mobile scanner service');

      // Listen for scan results
      _scanSubscription = _controller!.barcodes.listen(
        _handleBarcodeCapture,
        onError: _handleScanError,
      );

      // Start the scanner
      await _controller!.start();

      _isScanning = true;
      _logger.i('Mobile scanner service started successfully');

      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to start mobile scanner service: $e\n $stackTrace');

      await _cleanup();

      _errorsController.add(
        ScannerError.initialization(
          message: 'Failed to initialize camera scanner',
          originalError: e,
        ),
      );

      return false;
    }
  }

  @override
  Future<void> stop() async {
    if (!_isScanning || _isDisposed) return;

    try {
      _logger.d('Stopping mobile scanner service');

      _isScanning = false;
      await _cleanup();

      _logger.i('Mobile scanner service stopped');
    } catch (e, stackTrace) {
      _logger.e('Error stopping mobile scanner service: $e\n $stackTrace');

      _errorsController.add(
        ScannerError.scanning(
          message: 'Error stopping scanner',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;

    _logger.d('Disposing mobile scanner service');

    _isDisposed = true;
    _isScanning = false;

    await _cleanup();

    await _scanResultsController.close();
    await _errorsController.close();

    _logger.i('Mobile scanner service disposed');
  }

  /// Handle barcode capture from mobile scanner
  void _handleBarcodeCapture(BarcodeCapture capture) {
    if (_isDisposed || capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;

    if (rawValue == null || rawValue.isEmpty) {
      _logger.w('Received empty barcode data');
      return;
    }

    _logger.i(
      'Barcode detected: ${rawValue.substring(0, rawValue.length.clamp(0, 50))}...',
    );

    _scanResultsController.add(rawValue);
  }

  /// Handle scan errors from mobile scanner
  void _handleScanError(Object error, StackTrace stackTrace) {
    _logger.e('Mobile scanner error: $error\n $stackTrace');

    if (!_isDisposed) {
      _errorsController.add(
        ScannerError.scanning(
          message: 'Scanner encountered an error',
          originalError: error,
        ),
      );
    }
  }

  /// Cleanup scanner resources
  Future<void> _cleanup() async {
    try {
      await _scanSubscription?.cancel();
      _scanSubscription = null;

      if (_controller != null) {
        await _controller!.stop();
        await _controller!.dispose();
        _controller = null;
      }
    } catch (e) {
      _logger.e('Error during scanner cleanup: $e');
    }
  }

  /// Map string formats to BarcodeFormat
  List<BarcodeFormat> _mapFormats(List<String> formats) {
    return formats.map((format) {
      return switch (format.toLowerCase()) {
        'qr' => BarcodeFormat.qrCode,
        'code128' => BarcodeFormat.code128,
        'code39' => BarcodeFormat.code39,
        'ean13' => BarcodeFormat.ean13,
        'ean8' => BarcodeFormat.ean8,
        _ => BarcodeFormat.qrCode,
      };
    }).toList();
  }

  /// Map string facing to CameraFacing
  CameraFacing _mapFacing(String facing) {
    return switch (facing.toLowerCase()) {
      'front' => CameraFacing.front,
      'back' => CameraFacing.back,
      _ => CameraFacing.back,
    };
  }

  /// Get mobile scanner controller for UI integration (if needed)
  MobileScannerController? get controller => _controller;
}
