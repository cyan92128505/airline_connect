import 'package:app/features/flight/domain/entities/flight.dart';
import 'package:app/features/flight/domain/enums/flight_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'flight_dto.freezed.dart';
part 'flight_dto.g.dart';

/// Data Transfer Object for Flight
@freezed
abstract class FlightDTO with _$FlightDTO {
  const factory FlightDTO({
    required String flightNumber,
    required FlightScheduleDTO schedule,
    required FlightStatus status,
    required String aircraftType,
    required String createdAt,
    String? updatedAt,
  }) = _FlightDTO;

  factory FlightDTO.fromJson(Map<String, Object?> json) =>
      _$FlightDTOFromJson(json);
}

/// Data Transfer Object for Flight Schedule
@freezed
abstract class FlightScheduleDTO with _$FlightScheduleDTO {
  const factory FlightScheduleDTO({
    required String departureTime,
    required String boardingTime,
    required String departure,
    required String arrival,
    required String gate,
  }) = _FlightScheduleDTO;

  factory FlightScheduleDTO.fromJson(Map<String, Object?> json) =>
      _$FlightScheduleDTOFromJson(json);
}

/// Extensions for Flight DTO conversion
extension FlightDTOExtensions on FlightDTO {
  /// Convert from Domain Entity to DTO
  static FlightDTO fromDomain(Flight flight) {
    return FlightDTO(
      flightNumber: flight.flightNumber.value,
      schedule: FlightScheduleDTO(
        departureTime: flight.schedule.departureTime.toIso8601String(),
        boardingTime: flight.schedule.boardingTime.toIso8601String(),
        departure: flight.schedule.departure.value,
        arrival: flight.schedule.arrival.value,
        gate: flight.schedule.gate.value,
      ),
      status: flight.status,
      aircraftType: flight.aircraftType,
      createdAt: flight.createdAt.toIso8601String(),
      updatedAt: flight.updatedAt?.toIso8601String(),
    );
  }
}
