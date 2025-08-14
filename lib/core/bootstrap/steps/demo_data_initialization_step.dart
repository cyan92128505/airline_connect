import 'package:app/core/bootstrap/contracts/initialization_context.dart';
import 'package:app/core/bootstrap/initialization_step.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/infrastructure/services/crypto_service_impl.dart';
import 'package:app/features/boarding_pass/infrastructure/services/qr_code_service_impl.dart';
import 'package:app/features/shared/infrastructure/database/mock_data_seeder.dart';
import 'package:app/di/dependency_injection.dart';
import 'package:flutter/foundation.dart';
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
      _logger.w(' ObjectBox not available, skipping demo data seeding');
      return;
    }

    try {
      final cryptoService = CryptoServiceImpl();
      final config = kDebugMode ? MockQRCodeConfig() : ProductionQRCodeConfig();
      final qrCodeService = QRCodeServiceImpl(cryptoService, config);

      final seeder = MockDataSeeder(
        objectBox: objectBox,
        qrCodeService: qrCodeService,
      );

      await seeder.resetToStandardData();

      // Store seeder in context for later container-based sync
      context.setData('demo_data_seeder', seeder);
      context.setData('demo_data_ready', true);
    } catch (e, stackTrace) {
      _logger.e(
        'Demo data initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      // Non-critical, continue app initialization
    }
  }

  /// Static method to perform remote sync after container is available
  static Future<void> syncRemoteDataSource(
    InitializationContext context,
  ) async {
    try {
      final seeder = context.getData('demo_data_seeder') as MockDataSeeder?;
      final container = context.container;

      if (seeder == null) {
        _logger.w(' Demo data seeder not found in context, skipping sync');
        return;
      }

      if (container == null) {
        _logger.w(' Container not available, skipping remote sync');
        return;
      }

      // Get services from container
      final demoServices = container.read(demoServicesProvider);

      final entities = demoServices.objectBox.boardingPassBox.getAll();
      if (entities.isEmpty) {
        _logger.w(' No boarding passes found in database, cannot sync remote');
        context.setData('demo_sync_error', 'No boarding passes in database');
        return;
      }

      // Convert entities to domain objects with error handling
      final domainObjects = <BoardingPass>[];
      for (final entity in entities) {
        try {
          final domainObject = entity.toDomain();
          domainObjects.add(domainObject);
        } catch (e) {
          _logger.e(' Failed to convert entity ${entity.passId} to domain: $e');
        }
      }

      if (domainObjects.isEmpty) {
        _logger.w(' No valid domain objects after conversion');
        context.setData('demo_sync_error', 'Entity conversion failed');
        return;
      }

      // Initialize remote datasource with local data
      demoServices.mockRemoteDataSource.initializeWithTestData(domainObjects);
      demoServices.mockRemoteDataSource.clearUsedTokens();
    } catch (e, stackTrace) {
      _logger.e(
        'Remote datasource sync failed',
        error: e,
        stackTrace: stackTrace,
      );
      context.setData('demo_sync_error', e.toString());
    }
  }
}
