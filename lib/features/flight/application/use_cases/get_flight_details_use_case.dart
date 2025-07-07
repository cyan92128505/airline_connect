import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/features/flight/application/dtos/flight_dto.dart';
import 'package:app/features/flight/domain/repositories/flight_repository.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

/// Use case for getting flight details to support boarding pass operations
/// This is a SUPPORTING use case for BoardingPass aggregate
@injectable
class GetFlightDetailsUseCase implements UseCase<FlightDTO, String> {
  final FlightRepository _flightRepository;

  const GetFlightDetailsUseCase(this._flightRepository);

  @override
  Future<Either<Failure, FlightDTO>> call(String flightNumber) async {
    try {
      // Validate flight number format
      final flightNumberVO = FlightNumber.create(flightNumber);

      // Retrieve flight from repository (or external API)
      final flightResult = await _flightRepository.findByFlightNumber(
        flightNumberVO,
      );

      return flightResult.fold((failure) => Left(failure), (flight) {
        if (flight == null) {
          return Left(NotFoundFailure('Flight not found: $flightNumber'));
        }

        // Convert to DTO for boarding pass operations
        final flightDTO = FlightDTOExtensions.fromDomain(flight);
        return Right(flightDTO);
      });
    } on DomainException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to get flight details: $e'));
    }
  }
}
