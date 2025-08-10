import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/domain/datasources/boarding_pass_local_data_source.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/infrastructure/entities/boarding_pass_entity.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:app/objectbox.g.dart';
import 'package:dartz/dartz.dart' hide Order;
import 'package:logger/logger.dart';

/// ObjectBox implementation of local data source
class ObjectBoxBoardingPassLocalDataSource
    implements BoardingPassLocalDataSource {
  static final Logger _logger = Logger();

  final ObjectBox _objectBox;
  late final Box<BoardingPassEntity> _boardingPassBox;

  ObjectBoxBoardingPassLocalDataSource(this._objectBox) {
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
  Future<Either<Failure, List<BoardingPass>>>
  findPassesRequiringStatusUpdate() async {
    try {
      _logger.d('Finding boarding passes requiring status update');

      final now = DateTime.now().toUtc();
      final activeStatuses = [
        PassStatus.issued.value,
        PassStatus.activated.value,
      ];

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

  @override
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

  @override
  Stream<List<BoardingPass>> watchBoardingPasses(MemberNumber memberNumber) {
    return _boardingPassBox
        .query(BoardingPassEntity_.memberNumber.equals(memberNumber.value))
        .watch(triggerImmediately: true)
        .map(
          (query) => query.find().map((entity) => entity.toDomain()).toList(),
        );
  }

  @override
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
}
