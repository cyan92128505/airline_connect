import 'package:app/core/failures/failure.dart';
import 'package:app/features/flight/entities/flight.dart';
import 'package:app/features/flight/enums/flight_status.dart';
import 'package:app/features/flight/value_objects/flight_number.dart';
import 'package:dartz/dartz.dart';

/// Flight repository interface
/// Follows Repository pattern for aggregate persistence
abstract class FlightRepository {
  /// Get flight by flight number (primary lookup)
  Future<Either<Failure, Flight?>> findByFlightNumber(
    FlightNumber flightNumber,
  );

  /// Get flights by departure airport and date
  Future<Either<Failure, List<Flight>>> findByDepartureAirportAndDate(
    String airportCode,
    DateTime date,
  );

  /// Get flights by arrival airport and date
  Future<Either<Failure, List<Flight>>> findByArrivalAirportAndDate(
    String airportCode,
    DateTime date,
  );

  /// Get active flights (not cancelled or completed)
  Future<Either<Failure, List<Flight>>> findActiveFlights();

  /// Save flight (create or update)
  Future<Either<Failure, void>> save(Flight flight);

  /// Save flight locally for offline support
  Future<Either<Failure, void>> saveLocally(Flight flight);

  /// Check if flight exists
  Future<Either<Failure, bool>> exists(FlightNumber flightNumber);

  /// Sync with remote server
  Future<Either<Failure, void>> syncWithServer();

  /// Bulk update flight statuses
  Future<Either<Failure, void>> bulkUpdateStatuses(
    Map<FlightNumber, FlightStatus> statusUpdates,
  );
}
