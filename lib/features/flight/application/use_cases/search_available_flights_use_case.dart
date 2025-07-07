import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/features/flight/application/dtos/flight_dto.dart';
import 'package:app/features/flight/application/dtos/flight_search_dto.dart';
import 'package:app/features/flight/entities/flight.dart';
import 'package:app/features/flight/repositories/flight_repository.dart';
import 'package:app/features/flight/value_objects/airport_code.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

/// Use case for searching available flights for boarding pass issuance
/// Simplified to support boarding pass business only
@injectable
class SearchAvailableFlightsUseCase
    implements UseCase<List<FlightDTO>, FlightSearchDTO> {
  final FlightRepository _flightRepository;

  const SearchAvailableFlightsUseCase(this._flightRepository);

  @override
  Future<Either<Failure, List<FlightDTO>>> call(FlightSearchDTO params) async {
    try {
      // Validate search parameters
      final validationResult = _validateSearchParams(params);
      if (validationResult != null) {
        return Left(validationResult);
      }

      // Search flights based on simple criteria
      List<Flight> flights = [];

      if (params.departureAirport != null && params.departureDate != null) {
        // Search by departure airport and date
        flights = await _searchByDepartureAirportAndDate(params);
      } else {
        // Get available flights (basic query)
        final result = await _flightRepository.findActiveFlights();
        return result.fold(
          (failure) => Left(failure),
          (flightList) => Right(_convertFlightsToDTOs(flightList)),
        );
      }

      return Right(_convertFlightsToDTOs(flights));
    } catch (e) {
      return Left(UnknownFailure('Failed to search flights: $e'));
    }
  }

  /// Search flights by departure airport and date
  Future<List<Flight>> _searchByDepartureAirportAndDate(
    FlightSearchDTO params,
  ) async {
    try {
      final airportCode = AirportCode.create(params.departureAirport!);
      final searchDate = DateTime.parse(params.departureDate!);

      final result = await _flightRepository.findByDepartureAirportAndDate(
        airportCode.value,
        searchDate,
      );

      return result.fold(
        (failure) => throw Exception(failure.message),
        (flights) => flights,
      );
    } on DomainException catch (e) {
      throw Exception('Invalid search parameters: ${e.message}');
    }
  }

  /// Convert flights to DTOs
  List<FlightDTO> _convertFlightsToDTOs(List<Flight> flights) {
    return flights.map(FlightDTOExtensions.fromDomain).toList();
  }

  /// Validate search parameters
  Failure? _validateSearchParams(FlightSearchDTO params) {
    // If searching by airport, date must also be provided
    if (params.departureAirport != null && params.departureDate == null) {
      return ValidationFailure(
        'Departure date must be provided when searching by airport',
      );
    }

    // Validate date format if provided
    if (params.departureDate != null) {
      try {
        DateTime.parse(params.departureDate!);
      } catch (e) {
        return ValidationFailure(
          'Invalid date format: ${params.departureDate}',
        );
      }
    }

    return null;
  }
}
