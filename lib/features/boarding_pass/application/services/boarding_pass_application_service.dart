import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';
import 'package:app/features/boarding_pass/application/use_cases/create_boarding_pass_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/activate_boarding_pass_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/use_boarding_pass_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/update_seat_assignment_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/validate_qr_code_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/get_boarding_passes_for_member_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/get_boarding_pass_details_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/validate_boarding_eligibility_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/auto_expire_boarding_passes_use_case.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';

/// Application service that orchestrates boarding pass use cases
/// Provides a higher-level API for the presentation layer
@injectable
class BoardingPassApplicationService {
  final CreateBoardingPassUseCase _createBoardingPassUseCase;
  final ActivateBoardingPassUseCase _activateBoardingPassUseCase;
  final UseBoardingPassUseCase _useBoardingPassUseCase;
  final UpdateSeatAssignmentUseCase _updateSeatAssignmentUseCase;
  final ValidateQRCodeUseCase _validateQRCodeUseCase;
  final GetBoardingPassesForMemberUseCase _getBoardingPassesForMemberUseCase;
  final GetBoardingPassDetailsUseCase _getBoardingPassDetailsUseCase;
  final ValidateBoardingEligibilityUseCase _validateBoardingEligibilityUseCase;
  final AutoExpireBoardingPassesUseCase _autoExpireBoardingPassesUseCase;

  const BoardingPassApplicationService(
    this._createBoardingPassUseCase,
    this._activateBoardingPassUseCase,
    this._useBoardingPassUseCase,
    this._updateSeatAssignmentUseCase,
    this._validateQRCodeUseCase,
    this._getBoardingPassesForMemberUseCase,
    this._getBoardingPassDetailsUseCase,
    this._validateBoardingEligibilityUseCase,
    this._autoExpireBoardingPassesUseCase,
  );

  /// Create a new boarding pass
  Future<Either<Failure, BoardingPassOperationResponseDTO>> createBoardingPass({
    required String memberNumber,
    required String flightNumber,
    required String seatNumber,
  }) async {
    final request = CreateBoardingPassDTO(
      memberNumber: memberNumber,
      flightNumber: flightNumber,
      seatNumber: seatNumber,
    );

    return _createBoardingPassUseCase(request);
  }

  /// Activate a boarding pass
  Future<Either<Failure, BoardingPassOperationResponseDTO>>
  activateBoardingPass(String passId) async {
    return _activateBoardingPassUseCase(passId);
  }

  /// Use a boarding pass at boarding gate
  Future<Either<Failure, BoardingPassOperationResponseDTO>> useBoardingPass(
    String passId,
  ) async {
    return _useBoardingPassUseCase(passId);
  }

  /// Update seat assignment on boarding pass
  Future<Either<Failure, BoardingPassOperationResponseDTO>>
  updateSeatAssignment({
    required String passId,
    required String newSeatNumber,
  }) async {
    final request = UpdateSeatDTO(passId: passId, newSeatNumber: newSeatNumber);

    return _updateSeatAssignmentUseCase(request);
  }

  /// Validate QR code at boarding gate
  Future<Either<Failure, QRCodeValidationResponseDTO>> validateQRCode({
    required String encryptedPayload,
    required String checksum,
    required String generatedAt,
    required int version,
  }) async {
    final request = QRCodeValidationDTO(
      encryptedPayload: encryptedPayload,
      checksum: checksum,
      generatedAt: generatedAt,
      version: version,
    );

    return _validateQRCodeUseCase(request);
  }

  /// Get boarding pass details by pass ID
  Future<Either<Failure, BoardingPassDTO>> getBoardingPassDetails(
    String passId,
  ) async {
    return _getBoardingPassDetailsUseCase(passId);
  }

  /// Get all boarding passes for a member
  Future<Either<Failure, List<BoardingPassDTO>>> getBoardingPassesForMember(
    String memberNumber, {
    bool activeOnly = false,
    int? limit,
    int? offset,
  }) async {
    final searchParams = BoardingPassSearchDTO(
      memberNumber: memberNumber,
      activeOnly: activeOnly,
      limit: limit,
      offset: offset,
    );

    return _getBoardingPassesForMemberUseCase(searchParams);
  }

  /// Get boarding passes for member by flight
  Future<Either<Failure, List<BoardingPassDTO>>>
  getBoardingPassesForMemberByFlight({
    required String memberNumber,
    required String flightNumber,
  }) async {
    final searchParams = BoardingPassSearchDTO(
      memberNumber: memberNumber,
      flightNumber: flightNumber,
    );

    return _getBoardingPassesForMemberUseCase(searchParams);
  }

  /// Get boarding passes for member by status
  Future<Either<Failure, List<BoardingPassDTO>>>
  getBoardingPassesForMemberByStatus({
    required String memberNumber,
    required PassStatus status,
  }) async {
    final searchParams = BoardingPassSearchDTO.memberByStatus(
      memberNumber: memberNumber,
      status: status,
    );

    return _getBoardingPassesForMemberUseCase(searchParams);
  }

