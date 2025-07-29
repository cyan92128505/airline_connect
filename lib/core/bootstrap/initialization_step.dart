import 'package:app/features/shared/infrastructure/database/objectbox.dart';

/// Abstract base class for application initialization steps
/// Each step represents a discrete initialization operation
abstract class InitializationStep {
  const InitializationStep({required this.name, this.isCritical = true});

  /// Human-readable name of this initialization step
  final String name;

  /// Whether failure of this step should halt application startup
  final bool isCritical;

  /// Execute this initialization step
  /// Context allows steps to share data and dependencies
  Future<void> execute(InitializationContext context);
}

/// Context passed between initialization steps
/// Allows steps to share initialized resources and configuration
class InitializationContext {
  /// ObjectBox database instance (once initialized)
  ObjectBox? objectBox;

  /// Additional data that steps can use to communicate
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
