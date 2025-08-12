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
      _logger.w('ObjectBox not available, skipping demo data seeding');
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

      // Only seed if essential data is missing
      if (!await seeder.verifyEssentialData()) {
        await seeder.seedMinimalMockData();
        _logger.i('✅ Demo data seeded successfully');
      } else {
        _logger.i('✅ Essential data already exists, skipping seeding');
      }

      // Store seeder in context for later container-based sync
      context.setData('demo_data_seeder', seeder);
      context.setData('demo_data_ready', true);

      _logger.d('Demo data seeder stored in context for later sync');

      final diagnostics = seeder.getDatabaseDiagnostics();
      if (!diagnostics['allDataPresent']) {
        await seeder.forceFixDatabasePassIds();
      }
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
      _logger.i('🔄 Starting remote datasource sync...');

      final seeder = context.getData('demo_data_seeder') as MockDataSeeder?;
      final container = context.container;

      if (seeder == null) {
        _logger.w('Demo data seeder not found in context, skipping sync');
        return;
      }

      if (container == null) {
        _logger.w('Container not available, skipping remote sync');
        return;
      }

      // Get services from container
      final demoServices = container.read(demoServicesProvider);

      final entities = demoServices.objectBox.boardingPassBox.getAll();
      _logger.d(
        '📦 Found ${entities.length} boarding pass entities in local DB',
      );

      // Debug the actual PassIds in database
      final actualPassIds = entities.map((e) => e.passId).toList();
      final expectedPassIds = MockDataSeeder.getQRScannerPassIds();

      _logger.d('🎯 Expected PassIds: $expectedPassIds');
      _logger.d('📋 Actual PassIds in DB: $actualPassIds');

      if (entities.isEmpty) {
        _logger.w('❌ No boarding passes found in database, cannot sync remote');
        context.setData('demo_sync_error', 'No boarding passes in database');
        return;
      }

      // Convert entities to domain objects with error handling
      final domainObjects = <BoardingPass>[];
      for (final entity in entities) {
        try {
          final domainObject = entity.toDomain();
          domainObjects.add(domainObject);
          _logger.d('✅ Converted entity to domain: ${entity.passId}');
        } catch (e) {
          _logger.e(
            '❌ Failed to convert entity ${entity.passId} to domain: $e',
          );
        }
      }

      if (domainObjects.isEmpty) {
        _logger.w('❌ No valid domain objects after conversion');
        context.setData('demo_sync_error', 'Entity conversion failed');
        return;
      }

      // Initialize remote datasource with local data
      demoServices.mockRemoteDataSource.initializeWithTestData(domainObjects);
      demoServices.mockRemoteDataSource.clearUsedTokens();

      _logger.i(
        '✅ Remote datasource synced with ${domainObjects.length} boarding passes',
      );

      // Verify QR functionality with better error handling
      await _verifyQRFunctionalityFixed(seeder, actualPassIds, context);
    } catch (e, stackTrace) {
      _logger.e(
        'Remote datasource sync failed',
        error: e,
        stackTrace: stackTrace,
      );
      context.setData('demo_sync_error', e.toString());
    }
  }

  /// Fixed QR verification that works with actual data
  static Future<void> _verifyQRFunctionalityFixed(
    MockDataSeeder seeder,
    List<String> actualPassIds,
    InitializationContext context,
  ) async {
    try {
      _logger.d('🧪 Verifying QR functionality for actual PassIds...');

      final expectedPassIds = MockDataSeeder.getQRScannerPassIds();
      var allWorking = true;

      // Check which expected PassIds actually exist
      final existingExpectedPassIds = expectedPassIds
          .where((expected) => actualPassIds.contains(expected))
          .toList();

      _logger.d('🎯 Expected PassIds that exist: $existingExpectedPassIds');

      if (existingExpectedPassIds.isEmpty) {
        _logger.w('❌ None of the expected PassIds found in database');
        _logger.w('   Expected: $expectedPassIds');
        _logger.w('   Actual: $actualPassIds');
        context.setData('demo_qr_verified', false);
        return;
      }

      // Test QR functionality for existing PassIds
      for (final passId in existingExpectedPassIds) {
        _logger.d('🧪 Testing QR flow for existing PassId: $passId');

        try {
          final qrWorking = await seeder.testQRFlow(passId);
          if (!qrWorking) {
            _logger.w('❌ QR flow failed for PassId: $passId');
            allWorking = false;
          } else {
            _logger.d('✅ QR flow working for PassId: $passId');
          }
        } catch (e) {
          _logger.w('❌ QR test threw exception for $passId: $e');
          allWorking = false;
        }
      }

      // Also test any additional PassIds that exist but weren't expected
      final additionalPassIds = actualPassIds
          .where((actual) => !expectedPassIds.contains(actual))
          .toList();

      if (additionalPassIds.isNotEmpty) {
        _logger.d('🔍 Found additional PassIds: $additionalPassIds');

        for (final passId in additionalPassIds.take(3)) {
          // Test max 3 additional
          try {
            final qrWorking = await seeder.testQRFlow(passId);
            _logger.d(
              'Additional PassId $passId QR test: ${qrWorking ? '✅' : '❌'}',
            );
          } catch (e) {
            _logger.d('Additional PassId $passId QR test failed: $e');
          }
        }
      }

      if (allWorking && existingExpectedPassIds.isNotEmpty) {
        _logger.i('🎉 QR verification completed successfully!');
        _logger.i('   Working PassIds: $existingExpectedPassIds');
        context.setData('demo_qr_verified', true);
        context.setData('demo_working_pass_ids', existingExpectedPassIds);
      } else {
        _logger.w('⚠️ Some QR codes may not work correctly');
        context.setData('demo_qr_verified', false);
      }
    } catch (e, stackTrace) {
      _logger.e(
        'QR functionality verification failed',
        error: e,
        stackTrace: stackTrace,
      );
      context.setData('demo_qr_verified', false);
    }
  }
}
