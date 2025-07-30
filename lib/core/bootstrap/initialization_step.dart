import 'package:app/core/bootstrap/contracts/initialization_context.dart';

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
