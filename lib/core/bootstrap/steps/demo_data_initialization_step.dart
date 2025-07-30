import 'package:app/core/bootstrap/contracts/initialization_context.dart';
import 'package:app/core/bootstrap/initialization_step.dart';
import 'package:app/features/shared/infrastructure/database/mock_data_seeder.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

/// Seed demo data for development and testing
class DemoDataInitializationStep extends InitializationStep {
  const DemoDataInitializationStep()
    : super(name: 'Demo Data Seeding', isCritical: false);

  @override
  Future<void> execute(InitializationContext context) async {
    final objectBox = context.objectBox;
    if (objectBox == null) {
      _logger.w('ObjectBox not available, skipping demo data seeding');
      return;
    }

    final seeder = MockDataSeeder(objectBox);

    // Only seed if essential data is missing
    if (!await seeder.verifyEssentialData()) {
      await seeder.seedMinimalMockData();
      _logger.i('Demo data seeded successfully');
    } else {
      _logger.i('Essential data already exists, skipping seeding');
    }
  }
}
