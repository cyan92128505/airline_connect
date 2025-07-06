import 'package:app/features/boarding_pass/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/enums/pass_status.dart';
import 'package:app/features/boarding_pass/value_objects/flight_schedule_snapshot.dart';
import 'package:app/features/boarding_pass/value_objects/qr_code_data.dart';
import 'package:objectbox/objectbox.dart';
import 'package:timezone/timezone.dart' as tz;

/// ObjectBox entity for BoardingPass domain model
/// Follows official ObjectBox entity design patterns
@Entity()
class BoardingPassEntity {
  /// ObjectBox required ID field - always int type, 0 for auto-assignment
  @Id()
  int id = 0;

  /// Pass ID - primary business key with replace strategy
  @Index()
  @Unique(onConflict: ConflictStrategy.replace)
  String passId;

  /// Foreign keys - indexed for queries
  @Index()
  String memberNumber;

  @Index()
  String flightNumber;

  /// Seat assignment
  String seatNumber;

  /// Flight schedule snapshot (frozen at boarding pass creation)
  @Index()
  @Property(type: PropertyType.date)
  DateTime departureTime;

  @Property(type: PropertyType.date)
  DateTime boardingTime;

  String departureAirport;
  String arrivalAirport;
  String gateNumber;

  @Property(type: PropertyType.date)
  DateTime scheduleSnapshotTime;

  /// Pass status - indexed for status-based queries
  @Index()
  String status;

  /// QR Code data
  String qrCodeEncryptedPayload;
  String qrCodeChecksum;

  @Property(type: PropertyType.date)
  DateTime qrCodeGeneratedAt;

  int qrCodeVersion;

  /// Entity lifecycle timestamps - indexed for time-based queries
  @Index()
  @Property(type: PropertyType.date)
  DateTime issueTime;

  @Property(type: PropertyType.date)
  DateTime? activatedAt;

  @Property(type: PropertyType.date)
  DateTime? usedAt;

  /// No-args constructor required by ObjectBox
  BoardingPassEntity()
    : passId = '',
      memberNumber = '',
      flightNumber = '',
      seatNumber = '',
      departureTime = DateTime.now(),
      boardingTime = DateTime.now(),
      departureAirport = '',
      arrivalAirport = '',
      gateNumber = '',
      scheduleSnapshotTime = DateTime.now(),
      status = '',
      qrCodeEncryptedPayload = '',
      qrCodeChecksum = '',
      qrCodeGeneratedAt = DateTime.now(),
      qrCodeVersion = 1,
      issueTime = DateTime.now();

  /// Parameterized constructor for convenience
  BoardingPassEntity.create({
    required this.passId,
    required this.memberNumber,
    required this.flightNumber,
    required this.seatNumber,
    required this.departureTime,
    required this.boardingTime,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.gateNumber,
    required this.scheduleSnapshotTime,
    required this.status,
    required this.qrCodeEncryptedPayload,
    required this.qrCodeChecksum,
    required this.qrCodeGeneratedAt,
    required this.qrCodeVersion,
    required this.issueTime,
    this.activatedAt,
    this.usedAt,
  });

  /// Convert from Domain Entity to ObjectBox Entity
  factory BoardingPassEntity.fromDomain(BoardingPass boardingPass) {
    return BoardingPassEntity.create(
      passId: boardingPass.passId.value,
      memberNumber: boardingPass.memberNumber.value,
      flightNumber: boardingPass.flightNumber.value,
      seatNumber: boardingPass.seatNumber.value,
      departureTime: boardingPass.scheduleSnapshot.departureTime.toUtc(),
      boardingTime: boardingPass.scheduleSnapshot.boardingTime.toUtc(),
      departureAirport: boardingPass.scheduleSnapshot.departure.value,
      arrivalAirport: boardingPass.scheduleSnapshot.arrival.value,
      gateNumber: boardingPass.scheduleSnapshot.gate.value,
      scheduleSnapshotTime: boardingPass.scheduleSnapshot.snapshotTime.toUtc(),
      status: boardingPass.status.value,
      qrCodeEncryptedPayload: boardingPass.qrCode.encryptedPayload,
      qrCodeChecksum: boardingPass.qrCode.checksum,
      qrCodeGeneratedAt: boardingPass.qrCode.generatedAt.toUtc(),
      qrCodeVersion: boardingPass.qrCode.version,
      issueTime: boardingPass.issueTime.toUtc(),
      activatedAt: boardingPass.activatedAt?.toUtc(),
      usedAt: boardingPass.usedAt?.toUtc(),
    );
  }

  /// Convert from ObjectBox Entity to Domain Entity
  BoardingPass toDomain() {
    // Reconstruct FlightScheduleSnapshot
    final scheduleSnapshot = FlightScheduleSnapshot.create(
      departureTime: tz.TZDateTime.from(departureTime, tz.local),
      boardingTime: tz.TZDateTime.from(boardingTime, tz.local),
      departureAirport: departureAirport,
      arrivalAirport: arrivalAirport,
      gateNumber: gateNumber,
      snapshotTime: tz.TZDateTime.from(scheduleSnapshotTime, tz.local),
    );

    // Reconstruct QRCodeData
    final qrCode = QRCodeData(
      encryptedPayload: qrCodeEncryptedPayload,
      checksum: qrCodeChecksum,
      generatedAt: tz.TZDateTime.from(qrCodeGeneratedAt, tz.local),
      version: qrCodeVersion,
    );

    return BoardingPass.fromPersistence(
      passId: passId,
      memberNumber: memberNumber,
      flightNumber: flightNumber,
      seatNumber: seatNumber,
      scheduleSnapshot: scheduleSnapshot,
      status: PassStatus.fromString(status),
      qrCode: qrCode,
      issueTime: tz.TZDateTime.from(issueTime, tz.local),
      activatedAt: activatedAt != null
          ? tz.TZDateTime.from(activatedAt!, tz.local)
          : null,
      usedAt: usedAt != null ? tz.TZDateTime.from(usedAt!, tz.local) : null,
    );
  }

  /// Update entity from domain object while preserving ObjectBox ID
  void updateFromDomain(BoardingPass boardingPass) {
    passId = boardingPass.passId.value;
    memberNumber = boardingPass.memberNumber.value;
    flightNumber = boardingPass.flightNumber.value;
    seatNumber = boardingPass.seatNumber.value;
    departureTime = boardingPass.scheduleSnapshot.departureTime.toUtc();
    boardingTime = boardingPass.scheduleSnapshot.boardingTime.toUtc();
    departureAirport = boardingPass.scheduleSnapshot.departure.value;
    arrivalAirport = boardingPass.scheduleSnapshot.arrival.value;
    gateNumber = boardingPass.scheduleSnapshot.gate.value;
    scheduleSnapshotTime = boardingPass.scheduleSnapshot.snapshotTime.toUtc();
    status = boardingPass.status.value;
    qrCodeEncryptedPayload = boardingPass.qrCode.encryptedPayload;
    qrCodeChecksum = boardingPass.qrCode.checksum;
    qrCodeGeneratedAt = boardingPass.qrCode.generatedAt.toUtc();
    qrCodeVersion = boardingPass.qrCode.version;
    issueTime = boardingPass.issueTime.toUtc();
    activatedAt = boardingPass.activatedAt?.toUtc();
    usedAt = boardingPass.usedAt?.toUtc();
  }
}
