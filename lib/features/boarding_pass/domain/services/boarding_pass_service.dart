import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/domain/repositories/boarding_pass_repository.dart';
import 'package:app/features/boarding_pass/domain/value_objects/flight_schedule_snapshot.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:app/features/boarding_pass/domain/value_objects/seat_number.dart';
import 'package:app/features/flight/domain/entities/flight.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:dartz/dartz.dart';
import 'package:timezone/timezone.dart';

class BoardingPassService {
  final BoardingPassRepository _boardingPassRepository;

  const BoardingPassService(this._boardingPassRepository);

  Future<Either<Failure, BoardingPass>> createBoardingPass({
    required Member member,
    required Flight flight,
    required SeatNumber seatNumber,
    required QRCodeData qrCode,
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
          qrCode: qrCode,
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
