import 'package:timezone/timezone.dart';
import '../value_objects/flight_number.dart';
import '../value_objects/flight_schedule.dart';
import '../enums/flight_status.dart';
import '../../../core/exceptions/domain_exception.dart';

class Flight {
  final FlightNumber flightNumber;
  final FlightSchedule schedule;
  final FlightStatus status;
  final String aircraftType;
  final TZDateTime createdAt;
  final TZDateTime? updatedAt;

  const Flight._({
    required this.flightNumber,
    required this.schedule,
    required this.status,
    required this.aircraftType,
    required this.createdAt,
    this.updatedAt,
  });

  factory Flight.create({
    required String flightNumber,
    required FlightSchedule schedule,
    required String aircraftType,
  }) {
    return Flight._(
      flightNumber: FlightNumber.create(flightNumber),
      schedule: schedule,
      status: FlightStatus.scheduled,
      aircraftType: aircraftType.trim(),
      createdAt: TZDateTime.now(local),
    );
  }

  factory Flight.fromPersistence({
    required String flightNumber,
    required FlightSchedule schedule,
    required FlightStatus status,
    required String aircraftType,
    required TZDateTime createdAt,
    TZDateTime? updatedAt,
  }) {
    return Flight._(
      flightNumber: FlightNumber.create(flightNumber),
      schedule: schedule,
      status: status,
      aircraftType: aircraftType,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Flight updateStatus(FlightStatus newStatus) {
    if (!_canTransitionTo(newStatus)) {
      throw DomainException(
        'Invalid status transition from ${status.name} to ${newStatus.name}',
      );
    }

    return Flight._(
      flightNumber: flightNumber,
      schedule: schedule,
      status: newStatus,
      aircraftType: aircraftType,
      createdAt: createdAt,
      updatedAt: TZDateTime.now(local),
    );
  }

  Flight updateSchedule(FlightSchedule newSchedule) {
    // Validate that departure time hasn't passed for most updates
    if (status == FlightStatus.departed || status == FlightStatus.arrived) {
      throw DomainException(
        'Cannot update schedule for flight that has departed',
      );
    }

    return Flight._(
      flightNumber: flightNumber,
      schedule: newSchedule,
      status: status,
      aircraftType: aircraftType,
      createdAt: createdAt,
      updatedAt: TZDateTime.now(local),
    );
  }

  Flight delay(Duration delayDuration) {
    final delayedSchedule = schedule.delay(delayDuration);
    final newStatus = status == FlightStatus.scheduled
        ? FlightStatus.delayed
        : status;

    return Flight._(
      flightNumber: flightNumber,
      schedule: delayedSchedule,
      status: newStatus,
      aircraftType: aircraftType,
      createdAt: createdAt,
      updatedAt: TZDateTime.now(local),
    );
  }

  Flight cancel() {
    if (status == FlightStatus.departed || status == FlightStatus.arrived) {
      throw DomainException('Cannot cancel flight that has already departed');
    }

    return Flight._(
      flightNumber: flightNumber,
      schedule: schedule,
      status: FlightStatus.cancelled,
      aircraftType: aircraftType,
      createdAt: createdAt,
      updatedAt: TZDateTime.now(local),
    );
  }

  bool get isActive {
    return status != FlightStatus.cancelled &&
        status != FlightStatus.arrived &&
        status != FlightStatus.diverted;
  }

  bool get isBoardingEligible {
    return status == FlightStatus.boarding ||
        (status == FlightStatus.scheduled && _isWithinBoardingWindow()) ||
        (status == FlightStatus.delayed && _isWithinBoardingWindow());
  }

  bool _isWithinBoardingWindow() {
    final now = TZDateTime.now(local);
    final boardingStart = schedule.boardingTime;
    final departureTime = schedule.departureTime;

    return now.isAfter(boardingStart) && now.isBefore(departureTime);
  }

  bool _canTransitionTo(FlightStatus targetStatus) {
    switch (status) {
      case FlightStatus.scheduled:
        return targetStatus == FlightStatus.delayed ||
            targetStatus == FlightStatus.boarding ||
            targetStatus == FlightStatus.cancelled;

      case FlightStatus.delayed:
        return targetStatus == FlightStatus.boarding ||
            targetStatus == FlightStatus.cancelled ||
            targetStatus ==
                FlightStatus.scheduled; // Can revert if delay is resolved

      case FlightStatus.boarding:
        return targetStatus == FlightStatus.departed ||
            targetStatus == FlightStatus.delayed ||
            targetStatus == FlightStatus.cancelled;

      case FlightStatus.departed:
        return targetStatus == FlightStatus.arrived ||
            targetStatus == FlightStatus.diverted;

      case FlightStatus.arrived:
      case FlightStatus.cancelled:
      case FlightStatus.diverted:
        return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Flight && other.flightNumber == flightNumber;
  }

  @override
  int get hashCode => flightNumber.hashCode;

  @override
  String toString() {
    return 'Flight(flightNumber: ${flightNumber.value}, status: ${status.name}, '
        'departure: ${schedule.departure.value} -> ${schedule.arrival.value})';
  }
}
