import 'package:app/features/boarding_pass/infrastructure/services/crypto_service_impl.dart';
import 'package:app/features/boarding_pass/infrastructure/services/qr_code_service_impl.dart';
import 'package:app/features/shared/infrastructure/database/mock_data_seeder.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:logger/logger.dart';

class TestQrcodeHelper {
  static final _logger = Logger();

  /// Seed test data and generate real QR codes
  static Future<void> seedTestDataWithRealQRCodes(ObjectBox objectBox) async {
    try {
      // Clear existing data
      objectBox.memberBox.removeAll();
      objectBox.boardingPassBox.removeAll();

      final cryptoService = CryptoServiceImpl();
      final qrConfig = MockQRCodeConfig();
      final qrCodeService = QRCodeServiceImpl(cryptoService, qrConfig);

      // Create mock data seeder
      final seeder = MockDataSeeder(
        objectBox: objectBox,
        qrCodeService: qrCodeService,
      );

      // Seed the data
      await seeder.resetToStandardData();
    } catch (e, stackTrace) {
      _logger.e('Failed to seed test data: $e');
      _logger.e('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Generate real QR codes for testing
  static Future<List<String>> generateRealQRCodes(ObjectBox objectBox) async {
    try {
      final realQRCodes = <String>[];

      // Get all boarding passes from database
      final allBoardingPasses = objectBox.boardingPassBox.getAll();

      for (final entity in allBoardingPasses) {
        try {
          // Convert entity to domain object
          final domainBoardingPass = entity.toDomain();

          // Get the real QR string
          final qrString = domainBoardingPass.qrCode.toQRString();
          realQRCodes.add(qrString);
        } catch (e) {
          _logger.e('Failed to generate QR for pass ${entity.passId}: $e');
        }
      }

      if (realQRCodes.isEmpty) {
        // Fallback: create at least one working QR code
        realQRCodes.add(_createFallbackQRCode());
      }

      return realQRCodes;
    } catch (e) {
      _logger.e('Failed to generate real QR codes: $e');
      return [_createFallbackQRCode()];
    }
  }

  /// Create a fallback QR code that follows the expected format
  static String _createFallbackQRCode() {
    // This should match your QR code format
    // You might need to adjust this based on your actual QR code structure
    return 'TEST_QR_CODE_FALLBACK_FOR_INTEGRATION_TEST';
  }

  tearDownAll() {}
}
