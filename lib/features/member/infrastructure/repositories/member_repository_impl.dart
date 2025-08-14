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
class MemberRepositoryImpl implements MemberRepository {
  static final Logger _logger = Logger();

  final ObjectBox _objectBox;

  MemberRepositoryImpl(this._objectBox) {
    _logger.d('MemberRepositoryImpl initialized with lazy ObjectBox strategy');
  }

  /// Safe access to member box with validation
  Box<MemberEntity> get _memberBox {
    try {
      return _objectBox.memberBox;
    } catch (e) {
      _logger.e('Failed to access member box: $e');
      throw StateError('Member box is not accessible: $e');
    }
  }

  @override
  Future<Either<Failure, Member?>> findByMemberNumber(
    MemberNumber memberNumber,
  ) async {
    try {
      // Validate ObjectBox health before operation
      if (!_objectBox.isHealthy()) {
        throw StateError('ObjectBox is not healthy');
      }

      // Use ObjectBox query builder with proper indexing
      final query = _memberBox
          .query(MemberEntity_.memberNumber.equals(memberNumber.value))
          .build();

      try {
        final memberEntity = query.findFirst();

        if (memberEntity == null) {
          return const Right(null);
        }

        final member = memberEntity.toDomain();
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

      // Enhanced error context
      final errorContext = _buildErrorContext('findByMemberNumber', {
        'memberNumber': memberNumber.value,
        'objectBoxStats': _objectBox.getStatistics(),
      });

      return Left(
        DatabaseFailure('Failed to find member: $e\nContext: $errorContext'),
      );
    }
  }

  @override
  Future<Either<Failure, Member?>> findById(MemberId memberId) async {
    try {
      if (!_objectBox.isHealthy()) {
        throw StateError('ObjectBox is not healthy');
      }

      final query = _memberBox
          .query(MemberEntity_.memberId.equals(memberId.value))
          .build();

      try {
        final memberEntity = query.findFirst();

        if (memberEntity == null) {
          return const Right(null);
        }

        final member = memberEntity.toDomain();
        return Right(member);
      } finally {
        query.close();
      }
    } catch (e, stackTrace) {
      _logger.e('Error finding member by ID', error: e, stackTrace: stackTrace);

      final errorContext = _buildErrorContext('findById', {
        'memberId': memberId.value,
        'objectBoxStats': _objectBox.getStatistics(),
      });

      return Left(
        DatabaseFailure('Failed to find member: $e\nContext: $errorContext'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> save(Member member) async {
    try {
      if (!_objectBox.isHealthy()) {
        throw StateError('ObjectBox is not healthy');
      }

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
          } else {
            // Create new entity
            final newEntity = MemberEntity.fromDomain(member);
            _memberBox.put(newEntity);
          }
        } finally {
          existingQuery.close();
        }
      });

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error saving member', error: e, stackTrace: stackTrace);

      final errorContext = _buildErrorContext('save', {
        'memberId': member.memberId.value,
        'objectBoxStats': _objectBox.getStatistics(),
      });

      return Left(
        DatabaseFailure('Failed to save member: $e\nContext: $errorContext'),
      );
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
      if (!_objectBox.isHealthy()) {
        throw StateError('ObjectBox is not healthy');
      }

      final query = _memberBox
          .query(MemberEntity_.memberNumber.equals(memberNumber.value))
          .build();

      try {
        final count = query.count();
        final exists = count > 0;

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

      final errorContext = _buildErrorContext('exists', {
        'memberNumber': memberNumber.value,
        'objectBoxStats': _objectBox.getStatistics(),
      });

      return Left(
        DatabaseFailure(
          'Failed to check member existence: $e\nContext: $errorContext',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> syncWithServer() async {
    try {
      if (!_objectBox.isHealthy()) {
        throw StateError('ObjectBox is not healthy');
      }

      // Placeholder for server sync implementation
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

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error syncing with server', error: e, stackTrace: stackTrace);
      return Left(NetworkFailure('Failed to sync with server: $e'));
    }
  }

  /// Get reactive stream of members for UI updates
  /// Following ObjectBox streaming best practices
  Stream<List<Member>> watchMembers() {
    try {
      if (!_objectBox.isHealthy()) {
        _logger.w('ObjectBox is not healthy, returning empty stream');
        return Stream.value([]);
      }

      return _memberBox
          .query()
          .watch(triggerImmediately: true)
          .map(
            (query) => query.find().map((entity) => entity.toDomain()).toList(),
          );
    } catch (e, stackTrace) {
      _logger.e('Error in watchMembers', error: e, stackTrace: stackTrace);
      // Return empty stream on error
      return Stream.value([]);
    }
  }

  /// Bulk save operation using transactions for performance
  Future<Either<Failure, void>> saveMany(List<Member> members) async {
    try {
      if (!_objectBox.isHealthy()) {
        throw StateError('ObjectBox is not healthy');
      }

      await _objectBox.store.runInTransactionAsync(TxMode.write, (s, p) async {
        final entities = members.map(MemberEntity.fromDomain).toList();
        _memberBox.putMany(entities);
      }, {});

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e('Error in bulk save', error: e, stackTrace: stackTrace);

      final errorContext = _buildErrorContext('saveMany', {
        'memberCount': members.length,
        'objectBoxStats': _objectBox.getStatistics(),
      });

      return Left(
        DatabaseFailure('Failed to save members: $e\nContext: $errorContext'),
      );
    }
  }

  /// Build comprehensive error context for debugging
  String _buildErrorContext(String operation, Map<String, dynamic> details) {
    final context = {
      'operation': operation,
      'timestamp': DateTime.now().toIso8601String(),
      'objectBoxHealth': _objectBox.isHealthy(),
      ...details,
    };

    return context.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }

  /// Additional diagnostic methods for troubleshooting

  /// Get repository health status
  Map<String, dynamic> getHealthStatus() {
    return {
      'repositoryStatus': 'active',
      'objectBoxHealth': _objectBox.isHealthy(),
      'objectBoxStats': _objectBox.getStatistics(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Force member box reinitialization (for emergency recovery)
  Future<Either<Failure, void>> reinitializeMemberBox() async {
    try {
      _logger.w('Force reinitializing member box');

      // This will trigger lazy reinitialization on next access
      // The new ObjectBox implementation handles this automatically

      // Test access to ensure it works
      _memberBox.isEmpty();

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to reinitialize member box',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(DatabaseFailure('Failed to reinitialize member box: $e'));
    }
  }
}
