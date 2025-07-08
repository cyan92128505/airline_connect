import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/boarding_pass/domain/repositories/boarding_pass_repository.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';

/// Use case for getting boarding pass details by pass ID
@injectable
class GetBoardingPassDetailsUseCase
    implements UseCase<BoardingPassDTO, String> {
  final BoardingPassRepository _boardingPassRepository;

  const GetBoardingPassDetailsUseCase(this._boardingPassRepository);

  @override
  Future<Either<Failure, BoardingPassDTO>> call(String passId) async {
    try {
      // Validate pass ID format
      final trimedPassId = passId.trim();
      if (trimedPassId.isEmpty) {
        return Left(ValidationFailure('Pass ID cannot be empty'));
      }

      final passIdVO = PassId.fromString(trimedPassId);

      // Retrieve boarding pass from repository
      final passResult = await _boardingPassRepository.findByPassId(passIdVO);

      return passResult.fold((failure) => Left(failure), (boardingPass) {
        if (boardingPass == null) {
          return Left(NotFoundFailure('Boarding pass not found: $passId'));
        }

        // Convert to DTO
        final passDTO = BoardingPassDTOExtensions.fromDomain(boardingPass);
        return Right(passDTO);
      });
    } on DomainException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Failed to get boarding pass details: $e'));
    }
  }
}
