import 'dart:io';
import 'package:app/features/boarding_pass/infrastructure/entities/boarding_pass_entity.dart';
import 'package:app/features/flight/infrastructure/entities/flight_entity.dart';
import 'package:app/features/member/infrastructure/entities/member_entity.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:app/objectbox.g.dart';

/// ObjectBox singleton class following official recommendations
/// Manages Store lifecycle with single instance pattern
class ObjectBox {
  static final Logger _logger = Logger();

  /// The ObjectBox Store instance
  late final Store store;

  /// Box accessors for all entities
  late final Box<MemberEntity> memberBox;
  late final Box<FlightEntity> flightBox;
  late final Box<BoardingPassEntity> boardingPassBox;

  ObjectBox._create(this.store) {
    // Initialize all boxes after store creation
    memberBox = store.box<MemberEntity>();
    flightBox = store.box<FlightEntity>();
    boardingPassBox = store.box<BoardingPassEntity>();
    _logger.i('ObjectBox store initialized successfully');
  }

  /// Create ObjectBox instance with proper initialization
  /// Should be called once in main() function
  static Future<ObjectBox> create() async {
    try {
      _logger.i('Initializing ObjectBox...');

      // Get application documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = path.join(docsDir.path, 'objectbox');

      // Open store with proper error handling
      final store = await openStore(directory: dbPath);

      _logger.i('ObjectBox store opened at: $dbPath');
      return ObjectBox._create(store);
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to initialize ObjectBox',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Close the store (typically called on app shutdown)
  void close() {
    store.close();
    _logger.i('ObjectBox store closed');
  }

  /// Reset database for testing purposes
  static Future<ObjectBox> createForTesting([String? testPath]) async {
    final testDbPath =
        testPath ?? 'test-objectbox-${DateTime.now().millisecondsSinceEpoch}';

    // Clean up existing test database
    final testDir = Directory(testDbPath);
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }

    final store = await openStore(directory: testDbPath);
    return ObjectBox._create(store);
  }

  /// Reset database for testing purposes
  static ObjectBox createFromStore(Store store) {
    return ObjectBox._create(store);
  }

  /// Cleanup test database
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
