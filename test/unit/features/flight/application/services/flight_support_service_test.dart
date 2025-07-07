import 'package:app/core/failures/failure.dart';
import 'package:app/features/flight/application/dtos/flight_dto.dart';
import 'package:app/features/flight/application/dtos/flight_search_dto.dart';
import 'package:app/features/flight/application/services/flight_support_service.dart';
import 'package:app/features/flight/application/use_cases/get_flight_details_use_case.dart';
import 'package:app/features/flight/application/use_cases/search_available_flights_use_case.dart';
import 'package:app/features/flight/domain/enums/flight_status.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:timezone/data/latest.dart' as tz;

@GenerateMocks([GetFlightDetailsUseCase, SearchAvailableFlightsUseCase])
import 'flight_support_service_test.mocks.dart';

void main() {
  late FlightSupportService service;
  late MockGetFlightDetailsUseCase mockGetFlightDetailsUseCase;
  late MockSearchAvailableFlightsUseCase mockSearchAvailableFlightsUseCase;

  FlightDTO createTestFlightDTO({
    FlightStatus status = FlightStatus.scheduled,
  }) {
    return FlightDTO(
      flightNumber: 'BR857',
      schedule: FlightScheduleDTO(
        departureTime: '2025-07-17T10:00:00Z',
        boardingTime: '2025-07-17T09:30:00Z',
        departure: 'TPE',
        arrival: 'NRT',
        gate: 'A12',
      ),
      status: status,
      aircraftType: 'Boeing 777',
      createdAt: '2025-07-17T08:00:00Z',
    );
  }

  setUpAll(() {
    tz.initializeTimeZones();
  });

  setUp(() {
    mockGetFlightDetailsUseCase = MockGetFlightDetailsUseCase();
    mockSearchAvailableFlightsUseCase = MockSearchAvailableFlightsUseCase();

    service = FlightSupportService(
      mockGetFlightDetailsUseCase,
      mockSearchAvailableFlightsUseCase,
    );
  });

  group('FlightSupportService Tests', () {
    test('should get flight details for boarding pass successfully', () async {
      // Arrange
      final flightDTO = createTestFlightDTO();
      when(
        mockGetFlightDetailsUseCase('BR857'),
      ).thenAnswer((_) async => Right(flightDTO));

      // Act
      final result = await service.getFlightForBoardingPass('BR857');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Expected success'), (flight) {
        expect(flight.flightNumber, equals('BR857'));
        expect(flight.status, equals(FlightStatus.scheduled));
      });
      verify(mockGetFlightDetailsUseCase('BR857')).called(1);
    });

    test('should return failure when flight not found', () async {
      // Arrange
      when(
        mockGetFlightDetailsUseCase('XX999'),
      ).thenAnswer((_) async => Left(NotFoundFailure('Flight not found')));

      // Act
      final result = await service.getFlightForBoardingPass('XX999');

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (flight) => fail('Expected failure'),
      );
    });

    test('should search available flights successfully', () async {
      // Arrange
      final flights = [createTestFlightDTO()];
      when(
        mockSearchAvailableFlightsUseCase(any),
      ).thenAnswer((_) async => Right(flights));

      // Act
      final result = await service.searchAvailableFlights(
        departureAirport: 'TPE',
        departureDate: '2025-07-17',
        maxResults: 10,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success'),
        (flightList) => expect(flightList.length, equals(1)),
      );

      // Verify the correct DTO was passed
      verify(
        mockSearchAvailableFlightsUseCase(
          argThat(
            predicate<FlightSearchDTO>(
              (dto) =>
                  dto.departureAirport == 'TPE' &&
                  dto.departureDate == '2025-07-17' &&
                  dto.maxResults == 10,
            ),
          ),
        ),
      ).called(1);
    });

    test('should handle search failure', () async {
      // Arrange
      when(
        mockSearchAvailableFlightsUseCase(any),
      ).thenAnswer((_) async => Left(UnknownFailure('Search failed')));

      // Act
      final result = await service.searchAvailableFlights();

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (flights) => fail('Expected failure'),
      );
    });

    test('should get today\'s departures successfully', () async {
      // Arrange
      final flights = [createTestFlightDTO()];
      when(
        mockSearchAvailableFlightsUseCase(any),
      ).thenAnswer((_) async => Right(flights));

      // Act
      final result = await service.getTodaysDepartures('TPE');

      // Assert
      expect(result.isRight(), isTrue);

      // Verify today's date was used
      final today = DateTime.now().toIso8601String().split('T')[0];
      verify(
        mockSearchAvailableFlightsUseCase(
          argThat(
            predicate<FlightSearchDTO>(
              (dto) =>
                  dto.departureAirport == 'TPE' && dto.departureDate == today,
            ),
          ),
        ),
      ).called(1);
    });

    test(
      'should check flight availability for boarding pass - available',
      () async {
        // Arrange
        final flightDTO = createTestFlightDTO(status: FlightStatus.scheduled);
        when(
          mockGetFlightDetailsUseCase('BR857'),
        ).thenAnswer((_) async => Right(flightDTO));

        // Act
        final result = await service.isFlightAvailableForBoardingPass('BR857');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success'),
          (isAvailable) => expect(isAvailable, isTrue),
        );
      },
    );

    test(
      'should check flight availability for boarding pass - not available',
      () async {
        // Arrange - Departed flight should not be available for new boarding passes
        final flightDTO = createTestFlightDTO(status: FlightStatus.departed);
        when(
          mockGetFlightDetailsUseCase('BR857'),
        ).thenAnswer((_) async => Right(flightDTO));

        // Act
        final result = await service.isFlightAvailableForBoardingPass('BR857');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success'),
          (isAvailable) => expect(isAvailable, isFalse),
        );
      },
    );

    test(
      'should return failure when checking availability of non-existent flight',
      () async {
        // Arrange
        when(
          mockGetFlightDetailsUseCase('XX999'),
        ).thenAnswer((_) async => Left(NotFoundFailure('Flight not found')));

        // Act
        final result = await service.isFlightAvailableForBoardingPass('XX999');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (isAvailable) => fail('Expected failure'),
        );
      },
    );

    test(
      'should consider boarding status as available for boarding pass',
      () async {
        // Arrange - Boarding flight should still be available for boarding passes
        final flightDTO = createTestFlightDTO(status: FlightStatus.boarding);
        when(
          mockGetFlightDetailsUseCase('BR857'),
        ).thenAnswer((_) async => Right(flightDTO));

        // Act
        final result = await service.isFlightAvailableForBoardingPass('BR857');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success'),
          (isAvailable) => expect(isAvailable, isTrue),
        );
      },
    );
  });
}
