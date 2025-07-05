import 'package:app/features/flight/entities/flight.dart';
import 'package:app/features/flight/enums/flight_status.dart';
import 'package:app/features/flight/value_objects/flight_schedule.dart';
import 'package:objectbox/objectbox.dart';
import 'package:timezone/timezone.dart' as tz;

/// ObjectBox entity for Flight domain model
/// Follows official ObjectBox entity design patterns
@Entity()
class FlightEntity {
  /// ObjectBox required ID field - always int type, 0 for auto-assignment
  @Id()
  int id = 0;

  /// Flight number - primary business key with replace strategy
  @Index()
  @Unique(onConflict: ConflictStrategy.replace)
  String flightNumber;

  /// Schedule information - indexed for queries
  @Index()
  String departureAirport;

  @Index()
  String arrivalAirport;

  @Index()
  String gateNumber;

  /// Timestamps - indexed for date-based queries
  @Index()
  @Property(type: PropertyType.date)
  DateTime departureTime;

  @Property(type: PropertyType.date)
  DateTime boardingTime;

  /// Flight status as string value
  @Index()
  String status;

  /// Aircraft information
  String aircraftType;

  /// Entity lifecycle timestamps
  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime? updatedAt;

  /// No-args constructor required by ObjectBox
  FlightEntity()
    : flightNumber = '',
      departureAirport = '',
      arrivalAirport = '',
      gateNumber = '',
      departureTime = DateTime.now(),
      boardingTime = DateTime.now(),
      status = '',
      aircraftType = '',
      createdAt = DateTime.now();

  /// Parameterized constructor for convenience
  FlightEntity.create({
    required this.flightNumber,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.gateNumber,
    required this.departureTime,
    required this.boardingTime,
    required this.status,
    required this.aircraftType,
    required this.createdAt,
    this.updatedAt,
  });

  /// Convert from Domain Entity to ObjectBox Entity
  factory FlightEntity.fromDomain(Flight flight) {
    return FlightEntity.create(
      flightNumber: flight.flightNumber.value,
      departureAirport: flight.schedule.departure.value,
      arrivalAirport: flight.schedule.arrival.value,
      gateNumber: flight.schedule.gate.value,
      departureTime: flight.schedule.departureTime.toUtc(),
      boardingTime: flight.schedule.boardingTime.toUtc(),
      status: flight.status.value,
      aircraftType: flight.aircraftType,
      createdAt: flight.createdAt.toUtc(),
      updatedAt: flight.updatedAt?.toUtc(),
    );
  }

  /// Convert from ObjectBox Entity to Domain Entity
  Flight toDomain() {
    final schedule = FlightSchedule.create(
      departureTime: tz.TZDateTime.from(departureTime, tz.local),
      boardingTime: tz.TZDateTime.from(boardingTime, tz.local),
      departureAirport: departureAirport,
      arrivalAirport: arrivalAirport,
      gateNumber: gateNumber,
    );

    return Flight.fromPersistence(
      flightNumber: flightNumber,
      schedule: schedule,
      status: FlightStatus.fromString(status),
      aircraftType: aircraftType,
      createdAt: tz.TZDateTime.from(createdAt, tz.local),
      updatedAt: updatedAt != null
          ? tz.TZDateTime.from(updatedAt!, tz.local)
          : null,
    );
  }

  /// Update entity from domain object while preserving ObjectBox ID
  void updateFromDomain(Flight flight) {
    flightNumber = flight.flightNumber.value;
    departureAirport = flight.schedule.departure.value;
    arrivalAirport = flight.schedule.arrival.value;
    gateNumber = flight.schedule.gate.value;
    departureTime = flight.schedule.departureTime.toUtc();
    boardingTime = flight.schedule.boardingTime.toUtc();
    status = flight.status.value;
    aircraftType = flight.aircraftType;
    createdAt = flight.createdAt.toUtc();
    updatedAt = flight.updatedAt?.toUtc();
  }
}
