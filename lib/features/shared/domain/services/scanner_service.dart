// lib/features/shared/domain/services/scanner_service.dart
import 'dart:async';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scanner_service.freezed.dart';

/// Scanner error types
@freezed
abstract class ScannerError with _$ScannerError {
  const factory ScannerError.permission({
    required String message,
    @Default(false) bool isPermanentlyDenied,
  }) = PermissionError;

  const factory ScannerError.hardware({
    required String message,
    String? details,
  }) = HardwareError;

  const factory ScannerError.initialization({
    required String message,
    Object? originalError,
  }) = InitializationError;

  const factory ScannerError.scanning({
    required String message,
    Object? originalError,
  }) = ScanningError;
}

/// Scanner service configuration
@freezed
abstract class ScannerConfig with _$ScannerConfig {
  const factory ScannerConfig({
    @Default(['qr']) List<String> formats,
    @Default('back') String facing,
    @Default(false) bool torchEnabled,
    @Default(false) bool returnImage,
  }) = _ScannerConfig;
}

/// Abstract scanner service interface
abstract class ScannerService {
  /// Stream of successful scan results
  Stream<String> get scanResults;

  /// Stream of scanner errors
  Stream<ScannerError> get errors;

  /// Current scanning status
  bool get isScanning;

  /// Whether scanner is ready to start
  bool get isReady;

  /// Configurate the scanner
  Future<void> config([ScannerConfig? config]);

  /// Start the scanner
  Future<bool> start();

  /// Stop the scanner
  Future<void> stop();

  /// Dispose all resources
  Future<void> dispose();

  /// Check if service is available on current platform
  Future<bool> get isAvailable;
}
