import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/boarding_pass/enums/pass_status.dart';
import 'package:app/features/boarding_pass/value_objects/flight_schedule_snapshot.dart';
import 'package:app/features/boarding_pass/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/value_objects/qr_code_data.dart';
import 'package:app/features/boarding_pass/value_objects/seat_number.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:timezone/timezone.dart';

class BoardingPass {
  final PassId passId;
  final MemberNumber memberNumber;
  final FlightNumber flightNumber;
  final SeatNumber seatNumber;
  final FlightScheduleSnapshot scheduleSnapshot;
  final PassStatus status;
  final QRCodeData qrCode;
  final TZDateTime issueTime;
  final TZDateTime? activatedAt;
  final TZDateTime? usedAt;

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
  }) {
    final passId = PassId.generate();
    final issueTime = TZDateTime.now(local);

    final qrCode = QRCodeData.generate(
      passId: passId,
      flightNumber: flightNumber,
      seatNumber: seatNumber,
      memberNumber: memberNumber,
      departureTime: scheduleSnapshot.departureTime,
    );

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
    required TZDateTime issueTime,
    TZDateTime? activatedAt,
    TZDateTime? usedAt,
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

    final activationTime = TZDateTime.now(local);

    final newQrCode = QRCodeData.generate(
      passId: passId,
      flightNumber: flightNumber,
      seatNumber: seatNumber,
      memberNumber: memberNumber,
      departureTime: scheduleSnapshot.departureTime,
    );

    return BoardingPass._(
      passId: passId,
      memberNumber: memberNumber,
      flightNumber: flightNumber,
      seatNumber: seatNumber,
      scheduleSnapshot: scheduleSnapshot,
      status: PassStatus.activated,
      qrCode: newQrCode,
      issueTime: issueTime,
      activatedAt: activationTime,
      usedAt: usedAt,
    );
  }

  BoardingPass use() {
    if (!_canUse()) {
      throw DomainException(
        'Cannot use boarding pass: ${_getUsageBlockingReason()}',
      );
    }

    return BoardingPass._(
      passId: passId,
      memberNumber: memberNumber,
      flightNumber: flightNumber,
      seatNumber: seatNumber,
      scheduleSnapshot: scheduleSnapshot,
      status: PassStatus.used,
      qrCode: qrCode,
      issueTime: issueTime,
      activatedAt: activatedAt,
      usedAt: TZDateTime.now(local),
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

  BoardingPass expire() {
    if (status == PassStatus.used) {
      throw DomainException('Cannot expire boarding pass that has been used');
    }

    return BoardingPass._(
      passId: passId,
      memberNumber: memberNumber,
      flightNumber: flightNumber,
      seatNumber: seatNumber,
      scheduleSnapshot: scheduleSnapshot,
      status: PassStatus.expired,
      qrCode: qrCode,
      issueTime: issueTime,
      activatedAt: activatedAt,
      usedAt: usedAt,
    );
  }

  BoardingPass updateSeat(SeatNumber newSeatNumber) {
    if (!_canUpdateSeat()) {
      throw DomainException(
        'Cannot update seat: boarding pass is ${status.name}',
      );
    }

    final newQrCode = QRCodeData.generate(
      passId: passId,
      flightNumber: flightNumber,
      seatNumber: newSeatNumber,
      memberNumber: memberNumber,
      departureTime: scheduleSnapshot.departureTime,
    );

    return BoardingPass._(
      passId: passId,
      memberNumber: memberNumber,
      flightNumber: flightNumber,
      seatNumber: newSeatNumber,
      scheduleSnapshot: scheduleSnapshot,
      status: status,
      qrCode: newQrCode,
      issueTime: issueTime,
      activatedAt: activatedAt,
      usedAt: usedAt,
    );
  }

  bool get isValidForBoarding {
    return status == PassStatus.activated &&
        _isWithinBoardingWindow() &&
        qrCode.isValid;
  }

  bool get isActive {
    return status != PassStatus.cancelled &&
        status != PassStatus.expired &&
        status != PassStatus.used;
  }

  Duration? get timeUntilDeparture {
    final now = TZDateTime.now(local);
    if (now.isAfter(scheduleSnapshot.departureTime)) {
      return null; // Flight has departed
    }
    return scheduleSnapshot.departureTime.difference(now);
  }

  bool _isWithinBoardingWindow() {
    final now = TZDateTime.now(local);
    return now.isAfter(scheduleSnapshot.boardingTime) &&
        now.isBefore(scheduleSnapshot.departureTime);
  }

  bool _canActivate() {
    if (status != PassStatus.issued) return false;

    final now = TZDateTime.now(local);
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

    final now = TZDateTime.now(local);
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

  bool _canUse() {
    return status == PassStatus.activated &&
        _isWithinBoardingWindow() &&
        qrCode.isValid;
  }

  String _getUsageBlockingReason() {
    if (status != PassStatus.activated) {
      return 'boarding pass is not activated (status: ${status.name})';
    }

    if (!_isWithinBoardingWindow()) {
      return 'not within boarding window';
    }

    if (!qrCode.isValid) {
      return 'QR code is invalid or expired';
    }

    return 'unknown reason';
  }

  bool _canUpdateSeat() {
    return status == PassStatus.issued || status == PassStatus.activated;
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
