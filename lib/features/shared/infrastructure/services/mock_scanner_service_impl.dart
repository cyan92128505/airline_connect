import 'dart:async';
import 'dart:math';
import 'package:app/features/shared/domain/services/scanner_service.dart';
import 'package:logger/logger.dart';

/// mock scanner service for testing with real QR codes
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

  // configuration for integration tests
  final bool _sequentialScanning;
  int _currentQRIndex = 0;

  MockScannerServiceImpl({
    Duration scanDelay = const Duration(seconds: 2),
    List<String>? mockQRCodes,
    double errorProbability = 0.0,
    bool shouldFailStart = false,
    bool sequentialScanning = false, // Scan QR codes in sequence
  }) : _scanDelay = scanDelay,
       _mockQRCodes = mockQRCodes ?? _defaultMockQRCodes,
       _errorProbability = errorProbability,
       _shouldFailStart = shouldFailStart,
       _sequentialScanning = sequentialScanning;

  static const List<String> _defaultMockQRCodes = [
    'FALLBACK_QR_CODE_1_FOR_TESTING',
    'FALLBACK_QR_CODE_2_FOR_TESTING',
    'FALLBACK_QR_CODE_3_FOR_TESTING',
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
    _logger.d('Configuring enhanced mock scanner service');
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
      _logger.d(
        'Starting enhanced mock scanner service with ${_mockQRCodes.length} QR codes',
      );

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

    _logger.d('Stopping enhanced mock scanner service');

    _isScanning = false;
    _stopMockScanning();

    _logger.i('Mock scanner service stopped');
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;

    _logger.d('Disposing enhanced mock scanner service');

    _isDisposed = true;
    _isScanning = false;

    _stopMockScanning();

    await _scanResultsController.close();
    await _errorsController.close();

    _logger.i('Mock scanner service disposed');
  }

  /// Start enhanced mock scanning behavior
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

  /// Emit mock scan result with enhanced logic
  void _emitMockScan() {
    if (_isDisposed || !_isScanning || _mockQRCodes.isEmpty) return;

    String mockData;

    if (_sequentialScanning) {
      // Scan QR codes in sequence for predictable testing
      mockData = _mockQRCodes[_currentQRIndex % _mockQRCodes.length];
      _currentQRIndex++;
    } else {
      // Random QR code selection
      final random = Random();
      mockData = _mockQRCodes[random.nextInt(_mockQRCodes.length)];
    }

    _logger.i('Mock scanner detected QR: ${_truncateQRCode(mockData)}');
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

  // 🔥 ENHANCED: Public methods for test control

  /// Manually trigger a scan result (for testing) - ENHANCED
  void simulateScan(String qrData) {
    if (_isDisposed) return;

    _logger.d(
      'Manually triggering enhanced mock scan: ${_truncateQRCode(qrData)}',
    );
    _scanResultsController.add(qrData);
  }

  /// Manually trigger an error (for testing)
  void simulateError(ScannerError error) {
    if (_isDisposed) return;

    _logger.d('Manually triggering mock error: ${error.toString()}');
    _errorsController.add(error);
  }

  /// Set custom mock QR codes for testing - ENHANCED
  void setMockQRCodes(List<String> qrCodes) {
    _mockQRCodes.clear();
    _mockQRCodes.addAll(qrCodes);
    _currentQRIndex = 0; // Reset sequence
    _logger.d('Updated mock QR codes: ${qrCodes.length} codes available');
  }

  /// Add a single QR code to the mock list
  void addMockQRCode(String qrCode) {
    _mockQRCodes.add(qrCode);
    _logger.d('Added mock QR code: ${_truncateQRCode(qrCode)}');
  }

  /// Get current QR codes for debugging
  List<String> get currentQRCodes => List.unmodifiable(_mockQRCodes);

  /// Reset sequence to start from beginning
  void resetSequence() {
    _currentQRIndex = 0;
    _logger.d('Reset QR code sequence');
  }

  /// Get next QR code in sequence without emitting
  String? getNextQRCode() {
    if (_mockQRCodes.isEmpty) return null;

    final qrCode = _mockQRCodes[_currentQRIndex % _mockQRCodes.length];
    _currentQRIndex++;
    return qrCode;
  }

  /// Simulate immediate scan (no delay)
  void scanImmediately([String? specificQRCode]) {
    if (_isDisposed) return;

    final qrCode = specificQRCode ?? getNextQRCode();
    if (qrCode != null) {
      _logger.d('Immediate scan: ${_truncateQRCode(qrCode)}');
      _scanResultsController.add(qrCode);
    }
  }

  /// Helper to truncate long QR codes for logging
  String _truncateQRCode(String qrCode, [int maxLength = 50]) {
    if (qrCode.length <= maxLength) return qrCode;
    return '${qrCode.substring(0, maxLength)}...';
  }

  /// Get scan statistics for debugging
  Map<String, dynamic> getScanStatistics() {
    return {
      'totalQRCodes': _mockQRCodes.length,
      'currentIndex': _currentQRIndex,
      'isScanning': _isScanning,
      'isDisposed': _isDisposed,
      'sequentialMode': _sequentialScanning,
      'errorProbability': _errorProbability,
      'scanDelay': _scanDelay.inMilliseconds,
    };
  }

  /// Create a test-specific scanner with predefined QR codes
  static MockScannerServiceImpl forIntegrationTest({
    required List<String> realQRCodes,
    Duration scanDelay = const Duration(milliseconds: 800),
    bool enableSequentialScanning = true,
  }) {
    return MockScannerServiceImpl(
      scanDelay: scanDelay,
      mockQRCodes: realQRCodes,
      errorProbability: 0.0, // No errors for integration tests
      shouldFailStart: false,
      sequentialScanning: enableSequentialScanning,
    );
  }
}
