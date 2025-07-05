import 'package:dartz/dartz.dart';
import 'package:timezone/timezone.dart';
import '../entities/boarding_pass.dart';
import '../value_objects/pass_id.dart';
import '../value_objects/seat_number.dart';
import '../value_objects/flight_schedule_snapshot.dart';
import '../repositories/boarding_pass_repository.dart';
import '../../member/entities/member.dart';
import '../../member/value_objects/member_number.dart';
import '../../flight/entities/flight.dart';
import '../../../core/failures/failure.dart';
import '../../../core/exceptions/domain_exception.dart';

class BoardingPassService {
  final BoardingPassRepository _boardingPassRepository;

  const BoardingPassService(this._boardingPassRepository);

  Future<Either<Failure, BoardingPass>> createBoardingPass({
    required Member member,
    required Flight flight,
    required SeatNumber seatNumber,
  }) async {
    try {
      if (!member.isEligibleForBoardingPass()) {
        return Left(
          ValidationFailure('Member is not eligible for boarding pass'),
        );
      }

      if (!flight.isActive) {
        return Left(ValidationFailure('Flight is not active'));
      }

      if (!flight.isBoardingEligible) {
        return Left(
          ValidationFailure(
            'Flight is not eligible for boarding pass issuance',
          ),
        );
      }

      final existingPassesResult = await _boardingPassRepository
          .findActiveBoardingPasses(member.memberNumber);

      return existingPassesResult.fold((failure) => Left(failure), (
        existingPasses,
      ) async {
        final hasExistingPass = existingPasses.any(
          (pass) => pass.flightNumber == flight.flightNumber,
        );

        if (hasExistingPass) {
          return Left(
            ValidationFailure(
              'Member already has boarding pass for this flight',
            ),
          );
        }

        final scheduleSnapshot = FlightScheduleSnapshot.fromSchedule(
          flight.schedule,
          snapshotTime: TZDateTime.now(local),
        );

        final boardingPass = BoardingPass.create(
          memberNumber: member.memberNumber,
          flightNumber: flight.flightNumber,
          seatNumber: seatNumber,
          scheduleSnapshot: scheduleSnapshot,
        );

        final saveResult = await _boardingPassRepository.save(boardingPass);

        return saveResult.fold(
          (failure) => Left(failure),
          (_) => Right(boardingPass),
        );
      });
    } on DomainException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to create boarding pass: $e'));
    }
  }

  Future<Either<Failure, BoardingPass>> activateBoardingPass(
    PassId passId,
  ) async {
    try {
      final boardingPassResult = await _boardingPassRepository.findByPassId(
        passId,
      );

      return boardingPassResult.fold((failure) => Left(failure), (
        boardingPass,
      ) async {
        if (boardingPass == null) {
          return Left(NotFoundFailure('Boarding pass not found'));
        }

        final activatedPass = boardingPass.activate();

        final saveResult = await _boardingPassRepository.save(activatedPass);

        return saveResult.fold(
          (failure) => Left(failure),
          (_) => Right(activatedPass),
        );
      });
    } on DomainException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to activate boarding pass: $e'));
    }
  }

  Future<Either<Failure, BoardingPass>> useBoardingPass(PassId passId) async {
    try {
      final boardingPassResult = await _boardingPassRepository.findByPassId(
        passId,
      );

      return boardingPassResult.fold((failure) => Left(failure), (
        boardingPass,
      ) async {
        if (boardingPass == null) {
          return Left(NotFoundFailure('Boarding pass not found'));
        }

        final usedPass = boardingPass.use();

        final saveResult = await _boardingPassRepository.save(usedPass);

        return saveResult.fold(
          (failure) => Left(failure),
          (_) => Right(usedPass),
        );
      });
    } on DomainException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to use boarding pass: $e'));
    }
  }

  Future<Either<Failure, BoardingPass>> updateSeatAssignment({
    required PassId passId,
    required SeatNumber newSeatNumber,
  }) async {
    try {
      final boardingPassResult = await _boardingPassRepository.findByPassId(
        passId,
      );

      return boardingPassResult.fold((failure) => Left(failure), (
        boardingPass,
      ) async {
        if (boardingPass == null) {
          return Left(NotFoundFailure('Boarding pass not found'));
        }

        final updatedPass = boardingPass.updateSeat(newSeatNumber);

        final saveResult = await _boardingPassRepository.save(updatedPass);

        return saveResult.fold(
          (failure) => Left(failure),
          (_) => Right(updatedPass),
        );
      });
    } on DomainException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to update seat assignment: $e'));
    }
  }

  Future<Either<Failure, bool>> validateBoardingEligibility(
    PassId passId,
  ) async {
    final boardingPassResult = await _boardingPassRepository.findByPassId(
      passId,
    );

    return boardingPassResult.fold((failure) => Left(failure), (boardingPass) {
      if (boardingPass == null) {
        return Left(NotFoundFailure('Boarding pass not found'));
      }

      return Right(boardingPass.isValidForBoarding);
    });
  }

  Future<Either<Failure, List<BoardingPass>>> autoExpireBoardingPasses() async {
    try {
      final passesResult = await _boardingPassRepository
          .findPassesRequiringStatusUpdate();

      return passesResult.fold((failure) => Left(failure), (passes) async {
        final expiredPasses = <BoardingPass>[];
        final now = TZDateTime.now(local);

        for (final pass in passes) {
          if (pass.isActive &&
              now.isAfter(pass.scheduleSnapshot.departureTime)) {
            final expiredPass = pass.expire();
            await _boardingPassRepository.save(expiredPass);
            expiredPasses.add(expiredPass);
          }
        }

        return Right(expiredPasses);
      });
    } catch (e) {
      return Left(UnknownFailure('Failed to auto-expire boarding passes: $e'));
    }
  }

  Future<Either<Failure, List<BoardingPass>>> getBoardingPassesForMember(
    MemberNumber memberNumber,
  ) async {
    return _boardingPassRepository.findByMemberNumber(memberNumber);
  }

  Future<Either<Failure, List<BoardingPass>>> getActiveBoardingPassesForMember(
    MemberNumber memberNumber,
  ) async {
    return _boardingPassRepository.findActiveBoardingPasses(memberNumber);
  }
}
