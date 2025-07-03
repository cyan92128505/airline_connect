import 'package:dartz/dartz.dart';
import '../entities/member.dart';
import '../value_objects/member_number.dart';
import '../value_objects/member_id.dart';
import '../../../core/failures/failure.dart';

/// Member repository interface
/// Follows Repository pattern for aggregate persistence
abstract class MemberRepository {
  /// Get member by member number (primary lookup)
  Future<Either<Failure, Member?>> findByMemberNumber(
    MemberNumber memberNumber,
  );

  /// Get member by member ID
  Future<Either<Failure, Member?>> findById(MemberId memberId);

  /// Save member (create or update)
  Future<Either<Failure, void>> save(Member member);

  /// Save member locally for offline support
  Future<Either<Failure, void>> saveLocally(Member member);

  /// Check if member exists
  Future<Either<Failure, bool>> exists(MemberNumber memberNumber);

  /// Sync with remote server
  Future<Either<Failure, void>> syncWithServer();
}
