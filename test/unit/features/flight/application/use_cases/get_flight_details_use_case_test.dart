import 'package:app/core/failures/failure.dart';
import 'package:app/features/flight/application/use_cases/get_flight_details_use_case.dart';
import 'package:app/features/flight/domain/entities/flight.dart';
import 'package:app/features/flight/domain/repositories/flight_repository.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:app/features/flight/domain/value_objects/flight_schedule.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

@GenerateMocks([FlightRepository])
import 'get_flight_details_use_case_test.mocks.dart';

void main() {
  late GetFlightDetailsUseCase useCase;
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
    useCase = GetFlightDetailsUseCase(mockRepository);
  });

  group('GetFlightDetailsUseCase Tests', () {
    test('should return flight details when flight exists', () async {
      // Arrange
      final flight = createTestFlight();
      final flightNumber = FlightNumber.create('BR857');

      when(
        mockRepository.findByFlightNumber(flightNumber),
      ).thenAnswer((_) async => Right(flight));

      // Act
      final result = await useCase('BR857');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Expected success'), (flightDTO) {
        expect(flightDTO.flightNumber, equals('BR857'));
        expect(flightDTO.schedule.departure, equals('TPE'));
        expect(flightDTO.schedule.arrival, equals('NRT'));
      });
      verify(mockRepository.findByFlightNumber(flightNumber)).called(1);
    });

    test('should return NotFoundFailure when flight does not exist', () async {
      // Arrange - Use valid flight number format but non-existent flight
      final flightNumber = FlightNumber.create('AA9999');
      when(
        mockRepository.findByFlightNumber(flightNumber),
      ).thenAnswer((_) async => Right(null));

      // Act
      final result = await useCase('AA9999');

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (flightDTO) => fail('Expected failure'),
      );
    });

    test(
      'should return ValidationFailure for invalid flight number format',
      () async {
        // Act - Use empty string to trigger domain validation
        final result = await useCase('');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (flightDTO) => fail('Expected failure'),
        );
        verifyNever(mockRepository.findByFlightNumber(any));
      },
    );

    test(
      'should return UnknownFailure when repository throws exception',
      () async {
        // Arrange
        final flightNumber = FlightNumber.create('BR857');
        when(
          mockRepository.findByFlightNumber(flightNumber),
        ).thenThrow(Exception('Database error'));

        // Act
        final result = await useCase('BR857');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<UnknownFailure>()),
          (flightDTO) => fail('Expected failure'),
        );
      },
    );

    test('should handle repository failure result', () async {
      // Arrange
      final flightNumber = FlightNumber.create('BR857');
      when(
        mockRepository.findByFlightNumber(flightNumber),
      ).thenAnswer((_) async => Left(UnknownFailure('Network error')));

      // Act
      final result = await useCase('BR857');

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (flightDTO) => fail('Expected failure'),
      );
    });
  });
}
