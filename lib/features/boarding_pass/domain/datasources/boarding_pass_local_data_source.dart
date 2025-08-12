import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:dartz/dartz.dart';

abstract class BoardingPassLocalDataSource {
  Future<Either<Failure, BoardingPass?>> findByPassId(PassId passId);

  Future<Either<Failure, List<BoardingPass>>> findByMemberNumber(
    MemberNumber memberNumber,
  );

  Future<Either<Failure, List<BoardingPass>>> findByFlightNumber(
    FlightNumber flightNumber,
  );

  Future<Either<Failure, List<BoardingPass>>> findActiveBoardingPasses(
    MemberNumber memberNumber,
  );

  Future<Either<Failure, void>> save(BoardingPass boardingPass);

  Future<Either<Failure, bool>> exists(PassId passId);

  Future<Either<Failure, List<BoardingPass>>> findPassesRequiringStatusUpdate();

  Future<Either<Failure, void>> saveMany(List<BoardingPass> boardingPasses);

  Stream<List<BoardingPass>> watchBoardingPasses(MemberNumber memberNumber);

  Stream<List<BoardingPass>> watchActiveBoardingPasses(
    MemberNumber memberNumber,
  );
}
