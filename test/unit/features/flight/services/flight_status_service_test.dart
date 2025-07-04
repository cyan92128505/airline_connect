import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:app/features/flight/services/flight_status_service.dart';
import 'package:app/features/flight/repositories/flight_repository.dart';
import 'package:app/features/flight/entities/flight.dart';
import 'package:app/features/flight/value_objects/flight_number.dart';
import 'package:app/features/flight/value_objects/flight_schedule.dart';
import 'package:app/features/flight/enums/flight_status.dart';
import 'package:app/core/failures/failure.dart';

import 'flight_status_service_test.mocks.dart';

@GenerateMocks([FlightRepository])
void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('FlightStatusService Tests', () {
    late FlightStatusService statusService;
    late MockFlightRepository mockRepository;
    late Flight testFlight;

    setUp(() {
      mockRepository = MockFlightRepository();
      statusService = FlightStatusService(mockRepository);

      final now = TZDateTime.now(local);
      final boardingTime = now.add(const Duration(hours: 2));
      final departureTime = boardingTime.add(const Duration(hours: 1));

      final schedule = FlightSchedule.create(
        departureTime: departureTime,
        boardingTime: boardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
      );

      testFlight = Flight.create(
        flightNumber: 'BR857',
        schedule: schedule,
        aircraftType: 'A350',
      );
    });

    test('should update flight status successfully', () async {
      when(
        mockRepository.findByFlightNumber(any),
      ).thenAnswer((_) async => Right(testFlight));
      when(mockRepository.save(any)).thenAnswer((_) async => const Right(null));

      final result = await statusService.updateFlightStatus(
        flightNumber: FlightNumber.create('BR857'),
        newStatus: FlightStatus.boarding,
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (updatedFlight) {
        expect(updatedFlight.status, equals(FlightStatus.boarding));
      });

      verify(mockRepository.findByFlightNumber(any)).called(1);
      verify(mockRepository.save(any)).called(1);
    });

    test('should fail update for non-existent flight', () async {
      when(
        mockRepository.findByFlightNumber(any),
      ).thenAnswer((_) async => const Right(null));

      final result = await statusService.updateFlightStatus(
        flightNumber: FlightNumber.create('BR857'),
        newStatus: FlightStatus.boarding,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (flight) => fail('Should fail'),
      );
    });

    test('should delay flight successfully', () async {
      when(
        mockRepository.findByFlightNumber(any),
      ).thenAnswer((_) async => Right(testFlight));
      when(mockRepository.save(any)).thenAnswer((_) async => const Right(null));

      final result = await statusService.delayFlight(
        flightNumber: FlightNumber.create('BR857'),
        delayDuration: const Duration(minutes: 30),
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (delayedFlight) {
        expect(delayedFlight.status, equals(FlightStatus.delayed));
      });
    });

    test('should cancel flight successfully', () async {
      when(
        mockRepository.findByFlightNumber(any),
      ).thenAnswer((_) async => Right(testFlight));
      when(mockRepository.save(any)).thenAnswer((_) async => const Right(null));

      final result = await statusService.cancelFlight(
        FlightNumber.create('BR857'),
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (cancelledFlight) {
        expect(cancelledFlight.status, equals(FlightStatus.cancelled));
      });
    });

    test('should validate boarding eligibility successfully', () async {
      final now = TZDateTime.now(local);
      final boardingTime = now.subtract(
        const Duration(minutes: 30),
      ); // Boarding started 30 min ago
      final departureTime = now.add(
        const Duration(minutes: 30),
      ); // Departs in 30 min

      final activeSchedule = FlightSchedule.create(
        departureTime: departureTime,
        boardingTime: boardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
      );

      final activeFlight = Flight.create(
        flightNumber: 'BR857',
        schedule: activeSchedule,
        aircraftType: 'A350',
      ).updateStatus(FlightStatus.boarding);

      when(
        mockRepository.findByFlightNumber(any),
      ).thenAnswer((_) async => Right(activeFlight));

      final result = await statusService.validateBoardingEligibility(
        FlightNumber.create('BR857'),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not fail'),
        (isEligible) => expect(isEligible, isTrue),
      );
    });

    test(
      'should validate boarding eligibility as false for cancelled flight',
      () async {
        final cancelledFlight = testFlight.cancel();

        when(
          mockRepository.findByFlightNumber(any),
        ).thenAnswer((_) async => Right(cancelledFlight));

        final result = await statusService.validateBoardingEligibility(
          FlightNumber.create('BR857'),
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not fail'),
          (isEligible) => expect(isEligible, isFalse),
        );
      },
    );

    test('should handle repository failure', () async {
      when(
        mockRepository.findByFlightNumber(any),
      ).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

      final result = await statusService.updateFlightStatus(
        flightNumber: FlightNumber.create('BR857'),
        newStatus: FlightStatus.boarding,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (flight) => fail('Should fail'),
      );
    });
  });
}