  /// Get boarding passes for member by departure date range
  Future<Either<Failure, List<BoardingPassDTO>>>
  getBoardingPassesForMemberByDateRange({
    required String memberNumber,
    String? fromDate, // ISO date string (YYYY-MM-DD)
    String? toDate, // ISO date string (YYYY-MM-DD)
  }) async {
    final searchParams = BoardingPassSearchDTO(
      memberNumber: memberNumber,
      departureFromDate: fromDate,
      departureToDate: toDate,
    );

    return _getBoardingPassesForMemberUseCase(searchParams);
  }

  /// Get boarding passes for member by specific departure date
  Future<Either<Failure, List<BoardingPassDTO>>>
  getBoardingPassesForMemberByDate({
    required String memberNumber,
    required String departureDate, // ISO date string (YYYY-MM-DD)
  }) async {
    final searchParams = BoardingPassSearchDTO(
      memberNumber: memberNumber,
      departureDate: departureDate,
    );

    return _getBoardingPassesForMemberUseCase(searchParams);
  }

  /// Get active boarding passes for member
  Future<Either<Failure, List<BoardingPassDTO>>>
  getActiveBoardingPassesForMember(String memberNumber) async {
    final searchParams = BoardingPassSearchDTO.activeForMember(memberNumber);
    return _getBoardingPassesForMemberUseCase(searchParams);
  }

  /// Validate boarding eligibility
  Future<Either<Failure, BoardingEligibilityResponseDTO>>
  validateBoardingEligibility(String passId) async {
    return _validateBoardingEligibilityUseCase(passId);
  }

  /// Auto-expire boarding passes
  Future<Either<Failure, List<BoardingPassDTO>>>
  autoExpireBoardingPasses() async {
    return _autoExpireBoardingPassesUseCase();
  }

  /// Get boarding passes departing today for member
  Future<Either<Failure, List<BoardingPassDTO>>>
  getTodayBoardingPassesForMember(String memberNumber) async {
    final searchParams = BoardingPassSearchDTO.todayForMember(memberNumber);
    return _getBoardingPassesForMemberUseCase(searchParams);
  }

  /// Check if member has boarding pass for specific flight
  Future<Either<Failure, bool>> hasBoardingPassForFlight({
    required String memberNumber,
    required String flightNumber,
  }) async {
    final result = await getBoardingPassesForMemberByFlight(
      memberNumber: memberNumber,
      flightNumber: flightNumber,
    );

    return result.fold(
      (failure) => Left(failure),
      (passes) => Right(passes.isNotEmpty),
    );
  }

  /// Get upcoming boarding passes for member (next 7 days)
  Future<Either<Failure, List<BoardingPassDTO>>>
  getUpcomingBoardingPassesForMember(String memberNumber) async {
    final today = DateTime.now();
    final nextWeek = today.add(Duration(days: 7));

    return getBoardingPassesForMemberByDateRange(
      memberNumber: memberNumber,
      fromDate: today.toIso8601String().split('T')[0],
      toDate: nextWeek.toIso8601String().split('T')[0],
    );
  }

  /// Get boarding pass history for member (past flights)
  Future<Either<Failure, List<BoardingPassDTO>>>
  getBoardingPassHistoryForMember(
    String memberNumber, {
    int? limit,
    int? offset,
  }) async {
    final today = DateTime.now();

    return getBoardingPassesForMemberByDateRange(
      memberNumber: memberNumber,
      toDate: today.toIso8601String().split('T')[0],
    );
  }

  /// Batch validate multiple boarding passes
  Future<Map<String, Either<Failure, BoardingEligibilityResponseDTO>>>
  batchValidateBoardingEligibility(List<String> passIds) async {
    final results = <String, Either<Failure, BoardingEligibilityResponseDTO>>{};

    for (final passId in passIds) {
      try {
        final result = await validateBoardingEligibility(passId);
        results[passId] = result;
      } catch (e) {
        results[passId] = Left(
          UnknownFailure('Failed to validate pass $passId: $e'),
        );
      }
    }

    return results;
  }

  /// Get boarding pass statistics for member
  Future<Either<Failure, Map<String, dynamic>>> getBoardingPassStatsForMember(
    String memberNumber,
  ) async {
    final allPassesResult = await getBoardingPassesForMember(memberNumber);

    return allPassesResult.fold((failure) => Left(failure), (passes) {
      final stats = <String, dynamic>{
        'total': passes.length,
        'active': passes.where((p) => p.isActive == true).length,
        'used': passes.where((p) => p.status == PassStatus.used).length,
        'expired': passes.where((p) => p.status == PassStatus.expired).length,
        'cancelled': passes
            .where((p) => p.status == PassStatus.cancelled)
            .length,
        'byStatus': <String, int>{},
      };

      // Count by status
      for (final status in PassStatus.values) {
        stats['byStatus'][status.name] = passes
            .where((p) => p.status == status)
            .length;
      }

      return Right(stats);
    });
  }
}
