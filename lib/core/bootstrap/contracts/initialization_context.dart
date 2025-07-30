import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Context passed between initialization steps
/// Provides access to shared resources and allows data exchange
class InitializationContext {
  /// ObjectBox database instance (once initialized)
  ObjectBox? objectBox;

  /// Provider container for dependency injection
  ProviderContainer? container;

  /// Shared data storage for communication between steps
  final Map<String, dynamic> _data = {};

  /// Store arbitrary data for other steps to use
  void setData(String key, dynamic value) {
    _data[key] = value;
  }

  /// Retrieve data stored by previous steps
  T? getData<T>(String key) {
    return _data[key] as T?;
  }

  /// Check if specific data exists
  bool hasData(String key) {
    return _data.containsKey(key);
  }

  /// Get all stored data keys (for debugging)
  List<String> getDataKeys() {
    return _data.keys.toList();
  }

  /// Clear specific data entry
  void removeData(String key) {
    _data.remove(key);
  }

  /// Clear all stored data
  void clearData() {
    _data.clear();
  }

  /// Get summary of context state for logging
  Map<String, dynamic> getSummary() {
    return {
      'hasObjectBox': objectBox != null,
      'hasContainer': container != null,
      'dataKeys': getDataKeys(),
      'objectBoxHealthy': objectBox?.isHealthy() ?? false,
    };
  }
}

/// Exception thrown during application initialization
class InitializationException implements Exception {
  const InitializationException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  @override
  String toString() {
    if (originalError != null) {
      return 'InitializationException: $message\nCaused by: $originalError';
    }
    return 'InitializationException: $message';
  }
}
