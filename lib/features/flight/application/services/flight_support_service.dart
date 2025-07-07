import 'package:app/core/failures/failure.dart';
import 'package:app/features/flight/application/dtos/flight_dto.dart';
import 'package:app/features/flight/application/dtos/flight_search_dto.dart';
import 'package:app/features/flight/application/use_cases/get_flight_details_use_case.dart';
import 'package:app/features/flight/application/use_cases/search_available_flights_use_case.dart';
import 'package:app/features/flight/domain/enums/flight_status.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

/// Flight Support Service - provides flight data to support boarding pass operations
/// This is NOT a flight management service, but a support service for BoardingPass aggregate
@injectable
class FlightSupportService {
  final GetFlightDetailsUseCase _getFlightDetailsUseCase;
  final SearchAvailableFlightsUseCase _searchAvailableFlightsUseCase;

  const FlightSupportService(
    this._getFlightDetailsUseCase,
    this._searchAvailableFlightsUseCase,
  );

  /// Get flight details for boarding pass operations
  Future<Either<Failure, FlightDTO>> getFlightForBoardingPass(
    String flightNumber,
  ) async {
    return _getFlightDetailsUseCase(flightNumber);
  }

  /// Search available flights for booking/boarding pass issuance
  Future<Either<Failure, List<FlightDTO>>> searchAvailableFlights({
    String? departureAirport,
    String? departureDate,
    int maxResults = 20,
  }) async {
    final searchParams = FlightSearchDTO(
      departureAirport: departureAirport,
      departureDate: departureDate,
      maxResults: maxResults,
    );

    return _searchAvailableFlightsUseCase(searchParams);
  }

  /// Get today's departures from specific airport
  Future<Either<Failure, List<FlightDTO>>> getTodaysDepartures(
    String airportCode,
  ) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return searchAvailableFlights(
      departureAirport: airportCode,
      departureDate: today,
    );
  }

  /// Check if flight exists and is available for boarding pass issuance
  Future<Either<Failure, bool>> isFlightAvailableForBoardingPass(
    String flightNumber,
  ) async {
    final result = await getFlightForBoardingPass(flightNumber);

    return result.fold((failure) => Left(failure), (flight) {
      // Business rule: Flight must be scheduled or boarding to issue boarding pass
      final isAvailable =
          flight.status == FlightStatus.scheduled ||
          flight.status == FlightStatus.boarding;
      return Right(isAvailable);
    });
  }
}
