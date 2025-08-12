import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';
import 'package:app/features/boarding_pass/domain/value_objects/flight_schedule_snapshot.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:app/features/boarding_pass/domain/value_objects/seat_number.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:timezone/timezone.dart' as tz;

class BoardingPass {
  final PassId passId;
  final MemberNumber memberNumber;
  final FlightNumber flightNumber;
  final SeatNumber seatNumber;
  final FlightScheduleSnapshot scheduleSnapshot;
  final PassStatus status;
  final QRCodeData qrCode;
  final tz.TZDateTime issueTime;
  final tz.TZDateTime? activatedAt;
  final tz.TZDateTime? usedAt;

  const BoardingPass._({
    required this.passId,
    required this.memberNumber,
    required this.flightNumber,
    required this.seatNumber,
    required this.scheduleSnapshot,
    required this.status,
    required this.qrCode,
    required this.issueTime,
    this.activatedAt,
    this.usedAt,
  });

  factory BoardingPass.create({
    required MemberNumber memberNumber,
    required FlightNumber flightNumber,
    required SeatNumber seatNumber,
    required FlightScheduleSnapshot scheduleSnapshot,
    required QRCodeData qrCode,
  }) {
    final passId = PassId.generate();
    final issueTime = tz.TZDateTime.now(tz.local);

    return BoardingPass._(
      passId: passId,
      memberNumber: memberNumber,
      flightNumber: flightNumber,
      seatNumber: seatNumber,
      scheduleSnapshot: scheduleSnapshot,
      status: PassStatus.issued,
      qrCode: qrCode,
      issueTime: issueTime,
    );
  }

  factory BoardingPass.fromPersistence({
    required String passId,
    required String memberNumber,
    required String flightNumber,
    required String seatNumber,
    required FlightScheduleSnapshot scheduleSnapshot,
    required PassStatus status,
    required QRCodeData qrCode,
    required tz.TZDateTime issueTime,
    tz.TZDateTime? activatedAt,
    tz.TZDateTime? usedAt,
  }) {
    return BoardingPass._(
      passId: PassId.fromString(passId),
      memberNumber: MemberNumber.create(memberNumber),
      flightNumber: FlightNumber.create(flightNumber),
      seatNumber: SeatNumber.create(seatNumber),
      scheduleSnapshot: scheduleSnapshot,
      status: status,
      qrCode: qrCode,
      issueTime: issueTime,
      activatedAt: activatedAt,
      usedAt: usedAt,
    );
  }

  BoardingPass activate() {
    if (!_canActivate()) {
      throw DomainException(
        'Cannot activate boarding pass: ${_getActivationBlockingReason()}',
      );
    }

    final activationTime = tz.TZDateTime.now(tz.local);

    return BoardingPass._(
      passId: passId,
      memberNumber: memberNumber,
      flightNumber: flightNumber,
      seatNumber: seatNumber,
      scheduleSnapshot: scheduleSnapshot,
      status: PassStatus.activated,
      qrCode: qrCode,
      issueTime: issueTime,
      activatedAt: activationTime,
      usedAt: usedAt,
    );
  }

  BoardingPass cancel() {
    if (status == PassStatus.used) {
      throw DomainException(
        'Cannot cancel boarding pass that has already been used',
      );
    }

    return BoardingPass._(
      passId: passId,
      memberNumber: memberNumber,
      flightNumber: flightNumber,
      seatNumber: seatNumber,
      scheduleSnapshot: scheduleSnapshot,
      status: PassStatus.cancelled,
      qrCode: qrCode,
      issueTime: issueTime,
      activatedAt: activatedAt,
      usedAt: usedAt,
    );
  }

  bool get isValidForBoarding {
    return status == PassStatus.activated && _isWithinBoardingWindow();
  }

  bool get isActive {
    return status != PassStatus.cancelled &&
        status != PassStatus.expired &&
        status != PassStatus.used;
  }

  Duration? get timeUntilDeparture {
    final now = tz.TZDateTime.now(tz.local);
    if (now.isAfter(scheduleSnapshot.departureTime)) {
      return null; // Flight has departed
    }
    return scheduleSnapshot.departureTime.difference(now);
  }

  bool _isWithinBoardingWindow() {
    final now = tz.TZDateTime.now(tz.local);
    return now.isAfter(scheduleSnapshot.boardingTime) &&
        now.isBefore(scheduleSnapshot.departureTime);
  }

  bool _canActivate() {
    if (status != PassStatus.issued) return false;

    final now = tz.TZDateTime.now(tz.local);
    final twentyFourHoursBefore = scheduleSnapshot.departureTime.subtract(
      const Duration(hours: 24),
    );

    return now.isAfter(twentyFourHoursBefore) &&
        now.isBefore(scheduleSnapshot.departureTime);
  }

  String _getActivationBlockingReason() {
    if (status != PassStatus.issued) {
      return 'boarding pass status is ${status.name}';
    }

    final now = tz.TZDateTime.now(tz.local);
    final twentyFourHoursBefore = scheduleSnapshot.departureTime.subtract(
      const Duration(hours: 24),
    );

    if (now.isBefore(twentyFourHoursBefore)) {
      return 'too early (can only activate within 24 hours of departure)';
    }

    if (now.isAfter(scheduleSnapshot.departureTime)) {
      return 'flight has already departed';
    }

    return 'unknown reason';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoardingPass && other.passId == passId;
  }

  @override
  int get hashCode => passId.hashCode;

  @override
  String toString() {
    return 'BoardingPass(passId: ${passId.value}, memberNumber: ${memberNumber.value}, '
        'flightNumber: ${flightNumber.value}, status: ${status.name}, '
        'seat: ${seatNumber.value})';
  }
}
