import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/enums/pass_status.dart';
import 'package:app/features/boarding_pass/infrastructure/entities/boarding_pass_entity.dart';
import 'package:app/features/boarding_pass/repositories/boarding_pass_repository.dart';
import 'package:app/features/boarding_pass/value_objects/pass_id.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:app/objectbox.g.dart';
import 'package:dartz/dartz.dart' hide Order;
import 'package:logger/logger.dart';

/// Concrete implementation of BoardingPassRepository using ObjectBox
/// Follows official ObjectBox repository patterns with offline-first strategy
class BoardingPassRepositoryImpl implements BoardingPassRepository {
  static final Logger _logger = Logger();

  final ObjectBox _objectBox;
  late final Box<BoardingPassEntity> _boardingPassBox;

  BoardingPassRepositoryImpl(this._objectBox) {
    _boardingPassBox = _objectBox.store.box<BoardingPassEntity>();
  }

  @override
  Future<Either<Failure, BoardingPass?>> findByPassId(PassId passId) async {
    try {
      _logger.d('Finding boarding pass by ID: ${passId.value}');

      final query = _boardingPassBox
          .query(BoardingPassEntity_.passId.equals(passId.value))
          .build();

      try {
        final entity = query.findFirst();

        if (entity == null) {
          _logger.d('Boarding pass not found: ${passId.value}');
          return const Right(null);
        }

        final boardingPass = entity.toDomain();
        _logger.d('Boarding pass found: ${boardingPass.passId.value}');

        return Right(boardingPass);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error finding boarding pass by ID',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to find boarding pass: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BoardingPass>>> findByMemberNumber(
    MemberNumber memberNumber,
  ) async {
    try {
      _logger.d('Finding boarding passes for member: ${memberNumber.value}');

      final query = _boardingPassBox
          .query(BoardingPassEntity_.memberNumber.equals(memberNumber.value))
          .order(BoardingPassEntity_.issueTime, flags: Order.descending)
          .build();

      try {
        final entities = query.find();
        final boardingPasses = entities
            .map((entity) => entity.toDomain())
            .toList();

        _logger.d('Found ${boardingPasses.length} boarding passes for member');
        return Right(boardingPasses);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error finding boarding passes by member',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to find boarding passes: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BoardingPass>>> findByFlightNumber(
    FlightNumber flightNumber,
  ) async {
    try {
      _logger.d('Finding boarding passes for flight: ${flightNumber.value}');

      final query = _boardingPassBox
          .query(BoardingPassEntity_.flightNumber.equals(flightNumber.value))
          .order(BoardingPassEntity_.seatNumber)
          .build();

      try {
        final entities = query.find();
        final boardingPasses = entities
            .map((entity) => entity.toDomain())
            .toList();

        _logger.d('Found ${boardingPasses.length} boarding passes for flight');
        return Right(boardingPasses);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error finding boarding passes by flight',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to find boarding passes: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BoardingPass>>> findActiveBoardingPasses(
    MemberNumber memberNumber,
  ) async {
    try {
      _logger.d(
        'Finding active boarding passes for member: ${memberNumber.value}',
      );

      // Query for active statuses (issued, activated)
      final activeStatuses = [
        PassStatus.issued.value,
        PassStatus.activated.value,
      ];

      final query = _boardingPassBox
          .query(
            BoardingPassEntity_.memberNumber.equals(memberNumber.value) &
                BoardingPassEntity_.status.oneOf(activeStatuses),
          )
          .order(BoardingPassEntity_.departureTime)
          .build();

      try {
        final entities = query.find();
        final boardingPasses = entities
            .map((entity) => entity.toDomain())
            .where((pass) => pass.isActive)
            .toList();

        _logger.d('Found ${boardingPasses.length} active boarding passes');
        return Right(boardingPasses);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error finding active boarding passes',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to find active boarding passes: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> save(BoardingPass boardingPass) async {
    try {
      _logger.d('Saving boarding pass: ${boardingPass.passId.value}');

      // Use ObjectBox replace strategy for updates
      _objectBox.store.runInTransaction(TxMode.write, () {
        final entity = BoardingPassEntity.fromDomain(boardingPass);
        _boardingPassBox.put(entity);
        _logger.d('Saved boarding pass: ${boardingPass.passId.value}');
      });

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error saving boarding pass', error: e, stackTrace: stackTrace);
      return Left(DatabaseFailure('Failed to save boarding pass: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveLocally(BoardingPass boardingPass) async {
    // For ObjectBox, local save is the same as regular save
    return save(boardingPass);
  }

  @override
  Future<Either<Failure, bool>> exists(PassId passId) async {
    try {
      _logger.d('Checking if boarding pass exists: ${passId.value}');

      final query = _boardingPassBox
          .query(BoardingPassEntity_.passId.equals(passId.value))
          .build();

      try {
        final count = query.count();
        final exists = count > 0;

        _logger.d('Boarding pass exists: $exists');
        return Right(exists);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error checking boarding pass existence',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(
        DatabaseFailure('Failed to check boarding pass existence: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> syncWithServer() async {
    try {
      _logger.d('Syncing boarding passes with server');

      // Placeholder for server sync implementation
      await _objectBox.store.runInTransactionAsync(TxMode.write, (s, p) async {
        // Example sync logic:
        // 1. Get local changes since last sync
        // 2. Push changes to server
        // 3. Pull server updates
        // 4. Resolve conflicts using business rules
      }, {});

      _logger.d('Boarding pass sync completed');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error syncing with server', error: e, stackTrace: stackTrace);
      return Left(NetworkFailure('Failed to sync with server: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(PassId passId) async {
    try {
      _logger.d('Soft deleting boarding pass: ${passId.value}');

      final findResult = await findByPassId(passId);

      return findResult.fold((failure) => Left(failure), (boardingPass) async {
        if (boardingPass == null) {
          return Left(NotFoundFailure('Boarding pass not found'));
        }

        // Soft delete by cancelling the pass
        final cancelledPass = boardingPass.cancel();
        return save(cancelledPass);
      });
    } catch (e, stackTrace) {
      _logger.e(
        'Error deleting boarding pass',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to delete boarding pass: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BoardingPass>>>
  findPassesRequiringStatusUpdate() async {
    try {
      _logger.d('Finding boarding passes requiring status update');

      final now = DateTime.now().toUtc();
      final activeStatuses = [
        PassStatus.issued.value,
        PassStatus.activated.value,
      ];

      // Find active passes where departure time has passed
      final query = _boardingPassBox
          .query(
            BoardingPassEntity_.status.oneOf(activeStatuses) &
                BoardingPassEntity_.departureTime.lessThan(
                  now.millisecondsSinceEpoch,
                ),
          )
          .build();

      try {
        final entities = query.find();
        final boardingPasses = entities
            .map((entity) => entity.toDomain())
            .toList();

        _logger.d(
          'Found ${boardingPasses.length} passes requiring status update',
        );
        return Right(boardingPasses);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error finding passes requiring update',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(
        DatabaseFailure('Failed to find passes requiring update: $e'),
      );
    }
  }

  /// Get reactive stream of boarding passes for UI updates
  Stream<List<BoardingPass>> watchBoardingPasses(MemberNumber memberNumber) {
    return _boardingPassBox
        .query(BoardingPassEntity_.memberNumber.equals(memberNumber.value))
        .watch(triggerImmediately: true)
        .map(
          (query) => query.find().map((entity) => entity.toDomain()).toList(),
        );
  }

  /// Get reactive stream of active boarding passes
  Stream<List<BoardingPass>> watchActiveBoardingPasses(
    MemberNumber memberNumber,
  ) {
    final activeStatuses = [
      PassStatus.issued.value,
      PassStatus.activated.value,
    ];

    return _boardingPassBox
        .query(
          BoardingPassEntity_.memberNumber.equals(memberNumber.value) &
              BoardingPassEntity_.status.oneOf(activeStatuses),
        )
        .watch(triggerImmediately: true)
        .map(
          (query) => query
              .find()
              .map((entity) => entity.toDomain())
              .where((pass) => pass.isActive)
              .toList(),
        );
  }

  /// Bulk save operation using transactions for performance
  Future<Either<Failure, void>> saveMany(
    List<BoardingPass> boardingPasses,
  ) async {
    try {
      _logger.d('Bulk saving ${boardingPasses.length} boarding passes');

      await _objectBox.store.runInTransactionAsync(TxMode.write, (s, p) async {
        final entities = boardingPasses
            .map(BoardingPassEntity.fromDomain)
            .toList();
        _boardingPassBox.putMany(entities);
      }, {});

      _logger.d('Bulk save completed');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error in bulk save', error: e, stackTrace: stackTrace);
      return Left(DatabaseFailure('Failed to save boarding passes: $e'));
    }
  }

  /// Get boarding passes by status
  Future<Either<Failure, List<BoardingPass>>> findByStatus(
    PassStatus status,
  ) async {
    try {
      _logger.d('Finding boarding passes by status: ${status.value}');

      final query = _boardingPassBox
          .query(BoardingPassEntity_.status.equals(status.value))
          .order(BoardingPassEntity_.issueTime, flags: Order.descending)
          .build();

      try {
        final entities = query.find();
        final boardingPasses = entities
            .map((entity) => entity.toDomain())
            .toList();

        _logger.d(
          'Found ${boardingPasses.length} passes with status: ${status.value}',
        );
        return Right(boardingPasses);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error finding passes by status',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to find passes by status: $e'));
    }
  }

  /// Get boarding passes departing soon
  Future<Either<Failure, List<BoardingPass>>> findDepartingSoon(
    Duration timeWindow,
  ) async {
    try {
      _logger.d(
        'Finding boarding passes departing within ${timeWindow.inHours} hours',
      );

      final now = DateTime.now().toUtc();
      final futureTime = now.add(timeWindow);

      final activeStatuses = [
        PassStatus.issued.value,
        PassStatus.activated.value,
      ];

      final query = _boardingPassBox
          .query(
            BoardingPassEntity_.status.oneOf(activeStatuses) &
                BoardingPassEntity_.departureTime.between(
                  now.millisecondsSinceEpoch,
                  futureTime.millisecondsSinceEpoch,
                ),
          )
          .order(BoardingPassEntity_.departureTime)
          .build();

      try {
        final entities = query.find();
        final boardingPasses = entities
            .map((entity) => entity.toDomain())
            .where((pass) => pass.isActive)
            .toList();

        _logger.d('Found ${boardingPasses.length} passes departing soon');
        return Right(boardingPasses);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error finding departing passes',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to find departing passes: $e'));
    }
  }
}
