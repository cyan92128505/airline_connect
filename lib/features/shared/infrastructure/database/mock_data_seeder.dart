import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';
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

  MockDataSeeder(this._objectBox);

  /// Seed minimal mock data needed for QR code validation
  Future<void> seedMinimalMockData() async {
    try {
      _logger.i('Seeding minimal mock data...');

      // Only seed the essential data for QR code validation
      await _seedEssentialMembers();
      await _seedEssentialBoardingPasses();

      _logger.i('Minimal mock data seeding completed');
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
        }
      }
    });
  }

  /// Seed boarding passes using actual domain structure
  Future<void> _seedEssentialBoardingPasses() async {
    final now = tz.TZDateTime.now(tz.local);

    // Create boarding passes that will work with QR validation
    final boardingPassesToCreate = [
      {
        'passId': 'BPW3AHOV29',
        'memberNumber': 'AA123456',
        'flightNumber': 'CI123',
        'seatNumber': '12A',
      },
      {
        'passId': 'BPA1B2C3D4',
        'memberNumber': 'AA654321',
        'flightNumber': 'CI456',
        'seatNumber': '15C',
      },
    ];

    _objectBox.store.runInTransaction(TxMode.write, () {
      for (final passData in boardingPassesToCreate) {
        final existing = _objectBox.boardingPassBox
            .query(BoardingPassEntity_.passId.equals(passData['passId']!))
            .build()
            .findFirst();

        if (existing == null) {
          final boardingPassEntity = _createBoardingPassEntity(
            passData['passId']!,
            passData['memberNumber']!,
            passData['flightNumber']!,
            passData['seatNumber']!,
            now,
          );

          _objectBox.boardingPassBox.put(boardingPassEntity);
          _logger.d('Created boarding pass: ${passData['passId']}');
        }
      }
    });
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

  /// Create boarding pass entity using domain objects
  BoardingPassEntity _createBoardingPassEntity(
    String passId,
    String memberNumber,
    String flightNumber,
    String seatNumber,
    tz.TZDateTime baseTime,
  ) {
    try {
      // Create domain objects
      final domainPassId = PassId.fromString(passId);
      final domainMemberNumber = MemberNumber.create(memberNumber);
      final domainFlightNumber = FlightNumber.create(flightNumber);
      final domainSeatNumber = SeatNumber.create(seatNumber);

      // Set times for boarding window
      final boardingTime = baseTime.subtract(Duration(minutes: 30));
      final departureTime = baseTime.add(Duration(minutes: 30));
      final snapshotTime = baseTime.subtract(Duration(hours: 1));

      // Create flight schedule snapshot using actual constructor
      final scheduleSnapshot = FlightScheduleSnapshot(
        departureTime: departureTime,
        boardingTime: boardingTime,
        departure: AirportCode.create('TPE'),
        arrival: AirportCode.create('NRT'),
        gate: Gate.create('A12'),
        snapshotTime: snapshotTime,
      );

      // Generate QR code
      final qrCode = QRCodeData.generate(
        passId: domainPassId,
        flightNumber: domainFlightNumber,
        seatNumber: domainSeatNumber,
        memberNumber: domainMemberNumber,
        departureTime: departureTime,
      );

      // Create domain boarding pass
      final domainBoardingPass = BoardingPass.fromPersistence(
        passId: passId,
        memberNumber: memberNumber,
        flightNumber: flightNumber,
        seatNumber: seatNumber,
        scheduleSnapshot: scheduleSnapshot,
        status: PassStatus.activated, // Make it activated so it can be used
        qrCode: qrCode,
        issueTime: baseTime.subtract(Duration(hours: 2)),
        activatedAt: baseTime.subtract(Duration(hours: 1)),
      );

      // Convert to entity
      return BoardingPassEntity()
        ..passId = domainBoardingPass.passId.value
        ..memberNumber = domainBoardingPass.memberNumber.value
        ..flightNumber = domainBoardingPass.flightNumber.value
        ..seatNumber = domainBoardingPass.seatNumber.value
        ..status = domainBoardingPass.status.name
        ..issueTime = domainBoardingPass.issueTime.toUtc()
        ..activatedAt = domainBoardingPass.activatedAt?.toUtc()
        ..usedAt = domainBoardingPass.usedAt?.toUtc()
        // Store minimal schedule data
        ..departureAirport = scheduleSnapshot.departure.value
        ..arrivalAirport = scheduleSnapshot.arrival.value
        ..departureTime = scheduleSnapshot.departureTime.toUtc()
        ..boardingTime = scheduleSnapshot.boardingTime.toUtc()
        ..gateNumber = scheduleSnapshot.gate.value
        ..scheduleSnapshotTime = scheduleSnapshot.snapshotTime.toUtc()
        // Store QR code data
        ..qrCodeEncryptedPayload = qrCode.encryptedPayload
        ..qrCodeChecksum = qrCode.checksum
        ..qrCodeGeneratedAt = qrCode.generatedAt.toUtc()
        ..qrCodeVersion = qrCode.version;
    } catch (e) {
      _logger.e('Failed to create boarding pass entity: $e');
      rethrow;
    }
  }

  /// Get the PassIds used by QR scanner
  static List<String> getQRScannerPassIds() {
    return [
      'BP12345678', // Primary test PassId
      'BPW3AHOV29',
      'BPA1B2C3D4',
    ];
  }

  /// Verify that required data exists
  Future<bool> verifyEssentialData() async {
    try {
      final passIds = getQRScannerPassIds();

      for (final passId in passIds) {
        final boardingPass = _objectBox.boardingPassBox
            .query(BoardingPassEntity_.passId.equals(passId))
            .build()
            .findFirst();

        if (boardingPass == null) {
          _logger.w('Missing boarding pass: $passId');
          return false;
        }

        // Verify member exists
        final member = _objectBox.memberBox
            .query(MemberEntity_.memberNumber.equals(boardingPass.memberNumber))
            .build()
            .findFirst();

        if (member == null) {
          _logger.w('Missing member for pass: $passId');
          return false;
        }
      }

      return true;
    } catch (e) {
      _logger.e('Data verification failed: $e');
      return false;
    }
  }

  /// Clean up test data
  Future<void> cleanupData() async {
    try {
      final passIds = getQRScannerPassIds();
      final memberNumbers = ['AA123456', 'AA654321'];

      _objectBox.store.runInTransaction(TxMode.write, () {
        // Remove boarding passes
        for (final passId in passIds) {
          final existing = _objectBox.boardingPassBox
              .query(BoardingPassEntity_.passId.equals(passId))
              .build()
              .findFirst();
          if (existing != null) {
            _objectBox.boardingPassBox.remove(existing.id);
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
          }
        }
      });

      _logger.i('Cleanup completed');
    } catch (e) {
      _logger.e('Cleanup failed: $e');
    }
  }
}
