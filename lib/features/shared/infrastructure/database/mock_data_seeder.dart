import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';
import 'package:app/features/boarding_pass/domain/services/qr_code_service.dart';
import 'package:app/features/boarding_pass/domain/value_objects/flight_schedule_snapshot.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:app/features/boarding_pass/domain/value_objects/seat_number.dart';
import 'package:app/features/boarding_pass/infrastructure/entities/boarding_pass_entity.dart';
import 'package:app/features/flight/domain/value_objects/airport_code.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:app/features/flight/domain/value_objects/gate.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:app/features/member/infrastructure/entities/member_entity.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:app/objectbox.g.dart';
import 'package:logger/logger.dart';
import 'package:timezone/timezone.dart' as tz;

class MockDataSeeder {
  static final Logger _logger = Logger();
  final ObjectBox _objectBox;
  final QRCodeService _qrCodeService;

  MockDataSeeder({
    required ObjectBox objectBox,
    required QRCodeService qrCodeService,
  }) : _objectBox = objectBox,
       _qrCodeService = qrCodeService;

  /// Seed minimal mock data needed for QR code validation
  Future<void> seedMinimalMockData() async {
    try {
      _logger.i('Seeding minimal mock data with real QR codes...');

      // Only seed the essential data for QR code validation
      await _seedEssentialMembers();
      await _seedEssentialBoardingPasses();

      _logger.i('Minimal mock data seeding completed successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to seed minimal mock data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Seed only the members needed for testing
  Future<void> _seedEssentialMembers() async {
    final essentialMembers = [
      _createMemberEntity('AA123456', 'Shinku Aoma'),
      _createMemberEntity('AA654321', 'John Doe'),
      _createMemberEntity('BB987654', 'Alice Chen'),
    ];

    _objectBox.store.runInTransaction(TxMode.write, () {
      for (final member in essentialMembers) {
        final existing = _objectBox.memberBox
            .query(MemberEntity_.memberNumber.equals(member.memberNumber))
            .build()
            .findFirst();

        if (existing == null) {
          _objectBox.memberBox.put(member);
          _logger.d('Created member: ${member.memberNumber}');
        } else {
          _logger.d('Member already exists: ${member.memberNumber}');
        }
      }
    });
  }

  /// Seed boarding passes using real QRCodeService
  Future<void> _seedEssentialBoardingPasses() async {
    final now = tz.TZDateTime.now(tz.local);

    // Create boarding passes that will work with QR validation
    final boardingPassesToCreate = [
      {
        'passId': 'BPW3AHOV29',
        'memberNumber': 'AA123456',
        'flightNumber': 'CI123',
        'seatNumber': '12A',
        'description': 'Primary demo boarding pass',
      },
      {
        'passId': 'BPA1B2C3D4',
        'memberNumber': 'AA654321',
        'flightNumber': 'CI456',
        'seatNumber': '15C',
        'description': 'Secondary demo boarding pass',
      },
      {
        'passId': 'BP12345678',
        'memberNumber': 'BB987654',
        'flightNumber': 'BR857',
        'seatNumber': '8F',
        'description': 'Test boarding pass for QR scanner',
      },
    ];

    // 🔥 NEW: Use individual transactions instead of one big transaction
    for (final passData in boardingPassesToCreate) {
      try {
        _logger.d('🔨 Creating boarding pass: ${passData['passId']}');

        // Check if already exists
        final existing = _objectBox.boardingPassBox
            .query(BoardingPassEntity_.passId.equals(passData['passId']!))
            .build()
            .findFirst();

        if (existing != null) {
          _logger.d('✅ Boarding pass already exists: ${passData['passId']}');
          continue;
        }

        // 🔥 Create in separate transaction for better error isolation
        _objectBox.store.runInTransaction(TxMode.write, () {
          try {
            final boardingPassEntity = _createWorkingBoardingPassEntity(
              passId: passData['passId']!,
              memberNumber: passData['memberNumber']!,
              flightNumber: passData['flightNumber']!,
              seatNumber: passData['seatNumber']!,
              baseTime: now,
            );

            final id = _objectBox.boardingPassBox.put(boardingPassEntity);
            _logger.d(
              '✅ Created boarding pass with ID $id: ${passData['passId']}',
            );

            // 🔥 Immediate verification within same transaction
            final verification = _objectBox.boardingPassBox.get(id);
            if (verification == null) {
              throw Exception('Failed to retrieve just-created boarding pass');
            }

            _logger.d('🔍 Verified creation: ${verification.passId}');
          } catch (e, stackTrace) {
            _logger.e(
              '💥 Error creating boarding pass ${passData['passId']}: $e',
              error: e,
              stackTrace: stackTrace,
            );
            rethrow;
          }
        });

        _logger.i(
          '✅ Successfully created: ${passData['passId']} - ${passData['description']}',
        );
      } catch (e, stackTrace) {
        _logger.e(
          '❌ Failed to create boarding pass ${passData['passId']}: $e',
          error: e,
          stackTrace: stackTrace,
        );
        // Continue with next pass instead of failing completely
      }
    }

    // 🔥 NEW: Post-creation verification
    _logger.d('🔍 Post-creation verification...');
    final allPasses = _objectBox.boardingPassBox.getAll();
    _logger.d('📊 Total boarding passes in DB: ${allPasses.length}');

    for (final passData in boardingPassesToCreate) {
      final found = _objectBox.boardingPassBox
          .query(BoardingPassEntity_.passId.equals(passData['passId']!))
          .build()
          .findFirst();

      if (found != null) {
        _logger.d('✅ Verified in DB: ${passData['passId']}');
      } else {
        _logger.e('❌ Missing from DB: ${passData['passId']}');
      }
    }
  }

  /// Create member entity with minimal data
  MemberEntity _createMemberEntity(String memberNumber, String fullName) {
    return MemberEntity()
      ..memberNumber = memberNumber
      ..fullName = fullName
      ..email = '${fullName.toLowerCase().replaceAll(' ', '.')}@example.com'
      ..phone = '+886912345678'
      ..tier = 'GOLD'
      ..lastLoginAt = DateTime.now();
  }

  /// Create boarding pass entity using REAL QRCodeService

  BoardingPassEntity _createWorkingBoardingPassEntity({
    required String passId,
    required String memberNumber,
    required String flightNumber,
    required String seatNumber,
    required tz.TZDateTime baseTime,
  }) {
    try {
      _logger.d('🏗️ Creating domain objects for pass: $passId');

      // Create domain objects with validation
      final domainPassId = PassId.fromString(passId);
      final domainMemberNumber = MemberNumber.create(memberNumber);
      final domainFlightNumber = FlightNumber.create(flightNumber);
      final domainSeatNumber = SeatNumber.create(seatNumber);

      _logger.d('✅ Domain objects created for pass: $passId');

      // Set times for realistic boarding window
      final boardingTime = baseTime.add(Duration(hours: 1, minutes: 30));
      final departureTime = baseTime.add(Duration(hours: 2, minutes: 30));
      final snapshotTime = baseTime.subtract(Duration(minutes: 30));

      // Create flight schedule snapshot
      final scheduleSnapshot = FlightScheduleSnapshot(
        departureTime: departureTime,
        boardingTime: boardingTime,
        departure: AirportCode.create('TPE'),
        arrival: AirportCode.create('NRT'),
        gate: Gate.create('A12'),
        snapshotTime: snapshotTime,
      );

      _logger.d('📅 Flight schedule created for pass: $passId');

      // 🔥 Generate QR code with detailed error handling
      _logger.d('🔐 Generating QR code for pass: $passId');

      final qrCodeResult = _qrCodeService.generate(
        passId: domainPassId,
        flightNumber: domainFlightNumber.value,
        seatNumber: domainSeatNumber.value,
        memberNumber: domainMemberNumber.value,
        departureTime: departureTime,
      );

      final qrCode = qrCodeResult.fold(
        (failure) {
          final errorMsg =
              'QR generation failed for $passId: ${failure.message}';
          _logger.e(errorMsg);
          throw Exception(errorMsg);
        },
        (qrCode) {
          _logger.d('✅ QR code generated successfully for pass: $passId');
          return qrCode;
        },
      );

      // Create domain boarding pass
      final domainBoardingPass = BoardingPass.fromPersistence(
        passId: passId,
        memberNumber: memberNumber,
        flightNumber: flightNumber,
        seatNumber: seatNumber,
        scheduleSnapshot: scheduleSnapshot,
        status: PassStatus.activated, // Make it activated for demo
        qrCode: qrCode,
        issueTime: baseTime.subtract(Duration(hours: 2)),
        activatedAt: baseTime.subtract(Duration(hours: 1)),
      );

      _logger.d('🎫 Domain boarding pass created for: $passId');

      // 🔥 Convert to entity with error handling
      try {
        final entity = BoardingPassEntity.fromDomain(domainBoardingPass);
        _logger.d('🔄 Entity conversion successful for: $passId');
        return entity;
      } catch (e, stackTrace) {
        _logger.e(
          'Entity conversion failed for $passId: $e',
          error: e,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    } catch (e, stackTrace) {
      final errorMsg =
          'Failed to create working boarding pass entity for $passId: $e';
      _logger.e(errorMsg, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Generate a REAL working QR string for testing
  String? generateWorkingQRString(String passId) {
    try {
      _logger.d('🔐 Generating QR string for PassId: $passId');

      // Get entity with detailed debugging
      final entity = _objectBox.boardingPassBox
          .query(BoardingPassEntity_.passId.equals(passId))
          .build()
          .findFirst();

      if (entity == null) {
        _logger.w('❌ Boarding pass entity not found: $passId');

        // 🔥 DEBUG: List all available PassIds
        final allEntities = _objectBox.boardingPassBox.getAll();
        final availablePassIds = allEntities.map((e) => e.passId).toList();
        _logger.w('📋 Available PassIds: $availablePassIds');

        return null;
      }

      _logger.d('✅ Found entity for PassId: $passId');

      // Convert entity back to domain object
      final domainBoardingPass = entity.toDomain();

      // Return the REAL working QR string
      final qrString = domainBoardingPass.qrCode.toQRString();
      _logger.d(
        '✅ Generated QR string for $passId (length: ${qrString.length})',
      );

      return qrString;
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Failed to generate QR string for $passId: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Test the end-to-end QR flow
  Future<bool> testQRFlow(String passId) async {
    try {
      _logger.i('🧪 Testing end-to-end QR flow for: $passId');

      // 🔥 FIX: Add detailed debugging for entity retrieval
      _logger.d('🔍 Searching for boarding pass entity with PassId: $passId');

      // Try different query approaches to debug
      final allEntities = _objectBox.boardingPassBox.getAll();
      _logger.d('📊 Total entities in box: ${allEntities.length}');

      if (allEntities.isNotEmpty) {
        final allPassIds = allEntities.map((e) => e.passId).toList();
        _logger.d('📋 All PassIds in database: $allPassIds');

        // Check if our target exists
        final hasExactMatch = allPassIds.contains(passId);
        _logger.d('🎯 Exact match for $passId: $hasExactMatch');
      }

      // 1. Get the entity using query
      final entity = _objectBox.boardingPassBox
          .query(BoardingPassEntity_.passId.equals(passId))
          .build()
          .findFirst();

      if (entity == null) {
        _logger.e('❌ Boarding pass entity not found: $passId');
        return false;
      }

      _logger.d('✅ Found boarding pass entity: ${entity.passId}');

      // 2. Convert to domain object with error handling
      BoardingPass domainBoardingPass;
      try {
        domainBoardingPass = entity.toDomain();
        _logger.d('✅ Successfully converted entity to domain object');
      } catch (e, stackTrace) {
        _logger.e(
          '❌ Failed to convert entity to domain: $e',
          error: e,
          stackTrace: stackTrace,
        );
        return false;
      }

      // 3. Get QR string with error handling
      String qrString;
      try {
        qrString = domainBoardingPass.qrCode.toQRString();
        _logger.d(
          '✅ Successfully generated QR string (length: ${qrString.length})',
        );
        _logger.d(
          '🔐 QR string preview: ${qrString.length > 50 ? '${qrString.substring(0, 50)}...' : qrString}',
        );
      } catch (e, stackTrace) {
        _logger.e(
          '❌ Failed to generate QR string: $e',
          error: e,
          stackTrace: stackTrace,
        );
        return false;
      }

      // 4. Parse QR string (simulate scanning)
      QRCodeData qrData;
      try {
        qrData = QRCodeData.fromQRString(qrString);
        _logger.d('✅ Successfully parsed QR string');
      } catch (e, stackTrace) {
        _logger.e(
          '❌ Failed to parse QR string: $e',
          error: e,
          stackTrace: stackTrace,
        );
        return false;
      }

      // 5. Validate using real service
      try {
        final validationResult = _qrCodeService.validate(qrData);

        return validationResult.fold(
          (failure) {
            _logger.e('❌ QR validation failed: ${failure.message}');
            return false;
          },
          (result) {
            if (result.isValid) {
              _logger.i(
                '✅ QR validation passed! PassID: ${result.payload?.passId}',
              );
              return true;
            } else {
              _logger.w('❌ QR validation failed: ${result.reason}');
              return false;
            }
          },
        );
      } catch (e, stackTrace) {
        _logger.e(
          '❌ QR validation threw exception: $e',
          error: e,
          stackTrace: stackTrace,
        );
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e(
        '❌ QR flow test failed with exception: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get the PassIds used by QR scanner
  static List<String> getQRScannerPassIds() {
    return [
      'BP12345678', // Primary test PassId for QR scanner
      'BPW3AHOV29', // Demo PassId 1
      'BPA1B2C3D4', // Demo PassId 2
    ];
  }

  /// Verify that required data exists and QR codes work
  Future<bool> verifyEssentialData() async {
    try {
      _logger.i('🔍 Verifying essential data and QR functionality...');

      // 🔥 First, log database state
      final totalMembers = _objectBox.memberBox.count();
      final totalBoardingPasses = _objectBox.boardingPassBox.count();

      _logger.d('📊 Database state:');
      _logger.d('   - Total members: $totalMembers');
      _logger.d('   - Total boarding passes: $totalBoardingPasses');

      // 🔥 Log all existing PassIds for debugging
      final allPasses = _objectBox.boardingPassBox.getAll();
      final existingPassIds = allPasses.map((p) => p.passId).toList();
      _logger.d('   - Existing PassIds: $existingPassIds');

      final passIds = getQRScannerPassIds();
      var allValid = true;

      _logger.d('🎯 Checking required PassIds: $passIds');

      for (final passId in passIds) {
        _logger.d('🔍 Checking PassId: $passId');

        // Check boarding pass exists
        final boardingPass = _objectBox.boardingPassBox
            .query(BoardingPassEntity_.passId.equals(passId))
            .build()
            .findFirst();

        if (boardingPass == null) {
          _logger.w('❌ Missing boarding pass: $passId');
          allValid = false;
          continue;
        } else {
          _logger.d('✅ Found boarding pass: $passId');
        }

        // Check member exists
        final member = _objectBox.memberBox
            .query(MemberEntity_.memberNumber.equals(boardingPass.memberNumber))
            .build()
            .findFirst();

        if (member == null) {
          _logger.w(
            '❌ Missing member for pass: $passId (member: ${boardingPass.memberNumber})',
          );
          allValid = false;
          continue;
        } else {
          _logger.d(
            '✅ Found member: ${boardingPass.memberNumber} for pass: $passId',
          );
        }

        // Test QR functionality
        _logger.d('🧪 Testing QR flow for: $passId');
        final qrWorking = await testQRFlow(passId);
        if (!qrWorking) {
          _logger.w('❌ QR flow failed for pass: $passId');
          allValid = false;
        } else {
          _logger.d('✅ QR flow working for pass: $passId');
        }
      }

      if (allValid) {
        _logger.i('✅ All essential data verified and QR codes working!');
      } else {
        _logger.w('⚠️ Some data verification failed');

        // 🔥 Additional debugging info
        _logger.d('🔧 Debug info for troubleshooting:');
        _logger.d('   - Required PassIds: $passIds');
        _logger.d('   - Found PassIds: $existingPassIds');

        final missingPassIds = passIds
            .where((id) => !existingPassIds.contains(id))
            .toList();
        if (missingPassIds.isNotEmpty) {
          _logger.w('   - Missing PassIds: $missingPassIds');
        }
      }

      return allValid;
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Data verification failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Clean up test data
  Future<void> cleanupData() async {
    try {
      _logger.i('🧹 Cleaning up test data...');

      final passIds = getQRScannerPassIds();
      final memberNumbers = ['AA123456', 'AA654321', 'BB987654'];

      _objectBox.store.runInTransaction(TxMode.write, () {
        // Remove boarding passes
        for (final passId in passIds) {
          final existing = _objectBox.boardingPassBox
              .query(BoardingPassEntity_.passId.equals(passId))
              .build()
              .findFirst();
          if (existing != null) {
            _objectBox.boardingPassBox.remove(existing.id);
            _logger.d('Removed boarding pass: $passId');
          }
        }

        // Remove members
        for (final memberNumber in memberNumbers) {
          final existing = _objectBox.memberBox
              .query(MemberEntity_.memberNumber.equals(memberNumber))
              .build()
              .findFirst();
          if (existing != null) {
            _objectBox.memberBox.remove(existing.id);
            _logger.d('Removed member: $memberNumber');
          }
        }
      });

      _logger.i('✅ Cleanup completed');
    } catch (e) {
      _logger.e('❌ Cleanup failed: $e');
    }
  }

  /// Get demo statistics for UI display
  Map<String, dynamic> getDemoStats() {
    final totalMembers = _objectBox.memberBox.count();
    final totalBoardingPasses = _objectBox.boardingPassBox.count();
    final activeBoardingPasses = _objectBox.boardingPassBox
        .query(BoardingPassEntity_.status.equals('activated'))
        .build()
        .count();

    return {
      'totalMembers': totalMembers,
      'totalBoardingPasses': totalBoardingPasses,
      'activeBoardingPasses': activeBoardingPasses,
      'qrScannerPassIds': getQRScannerPassIds(),
    };
  }

  /// 🔍 Diagnostic method to check database state
  Map<String, dynamic> getDatabaseDiagnostics() {
    try {
      _logger.i('🔍 Running database diagnostics...');

      final allMembers = _objectBox.memberBox.getAll();
      final allBoardingPasses = _objectBox.boardingPassBox.getAll();

      final memberNumbers = allMembers.map((m) => m.memberNumber).toList();
      final passIds = allBoardingPasses.map((bp) => bp.passId).toList();

      final expectedPassIds = getQRScannerPassIds();
      final missingPassIds = expectedPassIds
          .where((id) => !passIds.contains(id))
          .toList();
      final extraPassIds = passIds
          .where((id) => !expectedPassIds.contains(id))
          .toList();

      final diagnostics = {
        'totalMembers': allMembers.length,
        'totalBoardingPasses': allBoardingPasses.length,
        'memberNumbers': memberNumbers,
        'actualPassIds': passIds,
        'expectedPassIds': expectedPassIds,
        'missingPassIds': missingPassIds,
        'extraPassIds': extraPassIds,
        'allDataPresent': missingPassIds.isEmpty,
      };

      // Log comprehensive diagnostics
      _logger.i('''
🔍 Database Diagnostics:
   📊 Totals:
      - Members: ${diagnostics['totalMembers']}
      - Boarding Passes: ${diagnostics['totalBoardingPasses']}
   
   👥 Member Numbers: ${memberNumbers.join(', ')}
   
   🎫 PassIds:
      - Expected: ${expectedPassIds.join(', ')}
      - Actual: ${passIds.join(', ')}
      - Missing: ${missingPassIds.isEmpty ? 'None' : missingPassIds.join(', ')}
      - Extra: ${extraPassIds.isEmpty ? 'None' : extraPassIds.join(', ')}
   
   ✅ All Expected Data Present: ${diagnostics['allDataPresent']}
''');

      return diagnostics;
    } catch (e, stackTrace) {
      _logger.e(
        '❌ Database diagnostics failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'error': e.toString(),
        'totalMembers': 0,
        'totalBoardingPasses': 0,
        'allDataPresent': false,
      };
    }
  }

  /// 🔧 Force fix database if PassIds don't match
  Future<bool> forceFixDatabasePassIds() async {
    try {
      _logger.i('🔧 Attempting to force fix database PassIds...');

      final diagnostics = getDatabaseDiagnostics();
      final missingPassIds = diagnostics['missingPassIds'] as List<String>;

      if (missingPassIds.isEmpty) {
        _logger.i('✅ No missing PassIds, database is correct');
        return true;
      }

      _logger.w('🔨 Found missing PassIds: $missingPassIds');
      _logger.i('🔄 Attempting to recreate missing data...');

      // Clear all existing data first
      await cleanupData();

      // Re-seed everything
      await seedMinimalMockData();

      // Verify the fix
      final newDiagnostics = getDatabaseDiagnostics();
      final stillMissingPassIds =
          newDiagnostics['missingPassIds'] as List<String>;

      if (stillMissingPassIds.isEmpty) {
        _logger.i('✅ Database fix successful!');
        return true;
      } else {
        _logger.e('❌ Database fix failed, still missing: $stillMissingPassIds');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Force fix failed: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}
