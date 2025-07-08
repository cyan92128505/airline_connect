import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/features/boarding_pass/domain/services/boarding_pass_service.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';

/// Use case for getting all boarding passes for a member
@injectable
class GetBoardingPassesForMemberUseCase
    implements UseCase<List<BoardingPassDTO>, BoardingPassSearchDTO> {
  final BoardingPassService _boardingPassService;

  const GetBoardingPassesForMemberUseCase(this._boardingPassService);

  @override
  Future<Either<Failure, List<BoardingPassDTO>>> call(
    BoardingPassSearchDTO params,
  ) async {
    try {
      // Validate member number is provided
      if (params.memberNumber == null || params.memberNumber!.trim().isEmpty) {
        return Left(ValidationFailure('Member number is required'));
      }

      final memberNumber = MemberNumber.create(params.memberNumber!);

      Either<Failure, List<BoardingPass>> serviceResult;

      if (params.activeOnly == true) {
        // Get only active boarding passes
        serviceResult = await _boardingPassService
            .getActiveBoardingPassesForMember(memberNumber);
      } else {
        // Get all boarding passes
        serviceResult = await _boardingPassService.getBoardingPassesForMember(
          memberNumber,
        );
      }

      return serviceResult.fold((failure) => Left(failure), (boardingPasses) {
        var filteredPasses = boardingPasses;

        // Apply additional filters if provided
        filteredPasses = _applyFilters(filteredPasses, params);

        // Apply pagination if provided
        if (params.offset != null || params.limit != null) {
          final offset = params.offset ?? 0;
          final limit = params.limit;

          filteredPasses = filteredPasses.skip(offset).toList();
          if (limit != null && limit > 0) {
            filteredPasses = filteredPasses.take(limit).toList();
          }
        }

        // Convert to DTOs
        final passDTOs = filteredPasses
            .map(BoardingPassDTOExtensions.fromDomain)
            .toList();

        return Right(passDTOs);
      });
    } catch (e) {
      return Left(UnknownFailure('Failed to get boarding passes: $e'));
    }
  }

  /// Apply search filters to boarding passes
  List<BoardingPass> _applyFilters(
    List<BoardingPass> passes,
    BoardingPassSearchDTO params,
  ) {
    var filteredPasses = passes;

    // Filter by status
    if (params.status != null) {
      filteredPasses = filteredPasses
          .where((pass) => pass.status == params.status)
          .toList();
    }

    // Filter by flight number
    if (params.flightNumber != null && params.flightNumber!.trim().isNotEmpty) {
      filteredPasses = filteredPasses
          .where((pass) => pass.flightNumber.value == params.flightNumber)
          .toList();
    }

    // Filter by specific departure date
    if (params.departureDate != null) {
      final targetDate = DateTime.parse(params.departureDate!);
      filteredPasses = filteredPasses.where((pass) {
        final departureDate = DateTime(
          pass.scheduleSnapshot.departureTime.year,
          pass.scheduleSnapshot.departureTime.month,
          pass.scheduleSnapshot.departureTime.day,
        );
        return departureDate ==
            DateTime(targetDate.year, targetDate.month, targetDate.day);
      }).toList();
    }

    // Filter by departure date range
    if (params.departureFromDate != null || params.departureToDate != null) {
      final fromDate = params.departureFromDate != null
          ? DateTime.parse(params.departureFromDate!)
          : DateTime(1900);
      final toDate = params.departureToDate != null
          ? DateTime.parse(params.departureToDate!).add(Duration(days: 1))
          : DateTime(2100);

      filteredPasses = filteredPasses.where((pass) {
        final departureDateTime = pass.scheduleSnapshot.departureTime.toLocal();
        return departureDateTime.isAfter(fromDate) &&
            departureDateTime.isBefore(toDate);
      }).toList();
    }

    return filteredPasses;
  }
}
