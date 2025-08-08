import 'dart:async';
import 'dart:math';
import 'package:app/features/shared/domain/services/scanner_service.dart';
import 'package:logger/logger.dart';

/// Mock scanner service for testing and development
class MockScannerServiceImpl implements ScannerService {
  static final Logger _logger = Logger();

  final StreamController<String> _scanResultsController =
      StreamController<String>.broadcast();
  final StreamController<ScannerError> _errorsController =
      StreamController<ScannerError>.broadcast();

  bool _isScanning = false;
  bool _isDisposed = false;
  Timer? _scanTimer;
  Timer? _errorTimer;

  // Test configuration
  final Duration _scanDelay;
  final List<String> _mockQRCodes;
  final double _errorProbability;
  final bool _shouldFailStart;

  MockScannerServiceImpl({
    Duration scanDelay = const Duration(seconds: 2),
    List<String>? mockQRCodes,
    double errorProbability = 0.0,
    bool shouldFailStart = false,
  }) : _scanDelay = scanDelay,
       _mockQRCodes = mockQRCodes ?? _defaultMockQRCodes,
       _errorProbability = errorProbability,
       _shouldFailStart = shouldFailStart;

  static const List<String> _defaultMockQRCodes = [
    'https://example.com/boarding-pass/ABC123|checksum123|2024-01-15T10:30:00Z|1',
    'https://example.com/boarding-pass/DEF456|checksum456|2024-01-15T11:45:00Z|1',
    'https://example.com/boarding-pass/GHI789|checksum789|2024-01-15T14:20:00Z|1',
  ];

  @override
  Stream<String> get scanResults => _scanResultsController.stream;

  @override
  Stream<ScannerError> get errors => _errorsController.stream;

  @override
  bool get isScanning => _isScanning;

  @override
  bool get isReady => !_isScanning && !_isDisposed;

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<void> config([ScannerConfig? config]) async {
    _logger.d('Configurate mock scanner service');
  }

  @override
  Future<bool> start() async {
    if (_isDisposed) {
      _logger.w('Cannot start disposed mock scanner');
      return false;
    }

    if (_isScanning) {
      _logger.w('Mock scanner already running');
      return true;
    }

    try {
      _logger.d('Starting mock scanner service');

      // Simulate initialization delay
      await Future.delayed(const Duration(milliseconds: 500));

      if (_shouldFailStart) {
        throw Exception('Mock scanner configured to fail startup');
      }

      _isScanning = true;
      _startMockScanning();

      _logger.i('Mock scanner service started successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Mock scanner startup failed: $e \n $stackTrace');

      _errorsController.add(
        ScannerError.initialization(
          message: 'Mock scanner initialization failed',
          originalError: e,
        ),
      );

      return false;
    }
  }

  @override
  Future<void> stop() async {
    if (!_isScanning || _isDisposed) return;

    _logger.d('Stopping mock scanner service');

    _isScanning = false;
    _stopMockScanning();

    _logger.i('Mock scanner service stopped');
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;

    _logger.d('Disposing mock scanner service');

    _isDisposed = true;
    _isScanning = false;

    _stopMockScanning();

    await _scanResultsController.close();
    await _errorsController.close();

    _logger.i('Mock scanner service disposed');
  }

  /// Start mock scanning behavior
  void _startMockScanning() {
    _scanTimer = Timer.periodic(_scanDelay, (_) {
      if (_isDisposed || !_isScanning) return;

      // Randomly decide whether to emit scan result or error
      final random = Random();

      if (_errorProbability > 0 && random.nextDouble() < _errorProbability) {
        _emitMockError();
      } else {
        _emitMockScan();
      }
    });
  }

  /// Stop mock scanning behavior
  void _stopMockScanning() {
    _scanTimer?.cancel();
    _scanTimer = null;
    _errorTimer?.cancel();
    _errorTimer = null;
  }

  /// Emit mock scan result
  void _emitMockScan() {
    if (_isDisposed || !_isScanning) return;

    final random = Random();
    final mockData = _mockQRCodes[random.nextInt(_mockQRCodes.length)];

    _logger.i(
      'Mock scanner detected QR: ${mockData.substring(0, mockData.length.clamp(0, 50))}...',
    );
    _scanResultsController.add(mockData);
  }

  /// Emit mock error
  void _emitMockError() {
    if (_isDisposed) return;

    final errors = [
      ScannerError.scanning(message: 'Mock camera focus error'),
      ScannerError.hardware(message: 'Mock hardware unavailable'),
      ScannerError.scanning(message: 'Mock lighting conditions poor'),
    ];

    final random = Random();
    final error = errors[random.nextInt(errors.length)];

    _logger.w('Mock scanner error: ${error.toString()}');
    _errorsController.add(error);
  }

  // Public methods for test control

  /// Manually trigger a scan result (for testing)
  void simulateScan(String qrData) {
    if (_isDisposed) return;

    _logger.d('Manually triggering mock scan: $qrData');
    _scanResultsController.add(qrData);
  }

  /// Manually trigger an error (for testing)
  void simulateError(ScannerError error) {
    if (_isDisposed) return;

    _logger.d('Manually triggering mock error: ${error.toString()}');
    _errorsController.add(error);
  }

  /// Set custom mock QR codes for testing
  void setMockQRCodes(List<String> qrCodes) {
    _mockQRCodes.clear();
    _mockQRCodes.addAll(qrCodes);
  }
}
