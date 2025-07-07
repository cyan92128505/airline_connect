import 'package:app/features/flight/application/dtos/flight_search_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlightSearchDTO Tests', () {
    test('should create valid DTO with all optional parameters', () {
      // Arrange & Act
      final dto = FlightSearchDTO(
        departureAirport: 'TPE',
        departureDate: '2025-07-17',
        maxResults: 10,
      );

      // Assert
      expect(dto.departureAirport, equals('TPE'));
      expect(dto.departureDate, equals('2025-07-17'));
      expect(dto.maxResults, equals(10));
    });

    test('should handle JSON serialization correctly', () {
      // Arrange
      final dto = FlightSearchDTO(
        departureAirport: 'TPE',
        departureDate: '2025-07-17',
        maxResults: 20,
      );

      // Act
      final json = dto.toJson();
      final fromJson = FlightSearchDTO.fromJson(json);

      // Assert
      expect(fromJson.departureAirport, equals(dto.departureAirport));
      expect(fromJson.departureDate, equals(dto.departureDate));
      expect(fromJson.maxResults, equals(dto.maxResults));
    });

    test('should create DTO with only airport code', () {
      // Arrange & Act
      final dto = FlightSearchDTO(departureAirport: 'NRT');

      // Assert
      expect(dto.departureAirport, equals('NRT'));
      expect(dto.departureDate, isNull);
      expect(dto.maxResults, isNull);
    });

    test('should create empty DTO with all null values', () {
      // Arrange & Act
      final dto = FlightSearchDTO();

      // Assert
      expect(dto.departureAirport, isNull);
      expect(dto.departureDate, isNull);
      expect(dto.maxResults, isNull);
    });
  });
}
