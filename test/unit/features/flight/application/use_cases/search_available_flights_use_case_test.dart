import 'package:app/core/failures/failure.dart';
import 'package:app/features/flight/application/dtos/flight_search_dto.dart';
import 'package:app/features/flight/application/use_cases/search_available_flights_use_case.dart';
import 'package:app/features/flight/domain/entities/flight.dart';
import 'package:app/features/flight/domain/repositories/flight_repository.dart';
import 'package:app/features/flight/domain/value_objects/flight_schedule.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

@GenerateMocks([FlightRepository])
import 'search_available_flights_use_case_test.mocks.dart';

void main() {
  late SearchAvailableFlightsUseCase useCase;
  late MockFlightRepository mockRepository;

  Flight createTestFlight() {
    final departureTime = tz.TZDateTime.now(tz.local).add(Duration(hours: 2));
    final boardingTime = departureTime.subtract(Duration(minutes: 30));

    final schedule = FlightSchedule.create(
      departureTime: departureTime,
      boardingTime: boardingTime,
      departureAirport: 'TPE',
      arrivalAirport: 'NRT',
      gateNumber: 'A12',
    );

    return Flight.create(
      flightNumber: 'BR857',
      schedule: schedule,
      aircraftType: 'Boeing 777',
    );
  }

  setUpAll(() {
    tz.initializeTimeZones();
  });

  setUp(() {
    mockRepository = MockFlightRepository();
    useCase = SearchAvailableFlightsUseCase(mockRepository);
  });

  group('SearchAvailableFlightsUseCase Tests', () {
    test('should search flights by airport and date successfully', () async {
      // Arrange
      final flights = [createTestFlight()];
      final searchDTO = FlightSearchDTO(
        departureAirport: 'TPE',
        departureDate: '2025-07-17',
      );

      when(
        mockRepository.findByDepartureAirportAndDate('TPE', any),
      ).thenAnswer((_) async => Right(flights));

      // Act
      final result = await useCase(searchDTO);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Expected success'), (flightDTOs) {
        expect(flightDTOs.length, equals(1));
        expect(flightDTOs.first.flightNumber, equals('BR857'));
      });
      verify(
        mockRepository.findByDepartureAirportAndDate('TPE', any),
      ).called(1);
    });

    test(
      'should return ValidationFailure for missing date when airport provided',
      () async {
        // Arrange - Airport provided but date missing
        final searchDTO = FlightSearchDTO(
          departureAirport: 'TPE',
          // Missing departureDate
        );

        // Act
        final result = await useCase(searchDTO);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Departure date must be provided'));
        }, (flightDTOs) => fail('Expected failure'));
        verifyNever(mockRepository.findByDepartureAirportAndDate(any, any));
      },
    );

    test(
      'should get active flights when no specific criteria provided',
      () async {
        // Arrange
        final flights = [createTestFlight()];
        final searchDTO = FlightSearchDTO(); // Empty search

        when(
          mockRepository.findActiveFlights(),
        ).thenAnswer((_) async => Right(flights));

        // Act
        final result = await useCase(searchDTO);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success'),
          (flightDTOs) => expect(flightDTOs.length, equals(1)),
        );
        verify(mockRepository.findActiveFlights()).called(1);
      },
    );

    test('should return ValidationFailure for invalid date format', () async {
      // Arrange
      final searchDTO = FlightSearchDTO(
        departureAirport: 'TPE',
        departureDate: 'invalid-date-format',
      );

      // Act
      final result = await useCase(searchDTO);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, contains('Invalid date format'));
      }, (flightDTOs) => fail('Expected failure'));
    });

    test('should handle repository failure gracefully', () async {
      // Arrange
      final searchDTO = FlightSearchDTO();
      when(
        mockRepository.findActiveFlights(),
      ).thenAnswer((_) async => Left(UnknownFailure('Database error')));

      // Act
      final result = await useCase(searchDTO);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (flightDTOs) => fail('Expected failure'),
      );
    });

    test('should handle domain exception when creating airport code', () async {
      // Arrange
      final searchDTO = FlightSearchDTO(
        departureAirport: 'INVALID', // This should trigger domain exception
        departureDate: '2025-07-17',
      );

      // Act
      final result = await useCase(searchDTO);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (flightDTOs) => fail('Expected failure'),
      );
    });

    test('should handle exception during airport search gracefully', () async {
      // Arrange
      final searchDTO = FlightSearchDTO(
        departureAirport: 'TPE',
        departureDate: '2025-07-17',
      );

      when(
        mockRepository.findByDepartureAirportAndDate('TPE', any),
      ).thenAnswer((_) async => Left(UnknownFailure('Network error')));

      // Act
      final result = await useCase(searchDTO);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (flightDTOs) => fail('Expected failure'),
      );
    });
  });
}
