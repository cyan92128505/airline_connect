import 'package:app/core/failures/failure.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/infrastructure/entities/member_entity.dart';
import 'package:app/features/member/domain/repositories/member_repository.dart';
import 'package:app/features/member/domain/value_objects/member_id.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:app/objectbox.g.dart';
import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

/// Concrete implementation of MemberRepository using ObjectBox
/// Follows official ObjectBox repository patterns
class MemberRepositoryImpl implements MemberRepository {
  static final Logger _logger = Logger();

  final ObjectBox _objectBox;
  late final Box<MemberEntity> _memberBox;

  MemberRepositoryImpl(this._objectBox) {
    _memberBox = _objectBox.memberBox;
  }

  @override
  Future<Either<Failure, Member?>> findByMemberNumber(
    MemberNumber memberNumber,
  ) async {
    try {
      _logger.d('Finding member by number: ${memberNumber.value}');

      // Use ObjectBox query builder with proper indexing
      final query = _memberBox
          .query(MemberEntity_.memberNumber.equals(memberNumber.value))
          .build();

      try {
        final memberEntity = query.findFirst();

        if (memberEntity == null) {
          _logger.d('Member not found: ${memberNumber.value}');
          return const Right(null);
        }

        final member = memberEntity.toDomain();
        _logger.d('Member found: ${member.memberId.value}');

        return Right(member);
      } finally {
        // Always close query to free resources
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error finding member by number',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to find member: $e'));
    }
  }

  @override
  Future<Either<Failure, Member?>> findById(MemberId memberId) async {
    try {
      _logger.d('Finding member by ID: ${memberId.value}');

      final query = _memberBox
          .query(MemberEntity_.memberId.equals(memberId.value))
          .build();

      try {
        final memberEntity = query.findFirst();

        if (memberEntity == null) {
          _logger.d('Member not found: ${memberId.value}');
          return const Right(null);
        }

        final member = memberEntity.toDomain();
        return Right(member);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e('Error finding member by ID', error: e, stackTrace: stackTrace);
      return Left(DatabaseFailure('Failed to find member: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> save(Member member) async {
    try {
      _logger.d('Saving member: ${member.memberId.value}');

      // Use transaction for data consistency
      _objectBox.store.runInTransaction(TxMode.write, () {
        // Find existing entity by business key (memberId)
        final existingQuery = _memberBox
            .query(MemberEntity_.memberId.equals(member.memberId.value))
            .build();

        try {
          final existingEntity = existingQuery.findFirst();

          if (existingEntity != null) {
            // Update existing entity preserving ObjectBox ID
            existingEntity.updateFromDomain(member);
            _memberBox.put(existingEntity);
            _logger.d('Updated existing member: ${member.memberId.value}');
          } else {
            // Create new entity
            final newEntity = MemberEntity.fromDomain(member);
            _memberBox.put(newEntity);
            _logger.d('Created new member: ${member.memberId.value}');
          }
        } finally {
          existingQuery.close();
        }
      });

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error saving member', error: e, stackTrace: stackTrace);
      return Left(DatabaseFailure('Failed to save member: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveLocally(Member member) async {
    // For ObjectBox, local save is the same as regular save
    return save(member);
  }

  @override
  Future<Either<Failure, bool>> exists(MemberNumber memberNumber) async {
    try {
      _logger.d('Checking if member exists: ${memberNumber.value}');

      final query = _memberBox
          .query(MemberEntity_.memberNumber.equals(memberNumber.value))
          .build();

      try {
        final count = query.count();
        final exists = count > 0;

        _logger.d('Member exists: $exists');
        return Right(exists);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error checking member existence',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to check member existence: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> syncWithServer() async {
    try {
      _logger.d('Syncing members with server');

      // Placeholder for server sync implementation
      // In real implementation, this would:
      // 1. Fetch data from server
      // 2. Compare with local data
      // 3. Perform batch operations using transactions

      await _objectBox.store.runInTransactionAsync(TxMode.write, (
        store,
        p,
      ) async {
        // Example bulk sync operation
        // final serverMembers = await _remoteDataSource.getMembers();
        // final localEntities = serverMembers.map(MemberEntity.fromDomain).toList();
        // _memberBox.putMany(localEntities);

        return null;
      }, {});

      _logger.d('Member sync completed');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error syncing with server', error: e, stackTrace: stackTrace);
      return Left(NetworkFailure('Failed to sync with server: $e'));
    }
  }

  /// Get reactive stream of members for UI updates
  /// Following ObjectBox streaming best practices
  Stream<List<Member>> watchMembers() {
    return _memberBox
        .query()
        .watch(triggerImmediately: true)
        .map(
          (query) => query.find().map((entity) => entity.toDomain()).toList(),
        );
  }

  /// Bulk save operation using transactions for performance
  Future<Either<Failure, void>> saveMany(List<Member> members) async {
    try {
      _logger.d('Bulk saving ${members.length} members');

      await _objectBox.store.runInTransactionAsync(TxMode.write, (s, p) async {
        final entities = members.map(MemberEntity.fromDomain).toList();
        _memberBox.putMany(entities);
      }, {});

      _logger.d('Bulk save completed');
      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error in bulk save', error: e, stackTrace: stackTrace);
      return Left(DatabaseFailure('Failed to save members: $e'));
    }
  }
}
