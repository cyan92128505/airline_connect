import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';
import 'package:app/features/boarding_pass/domain/services/qr_code_service.dart';
import 'package:app/features/boarding_pass/domain/value_objects/flight_schedule_snapshot.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
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

  Future<void> resetToStandardData() async {
    try {
      await _clearAllData();
      await _createStandardMembers();
      await _createStandardBoardingPasses();
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to reset to standard data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _clearAllData() async {
    _objectBox.store.runInTransaction(TxMode.write, () {
      _objectBox.boardingPassBox.removeAll();
      _objectBox.memberBox.removeAll();
    });
  }

  Future<void> _createStandardMembers() async {
    final members = [
      _StandardMemberData(
        memberNumber: 'AA123456',
        fullName: 'Shinku Aoma',
        email: 'shinku.aoma@example.com',
        phone: '+886912345678',
        tier: 'GOLD',
      ),
    ];

    _objectBox.store.runInTransaction(TxMode.write, () {
      for (final memberData in members) {
        final entity = MemberEntity()
          ..memberNumber = memberData.memberNumber
          ..fullName = memberData.fullName
          ..email = memberData.email
          ..phone = memberData.phone
          ..tier = memberData.tier
          ..lastLoginAt = tz.TZDateTime.now(tz.local);

        _objectBox.memberBox.put(entity);
      }
    });
  }

  Future<void> _createStandardBoardingPasses() async {
    final now = tz.TZDateTime.now(tz.local);

    final boardingPasses = [
      _StandardBoardingPassData(
        passId: 'BP12345678',
        memberNumber: 'AA123456',
        flightNumber: 'CI123',
        seatNumber: '12A',
        departureCode: 'TPE',
        arrivalCode: 'NRT',
        gate: 'A12',
        baseTime: now,
      ),
      _StandardBoardingPassData(
        passId: 'BPA1B2C3D4',
        memberNumber: 'AA123456',
        flightNumber: 'CI456',
        seatNumber: '15C',
        departureCode: 'TPE',
        arrivalCode: 'ICN',
        gate: 'B5',
        baseTime: now.add(Duration(days: 1)),
      ),
    ];

    for (final passData in boardingPasses) {
      _objectBox.store.runInTransaction(TxMode.write, () {
        final entity = _createBoardingPassEntity(passData);
        _objectBox.boardingPassBox.put(entity);
      });
    }
  }

  BoardingPassEntity _createBoardingPassEntity(_StandardBoardingPassData data) {
    final domainPassId = PassId.fromString(data.passId);
    final domainMemberNumber = MemberNumber.create(data.memberNumber);
    final domainFlightNumber = FlightNumber.create(data.flightNumber);
    final domainSeatNumber = SeatNumber.create(data.seatNumber);

    final boardingTime = data.baseTime.add(Duration(hours: 1, minutes: 30));
    final departureTime = data.baseTime.add(Duration(hours: 2, minutes: 30));
    final snapshotTime = data.baseTime.subtract(Duration(minutes: 30));

    final scheduleSnapshot = FlightScheduleSnapshot(
      departureTime: departureTime,
      boardingTime: boardingTime,
      departure: AirportCode.create(data.departureCode),
      arrival: AirportCode.create(data.arrivalCode),
      gate: Gate.create(data.gate),
      snapshotTime: snapshotTime,
    );

    final qrCodeResult = _qrCodeService.generate(
      passId: domainPassId,
      flightNumber: domainFlightNumber.value,
      seatNumber: domainSeatNumber.value,
      memberNumber: domainMemberNumber.value,
      departureTime: departureTime,
    );

    final qrCode = qrCodeResult.fold(
      (failure) => throw Exception('QR generation failed: ${failure.message}'),
      (qrCode) => qrCode,
    );

    final domainBoardingPass = BoardingPass.fromPersistence(
      passId: data.passId,
      memberNumber: data.memberNumber,
      flightNumber: data.flightNumber,
      seatNumber: data.seatNumber,
      scheduleSnapshot: scheduleSnapshot,
      status: PassStatus.activated,
      qrCode: qrCode,
      issueTime: data.baseTime.subtract(Duration(hours: 2)),
      activatedAt: data.baseTime.subtract(Duration(hours: 1)),
    );

    return BoardingPassEntity.fromDomain(domainBoardingPass);
  }
}

class _StandardMemberData {
  final String memberNumber;
  final String fullName;
  final String email;
  final String phone;
  final String tier;

  const _StandardMemberData({
    required this.memberNumber,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.tier,
  });
}

class _StandardBoardingPassData {
  final String passId;
  final String memberNumber;
  final String flightNumber;
  final String seatNumber;
  final String departureCode;
  final String arrivalCode;
  final String gate;
  final tz.TZDateTime baseTime;

  const _StandardBoardingPassData({
    required this.passId,
    required this.memberNumber,
    required this.flightNumber,
    required this.seatNumber,
    required this.departureCode,
    required this.arrivalCode,
    required this.gate,
    required this.baseTime,
  });

  _StandardBoardingPassData copyWith({
    String? passId,
    String? memberNumber,
    String? flightNumber,
    String? seatNumber,
    String? departureCode,
    String? arrivalCode,
    String? gate,
    tz.TZDateTime? baseTime,
  }) {
    return _StandardBoardingPassData(
      passId: passId ?? this.passId,
      memberNumber: memberNumber ?? this.memberNumber,
      flightNumber: flightNumber ?? this.flightNumber,
      seatNumber: seatNumber ?? this.seatNumber,
      departureCode: departureCode ?? this.departureCode,
      arrivalCode: arrivalCode ?? this.arrivalCode,
      gate: gate ?? this.gate,
      baseTime: baseTime ?? this.baseTime,
    );
  }
}
