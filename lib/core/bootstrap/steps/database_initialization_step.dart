import 'package:app/core/bootstrap/initialization_step.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

/// Initialize ObjectBox database with validation
class DatabaseInitializationStep extends InitializationStep {
  const DatabaseInitializationStep()
    : super(name: 'Database Initialization', isCritical: true);

  @override
  Future<void> execute(InitializationContext context) async {
    final objectBox = await ObjectBox.create();

    // Validate store state immediately after creation
    if (objectBox.store.isClosed()) {
      throw StateError('ObjectBox store failed to initialize properly');
    }

    // Test database accessibility with all required boxes
    await _validateDatabaseAccess(objectBox);

    // Store initialized database in context
    context.objectBox = objectBox;

    _logger.i('ObjectBox database initialized and validated successfully');
  }

  /// Validate that all required database boxes are accessible
  Future<void> _validateDatabaseAccess(ObjectBox objectBox) async {
    try {
      // Test basic operations on all critical boxes
      objectBox.memberBox.isEmpty();
      objectBox.flightBox.isEmpty();
      objectBox.boardingPassBox.isEmpty();

      _logger.d('All database boxes are accessible');
    } catch (e) {
      // Clean up on validation failure
      objectBox.close();
      throw StateError('Database boxes are not accessible: $e');
    }
  }
}
