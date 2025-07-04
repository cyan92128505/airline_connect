import 'package:dartz/dartz.dart';
import 'package:timezone/timezone.dart';
import '../entities/flight.dart';
import '../value_objects/flight_number.dart';
import '../enums/flight_status.dart';
import '../repositories/flight_repository.dart';
import '../../../core/failures/failure.dart';
import '../../../core/exceptions/domain_exception.dart';

class FlightStatusService {
  final FlightRepository _flightRepository;

  const FlightStatusService(this._flightRepository);

  Future<Either<Failure, Flight>> updateFlightStatus({
    required FlightNumber flightNumber,
    required FlightStatus newStatus,
  }) async {
    try {
      final flightResult = await _flightRepository.findByFlightNumber(
        flightNumber,
      );

      return flightResult.fold((failure) => Left(failure), (flight) async {
        if (flight == null) {
          return Left(
            NotFoundFailure('Flight not found: ${flightNumber.value}'),
          );
        }

        final updatedFlight = flight.updateStatus(newStatus);

        final saveResult = await _flightRepository.save(updatedFlight);

        return saveResult.fold(
          (failure) => Left(failure),
          (_) => Right(updatedFlight),
        );
      });
    } on DomainException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to update flight status: $e'));
    }
  }

  Future<Either<Failure, Flight>> delayFlight({
    required FlightNumber flightNumber,
    required Duration delayDuration,
  }) async {
    try {
      final flightResult = await _flightRepository.findByFlightNumber(
        flightNumber,
      );

      return flightResult.fold((failure) => Left(failure), (flight) async {
        if (flight == null) {
          return Left(
            NotFoundFailure('Flight not found: ${flightNumber.value}'),
          );
        }

        final delayedFlight = flight.delay(delayDuration);

        final saveResult = await _flightRepository.save(delayedFlight);

        return saveResult.fold(
          (failure) => Left(failure),
          (_) => Right(delayedFlight),
        );
      });
    } on DomainException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to delay flight: $e'));
    }
  }

  Future<Either<Failure, Flight>> cancelFlight(
    FlightNumber flightNumber,
  ) async {
    try {
      final flightResult = await _flightRepository.findByFlightNumber(
        flightNumber,
      );

      return flightResult.fold((failure) => Left(failure), (flight) async {
        if (flight == null) {
          return Left(
            NotFoundFailure('Flight not found: ${flightNumber.value}'),
          );
        }

        final cancelledFlight = flight.cancel();

        final saveResult = await _flightRepository.save(cancelledFlight);

        return saveResult.fold(
          (failure) => Left(failure),
          (_) => Right(cancelledFlight),
        );
      });
    } on DomainException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to cancel flight: $e'));
    }
  }

  Future<Either<Failure, bool>> validateBoardingEligibility(
    FlightNumber flightNumber,
  ) async {
    final flightResult = await _flightRepository.findByFlightNumber(
      flightNumber,
    );

    return flightResult.fold((failure) => Left(failure), (flight) {
      if (flight == null) {
        return Left(NotFoundFailure('Flight not found: ${flightNumber.value}'));
      }

      final isEligible = flight.isActive && flight.isBoardingEligible;

      return Right(isEligible);
    });
  }

  Future<Either<Failure, List<Flight>>> autoUpdateStatuses() async {
    try {
      final activeFlightsResult = await _flightRepository.findActiveFlights();

      return activeFlightsResult.fold((failure) => Left(failure), (
        flights,
      ) async {
        final updatedFlights = <Flight>[];
        final now = TZDateTime.now(local);

        for (final flight in flights) {
          Flight? updatedFlight;

          if (flight.status == FlightStatus.scheduled ||
              flight.status == FlightStatus.delayed) {
            if (flight.schedule.isInBoardingWindow()) {
              updatedFlight = flight.updateStatus(FlightStatus.boarding);
            }
          } else if (flight.status == FlightStatus.boarding) {
            if (now.isAfter(flight.schedule.departureTime)) {
              updatedFlight = flight.updateStatus(FlightStatus.departed);
            }
          }

          if (updatedFlight != null) {
            await _flightRepository.save(updatedFlight);
            updatedFlights.add(updatedFlight);
          }
        }

        return Right(updatedFlights);
      });
    } catch (e) {
      return Left(UnknownFailure('Failed to auto-update flight statuses: $e'));
    }
  }
}
