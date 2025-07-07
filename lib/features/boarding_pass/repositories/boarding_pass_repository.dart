import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/value_objects/pass_id.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:dartz/dartz.dart';

/// BoardingPass repository interface
/// Follows Repository pattern for aggregate persistence with offline-first strategy
abstract class BoardingPassRepository {
  /// Get boarding pass by pass ID
  Future<Either<Failure, BoardingPass?>> findByPassId(PassId passId);

  /// Get boarding passes by member number (primary use case)
  Future<Either<Failure, List<BoardingPass>>> findByMemberNumber(
    MemberNumber memberNumber,
  );

  /// Get boarding passes by flight number
  Future<Either<Failure, List<BoardingPass>>> findByFlightNumber(
    FlightNumber flightNumber,
  );

  /// Get active boarding passes for member
  Future<Either<Failure, List<BoardingPass>>> findActiveBoardingPasses(
    MemberNumber memberNumber,
  );

  /// Save boarding pass (create or update)
  Future<Either<Failure, void>> save(BoardingPass boardingPass);

  /// Save boarding pass locally for offline support
  Future<Either<Failure, void>> saveLocally(BoardingPass boardingPass);

  /// Check if boarding pass exists
  Future<Either<Failure, bool>> exists(PassId passId);

  /// Sync with remote server
  Future<Either<Failure, void>> syncWithServer();

  /// Delete boarding pass (soft delete - mark as cancelled)
  Future<Either<Failure, void>> delete(PassId passId);

  /// Get boarding passes requiring status update (auto-expiry)
  Future<Either<Failure, List<BoardingPass>>> findPassesRequiringStatusUpdate();
}
