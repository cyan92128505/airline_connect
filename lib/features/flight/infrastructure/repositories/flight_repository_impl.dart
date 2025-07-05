import 'package:app/core/failures/failure.dart';
import 'package:app/features/flight/entities/flight.dart';
import 'package:app/features/flight/enums/flight_status.dart';
import 'package:app/features/flight/infrastructure/entities/flight_entity.dart';
import 'package:app/features/flight/repositories/flight_repository.dart';
import 'package:app/features/flight/value_objects/flight_number.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:app/objectbox.g.dart';
import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

/// Concrete implementation of FlightRepository using ObjectBox
/// Follows official ObjectBox repository patterns
class FlightRepositoryImpl implements FlightRepository {
  static final Logger _logger = Logger();

  final ObjectBox _objectBox;
  late final Box<FlightEntity> _flightBox;

  FlightRepositoryImpl(this._objectBox) {
    _flightBox = _objectBox.store.box<FlightEntity>();
  }

  @override
  Future<Either<Failure, Flight?>> findByFlightNumber(
    FlightNumber flightNumber,
  ) async {
    try {
      _logger.d('Finding flight by number: ${flightNumber.value}');

      final query = _flightBox
          .query(FlightEntity_.flightNumber.equals(flightNumber.value))
          .build();

      try {
        final flightEntity = query.findFirst();

        if (flightEntity == null) {
          _logger.d('Flight not found: ${flightNumber.value}');
          return const Right(null);
        }

        final flight = flightEntity.toDomain();
        _logger.d('Flight found: ${flight.flightNumber.value}');

        return Right(flight);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error finding flight by number',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to find flight: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Flight>>> findByDepartureAirportAndDate(
    String airportCode,
    DateTime date,
  ) async {
    try {
      _logger.d(
        'Finding flights by departure airport: $airportCode, date: $date',
      );

      // Create date range for the entire day
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final query = _flightBox
          .query(
            FlightEntity_.departureAirport.equals(airportCode.toUpperCase()) &
                FlightEntity_.departureTime.between(
                  startOfDay.millisecondsSinceEpoch,
                  endOfDay.millisecondsSinceEpoch,
                ),
          )
          .order(FlightEntity_.departureTime)
          .build();

      try {
        final flightEntities = query.find();
        final flights = flightEntities
            .map((entity) => entity.toDomain())
            .toList();

        _logger.d('Found ${flights.length} flights for $airportCode on $date');
        return Right(flights);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error finding flights by departure',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to find flights: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Flight>>> findByArrivalAirportAndDate(
    String airportCode,
    DateTime date,
  ) async {
    try {
      _logger.d(
        'Finding flights by arrival airport: $airportCode, date: $date',
      );

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final query = _flightBox
          .query(
            FlightEntity_.arrivalAirport.equals(airportCode.toUpperCase()) &
                FlightEntity_.departureTime.between(
                  startOfDay.millisecondsSinceEpoch,
                  endOfDay.millisecondsSinceEpoch,
                ),
          )
          .order(FlightEntity_.departureTime)
          .build();

      try {
        final flightEntities = query.find();
        final flights = flightEntities
            .map((entity) => entity.toDomain())
            .toList();

        _logger.d(
          'Found ${flights.length} arrival flights for $airportCode on $date',
        );
        return Right(flights);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error finding flights by arrival',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to find flights: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Flight>>> findActiveFlights() async {
    try {
      _logger.d('Finding active flights');

      // Query for flights that are not in terminal states
      final activeStatuses = [
        FlightStatus.scheduled.value,
        FlightStatus.delayed.value,
        FlightStatus.boarding.value,
        FlightStatus.departed.value,
      ];

      final query = _flightBox
          .query(FlightEntity_.status.oneOf(activeStatuses))
          .order(FlightEntity_.departureTime)
          .build();

      try {
        final flightEntities = query.find();
        final flights = flightEntities
            .map((entity) => entity.toDomain())
            .where((flight) => flight.isActive)
            .toList();

        _logger.d('Found ${flights.length} active flights');
        return Right(flights);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error finding active flights',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to find active flights: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> save(Flight flight) async {
    try {
      _logger.d('Saving flight: ${flight.flightNumber.value}');

      // Use ObjectBox replace strategy for updates
      _objectBox.store.runInTransaction(TxMode.write, () {
        final entity = FlightEntity.fromDomain(flight);
        _flightBox.put(entity);
        _logger.d('Saved flight: ${flight.flightNumber.value}');
      });

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error saving flight', error: e, stackTrace: stackTrace);
      return Left(DatabaseFailure('Failed to save flight: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveLocally(Flight flight) async {
    // For ObjectBox, local save is the same as regular save
    return save(flight);
  }

  @override
  Future<Either<Failure, bool>> exists(FlightNumber flightNumber) async {
    try {
      _logger.d('Checking if flight exists: ${flightNumber.value}');

      final query = _flightBox
          .query(FlightEntity_.flightNumber.equals(flightNumber.value))
          .build();

      try {
        final count = query.count();
        final exists = count > 0;

        _logger.d('Flight exists: $exists');
        return Right(exists);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error checking flight existence',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to check flight existence: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> syncWithServer() async {
    try {
      _logger.d('Syncing flights with server');

      // Placeholder for server sync implementation
      await _objectBox.store.runInTransactionAsync(TxMode.write, (s, p) async {
        // Example bulk sync operation
        // final serverFlights = await _remoteDataSource.getFlights();
        // final localEntities = serverFlights.map(FlightEntity.fromDomain).toList();
        // _flightBox.putMany(localEntities);
      }, {});

      _logger.d('Flight sync completed');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error syncing with server', error: e, stackTrace: stackTrace);
      return Left(NetworkFailure('Failed to sync with server: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> bulkUpdateStatuses(
    Map<FlightNumber, FlightStatus> statusUpdates,
  ) async {
    try {
      _logger.d('Bulk updating ${statusUpdates.length} flight statuses');

      await _objectBox.store.runInTransactionAsync(TxMode.write, (s, p) async {
        for (final entry in statusUpdates.entries) {
          final flightNumber = entry.key;
          final newStatus = entry.value;

          final query = _flightBox
              .query(FlightEntity_.flightNumber.equals(flightNumber.value))
              .build();

          try {
            final entity = query.findFirst();
            if (entity != null) {
              // Create updated domain object to maintain business rules
              final currentFlight = entity.toDomain();
              final updatedFlight = currentFlight.updateStatus(newStatus);

              // Update entity from domain
              entity.updateFromDomain(updatedFlight);
              _flightBox.put(entity);
            }
          } finally {
            query.close();
          }
        }
      }, {});

      _logger.d('Bulk status update completed');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e(
        'Error in bulk status update',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to update flight statuses: $e'));
    }
  }

  /// Get reactive stream of flights for UI updates
  Stream<List<Flight>> watchFlights() {
    return _flightBox
        .query()
        .watch(triggerImmediately: true)
        .map(
          (query) => query.find().map((entity) => entity.toDomain()).toList(),
        );
  }

  /// Get reactive stream of active flights
  Stream<List<Flight>> watchActiveFlights() {
    final activeStatuses = [
      FlightStatus.scheduled.value,
      FlightStatus.delayed.value,
      FlightStatus.boarding.value,
      FlightStatus.departed.value,
    ];

    return _flightBox
        .query(FlightEntity_.status.oneOf(activeStatuses))
        .watch(triggerImmediately: true)
        .map(
          (query) => query
              .find()
              .map((entity) => entity.toDomain())
              .where((flight) => flight.isActive)
              .toList(),
        );
  }

  /// Bulk save operation using transactions for performance
  Future<Either<Failure, void>> saveMany(List<Flight> flights) async {
    try {
      _logger.d('Bulk saving ${flights.length} flights');

      await _objectBox.store.runInTransactionAsync(TxMode.write, (s, p) async {
        final entities = flights.map(FlightEntity.fromDomain).toList();
        _flightBox.putMany(entities);
      }, {});

      _logger.d('Bulk save completed');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error in bulk save', error: e, stackTrace: stackTrace);
      return Left(DatabaseFailure('Failed to save flights: $e'));
    }
  }

  /// Get flights by status
  Future<Either<Failure, List<Flight>>> findByStatus(
    FlightStatus status,
  ) async {
    try {
      _logger.d('Finding flights by status: ${status.value}');

      final query = _flightBox
          .query(FlightEntity_.status.equals(status.value))
          .order(FlightEntity_.departureTime)
          .build();

      try {
        final flightEntities = query.find();
        final flights = flightEntities
            .map((entity) => entity.toDomain())
            .toList();

        _logger.d(
          'Found ${flights.length} flights with status: ${status.value}',
        );
        return Right(flights);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error finding flights by status',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to find flights by status: $e'));
    }
  }

  /// Get flights departing in next N hours
  Future<Either<Failure, List<Flight>>> findDepartingSoon(int hours) async {
    try {
      _logger.d('Finding flights departing in next $hours hours');

      final now = DateTime.now();
      final futureTime = now.add(Duration(hours: hours));

      final query = _flightBox
          .query(
            FlightEntity_.departureTime.between(
              now.millisecondsSinceEpoch,
              futureTime.millisecondsSinceEpoch,
            ),
          )
          .order(FlightEntity_.departureTime)
          .build();

      try {
        final flightEntities = query.find();
        final flights = flightEntities
            .map((entity) => entity.toDomain())
            .where((flight) => flight.isActive)
            .toList();

        _logger.d('Found ${flights.length} flights departing soon');
        return Right(flights);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error finding departing flights',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to find departing flights: $e'));
    }
  }
}
