import 'dart:io';
import 'package:app/features/boarding_pass/infrastructure/entities/boarding_pass_entity.dart';
import 'package:app/features/flight/infrastructure/entities/flight_entity.dart';
import 'package:app/features/member/infrastructure/entities/member_entity.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:app/objectbox.g.dart';

class ObjectBox {
  static final Logger _logger = Logger();

  Store? _store;

  Box<MemberEntity>? _memberBox;
  Box<FlightEntity>? _flightBox;
  Box<BoardingPassEntity>? _boardingPassBox;

  ObjectBox._();

  Store get store {
    if (_store == null || _store!.isClosed()) {
      throw StateError('ObjectBox store is not initialized or closed');
    }
    return _store!;
  }

  Box<MemberEntity> get memberBox {
    if (_memberBox == null) {
      _memberBox = store.box<MemberEntity>();
      _logger.d('Member box initialized lazily');
    }
    return _memberBox!;
  }

  Box<FlightEntity> get flightBox {
    if (_flightBox == null) {
      _flightBox = store.box<FlightEntity>();
      _logger.d('Flight box initialized lazily');
    }
    return _flightBox!;
  }

  Box<BoardingPassEntity> get boardingPassBox {
    if (_boardingPassBox == null) {
      _boardingPassBox = store.box<BoardingPassEntity>();
      _logger.d('BoardingPass box initialized lazily');
    }
    return _boardingPassBox!;
  }

  /// Create ObjectBox instance with completely safe initialization
  static Future<ObjectBox> create() async {
    try {
      _logger.i('Initializing ObjectBox with safe strategy...');

      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(docsDir.path, 'objectbox');

      // Ensure directory exists
      final dbDir = Directory(dbPath);
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }

      // Open store with retries
      Store? store;
      int retryCount = 0;
      const maxRetries = 3;

      while (store == null && retryCount < maxRetries) {
        try {
          store = await openStore(directory: dbPath);
          _logger.i(
            'ObjectBox store opened successfully on attempt ${retryCount + 1}',
          );
        } catch (e) {
          retryCount++;
          _logger.w('Store open attempt $retryCount failed: $e');

          if (retryCount < maxRetries) {
            // Wait before retry
            await Future.delayed(Duration(milliseconds: 100 * retryCount));

            // Try to clean up corrupted database
            if (retryCount == 2) {
              await _cleanupCorruptedDatabase(dbPath);
            }
          } else {
            rethrow;
          }
        }
      }

      if (store == null) {
        throw StateError(
          'Failed to initialize ObjectBox store after $maxRetries attempts',
        );
      }

      // Create ObjectBox instance
      final objectBox = ObjectBox._();
      objectBox._store = store;

      // Validate initialization with retry mechanism
      await _validateInitialization(objectBox);

      _logger.i('ObjectBox initialized successfully at: $dbPath');
      return objectBox;
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to initialize ObjectBox',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Validate initialization with multiple checks
  static Future<void> _validateInitialization(ObjectBox objectBox) async {
    final maxAttempts = 5;
    int attempt = 0;

    while (attempt < maxAttempts) {
      try {
        // Test store accessibility
        if (objectBox._store!.isClosed()) {
          throw StateError('Store is closed during validation');
        }

        // Test each box with minimal operations
        objectBox.memberBox.isEmpty();
        objectBox.flightBox.isEmpty();
        objectBox.boardingPassBox.isEmpty();

        _logger.i('ObjectBox validation passed on attempt ${attempt + 1}');
        return;
      } catch (e) {
        attempt++;
        _logger.w('Validation attempt $attempt failed: $e');

        if (attempt < maxAttempts) {
          // Reset boxes for retry
          objectBox._memberBox = null;
          objectBox._flightBox = null;
          objectBox._boardingPassBox = null;

          await Future.delayed(Duration(milliseconds: 50 * attempt));
        } else {
          throw StateError(
            'ObjectBox validation failed after $maxAttempts attempts: $e',
          );
        }
      }
    }
  }

  /// Clean up potentially corrupted database
  static Future<void> _cleanupCorruptedDatabase(String dbPath) async {
    try {
      _logger.w('Attempting to clean up corrupted database at: $dbPath');

      final dbDir = Directory(dbPath);
      if (await dbDir.exists()) {
        await dbDir.delete(recursive: true);
        _logger.i('Corrupted database cleaned up');
      }
    } catch (e) {
      _logger.e('Failed to cleanup corrupted database: $e');
    }
  }

  /// Close the store safely
  void close() {
    try {
      _store?.close();
      _store = null;
      _memberBox = null;
      _flightBox = null;
      _boardingPassBox = null;
      _logger.i('ObjectBox store closed safely');
    } catch (e) {
      _logger.e('Error closing ObjectBox store: $e');
    }
  }

  /// Health check with comprehensive validation
  bool isHealthy() {
    try {
      if (_store == null || _store!.isClosed()) {
        return false;
      }

      // Test basic operations without forcing initialization
      if (_memberBox != null) {
        _memberBox!.isEmpty();
      }
      if (_flightBox != null) {
        _flightBox!.isEmpty();
      }
      if (_boardingPassBox != null) {
        _boardingPassBox!.isEmpty();
      }

      return true;
    } catch (e) {
      _logger.w('ObjectBox health check failed: $e');
      return false;
    }
  }

  /// Setup demo member with enhanced error handling
  void setupDemoMember() {
    try {
      if (_store == null || _store!.isClosed()) {
        throw StateError('Cannot setup demo data: store not available');
      }

      // Use transaction for safety
      store.runInTransaction(TxMode.write, () {
        memberBox.removeAll();

        final testMember = MemberEntity()
          ..memberNumber = 'AA123456'
          ..fullName = 'Shinku Aoma'
          ..email = 'test@example.com'
          ..phone = '+886912345678'
          ..tier = 'GOLD'
          ..lastLoginAt = DateTime.now();

        memberBox.put(testMember);
      });

      _logger.i('Demo member setup completed successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to setup demo member',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get comprehensive statistics
  Map<String, dynamic> getStatistics() {
    if (_store == null || _store!.isClosed()) {
      return {'status': 'not_initialized'};
    }

    try {
      return {
        'status': 'healthy',
        'storeOpen': !_store!.isClosed(),
        'memberBoxInit': _memberBox != null,
        'flightBoxInit': _flightBox != null,
        'boardingPassBoxInit': _boardingPassBox != null,
        'memberCount': _memberBox?.count() ?? 'N/A',
        'flightCount': _flightBox?.count() ?? 'N/A',
        'boardingPassCount': _boardingPassBox?.count() ?? 'N/A',
      };
    } catch (e) {
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Testing methods
  static Future<ObjectBox> createForTesting([String? testPath]) async {
    final testDbPath =
        testPath ?? 'test-objectbox-${DateTime.now().millisecondsSinceEpoch}';

    final testDir = Directory(testDbPath);
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }

    final store = await openStore(directory: testDbPath);
    final objectBox = ObjectBox._();
    objectBox._store = store;

    await _validateInitialization(objectBox);
    return objectBox;
  }

  static ObjectBox createFromStore(Store store) {
    if (store.isClosed()) {
      throw StateError('Cannot create ObjectBox from closed store');
    }

    final objectBox = ObjectBox._();
    objectBox._store = store;
    return objectBox;
  }

  static Future<void> cleanupTest(
    ObjectBox objectBox, [
    String? testPath,
  ]) async {
    objectBox.close();
    final testDbPath = testPath ?? 'test-objectbox';
    final testDir = Directory(testDbPath);
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  }
}
