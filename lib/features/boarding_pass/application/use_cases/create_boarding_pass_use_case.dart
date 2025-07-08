import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/member/domain/repositories/member_repository.dart';
import 'package:app/features/flight/domain/repositories/flight_repository.dart';
import 'package:app/features/boarding_pass/domain/services/boarding_pass_service.dart';
import 'package:app/features/boarding_pass/domain/value_objects/seat_number.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';

/// Use case for creating a boarding pass
/// Orchestrates member, flight validation and boarding pass creation
@injectable
class CreateBoardingPassUseCase
    implements
        UseCase<BoardingPassOperationResponseDTO, CreateBoardingPassDTO> {
  final BoardingPassService _boardingPassService;
  final MemberRepository _memberRepository;
  final FlightRepository _flightRepository;

  const CreateBoardingPassUseCase(
    this._boardingPassService,
    this._memberRepository,
    this._flightRepository,
  );

  @override
  Future<Either<Failure, BoardingPassOperationResponseDTO>> call(
    CreateBoardingPassDTO params,
  ) async {
    try {
      // Step 1: Validate input parameters
      final validationResult = _validateInput(params);
      if (validationResult != null) {
        return Right(
          BoardingPassOperationResponseDTO.error(
            errorMessage: validationResult.message,
            errorCode: 'VALIDATION_ERROR',
          ),
        );
      }

      // Step 2: Create value objects
      final memberNumber = MemberNumber.create(params.memberNumber);
      final flightNumber = FlightNumber.create(params.flightNumber);
      final seatNumber = SeatNumber.create(params.seatNumber);

      // Step 3: Retrieve member
      final memberResult = await _memberRepository.findByMemberNumber(
        memberNumber,
      );

      return memberResult.fold(
        (failure) => Right(
          BoardingPassOperationResponseDTO.error(
            errorMessage: 'Failed to retrieve member: ${failure.message}',
            errorCode: 'MEMBER_ERROR',
          ),
        ),
        (member) async {
          if (member == null) {
            return Right(
              BoardingPassOperationResponseDTO.error(
                errorMessage: 'Member not found: ${params.memberNumber}',
                errorCode: 'MEMBER_NOT_FOUND',
              ),
            );
          }

          // Step 4: Retrieve flight
          final flightResult = await _flightRepository.findByFlightNumber(
            flightNumber,
          );

          return flightResult.fold(
            (failure) => Right(
              BoardingPassOperationResponseDTO.error(
                errorMessage: 'Failed to retrieve flight: ${failure.message}',
                errorCode: 'FLIGHT_ERROR',
              ),
            ),
            (flight) async {
              if (flight == null) {
                return Right(
                  BoardingPassOperationResponseDTO.error(
                    errorMessage: 'Flight not found: ${params.flightNumber}',
                    errorCode: 'FLIGHT_NOT_FOUND',
                  ),
                );
              }

              // Step 5: Create boarding pass using domain service
              final createResult = await _boardingPassService
                  .createBoardingPass(
                    member: member,
                    flight: flight,
                    seatNumber: seatNumber,
                  );

              return createResult.fold(
                (failure) => Right(
                  BoardingPassOperationResponseDTO.error(
                    errorMessage: failure.message,
                    errorCode: _mapFailureToErrorCode(failure),
                  ),
                ),
                (boardingPass) => Right(
                  BoardingPassOperationResponseDTO.success(
                    boardingPass: BoardingPassDTOExtensions.fromDomain(
                      boardingPass,
                    ),
                    metadata: {
                      'createdAt': DateTime.now().toIso8601String(),
                      'memberTier': member.tier.name,
                      'flightStatus': flight.status.name,
                    },
                  ),
                ),
              );
            },
          );
        },
      );
    } on DomainException catch (e) {
      return Right(
        BoardingPassOperationResponseDTO.error(
          errorMessage: e.message,
          errorCode: 'DOMAIN_VALIDATION_ERROR',
        ),
      );
    } catch (e) {
      return Left(UnknownFailure('Failed to create boarding pass: $e'));
    }
  }

  /// Validate input parameters
  Failure? _validateInput(CreateBoardingPassDTO params) {
    if (params.memberNumber.trim().isEmpty) {
      return ValidationFailure('Member number cannot be empty');
    }

    if (params.flightNumber.trim().isEmpty) {
      return ValidationFailure('Flight number cannot be empty');
    }

    if (params.seatNumber.trim().isEmpty) {
      return ValidationFailure('Seat number cannot be empty');
    }

    // Validate formats using domain objects
    try {
      MemberNumber.create(params.memberNumber);
      FlightNumber.create(params.flightNumber);
      SeatNumber.create(params.seatNumber);
    } catch (e) {
      return ValidationFailure('Invalid input format: $e');
    }

    return null;
  }

  /// Map failure types to error codes
  String _mapFailureToErrorCode(Failure failure) {
    if (failure is ValidationFailure) return 'VALIDATION_ERROR';
    if (failure is NotFoundFailure) return 'NOT_FOUND';
    if (failure is DatabaseFailure) return 'DATABASE_ERROR';
    if (failure is NetworkFailure) return 'NETWORK_ERROR';
    return 'UNKNOWN_ERROR';
  }
}
