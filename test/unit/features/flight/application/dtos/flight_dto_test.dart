import 'package:app/features/flight/application/dtos/flight_dto.dart';
import 'package:app/features/flight/entities/flight.dart';
import 'package:app/features/flight/enums/flight_status.dart';
import 'package:app/features/flight/value_objects/flight_schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('FlightDTO Tests', () {
    test('should create FlightDTO from domain entity correctly', () {
      // Arrange
      final departureTime = tz.TZDateTime.now(
        tz.local,
      ).add(Duration(seconds: 1));
      final boardingTime = departureTime.subtract(Duration(minutes: 30));

      final schedule = FlightSchedule.create(
        departureTime: departureTime,
        boardingTime: boardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
      );

      final flight = Flight.create(
        flightNumber: 'BR857',
        schedule: schedule,
        aircraftType: 'Boeing 777',
      );

      // Act
      final dto = FlightDTOExtensions.fromDomain(flight);

      // Assert
      expect(dto.flightNumber, equals('BR857'));
      expect(dto.status, equals(FlightStatus.scheduled));
      expect(dto.aircraftType, equals('Boeing 777'));
      expect(dto.schedule.departure, equals('TPE'));
      expect(dto.schedule.arrival, equals('NRT'));
      expect(dto.schedule.gate, equals('A12'));
    });

    test('should handle JSON serialization correctly', () {
      // Arrange
      final dto = FlightDTO(
        flightNumber: 'BR857',
        schedule: FlightScheduleDTO(
          departureTime: '2025-07-17T10:00:00Z',
          boardingTime: '2025-07-17T09:30:00Z',
          departure: 'TPE',
          arrival: 'NRT',
          gate: 'A12',
        ),
        status: FlightStatus.scheduled,
        aircraftType: 'Boeing 777',
        createdAt: '2025-07-17T08:00:00Z',
      );

      // Act
      final json = dto.toJson();
      json['schedule'] = FlightScheduleDTO(
        departureTime: '2025-07-17T10:00:00Z',
        boardingTime: '2025-07-17T09:30:00Z',
        departure: 'TPE',
        arrival: 'NRT',
        gate: 'A12',
      ).toJson();

      final fromJson = FlightDTO.fromJson(json);

      // Assert
      expect(fromJson.flightNumber, equals(dto.flightNumber));
      expect(fromJson.status, equals(dto.status));
    });
  });

  group('FlightScheduleDTO Tests', () {
    test('should serialize and deserialize correctly', () {
      // Arrange
      final dto = FlightScheduleDTO(
        departureTime: '2025-07-17T10:00:00Z',
        boardingTime: '2025-07-17T09:30:00Z',
        departure: 'TPE',
        arrival: 'NRT',
        gate: 'A12',
      );

      // Act
      final json = dto.toJson();
      final fromJson = FlightScheduleDTO.fromJson(json);

      // Assert
      expect(fromJson.departure, equals('TPE'));
      expect(fromJson.arrival, equals('NRT'));
      expect(fromJson.gate, equals('A12'));
    });
  });
}
