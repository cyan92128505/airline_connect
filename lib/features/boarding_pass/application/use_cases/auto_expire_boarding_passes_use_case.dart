import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/core/use_cases/use_case.dart';
import 'package:app/features/boarding_pass/domain/services/boarding_pass_service.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';

/// Use case for automatically expiring boarding passes
@injectable
class AutoExpireBoardingPassesUseCase
    implements NoParamsUseCase<List<BoardingPassDTO>> {
  final BoardingPassService _boardingPassService;

  const AutoExpireBoardingPassesUseCase(this._boardingPassService);

  @override
  Future<Either<Failure, List<BoardingPassDTO>>> call() async {
    try {
      // Auto-expire boarding passes using domain service
      final expireResult = await _boardingPassService
          .autoExpireBoardingPasses();

      return expireResult.fold((failure) => Left(failure), (expiredPasses) {
        final passDTOs = expiredPasses
            .map(BoardingPassDTOExtensions.fromDomain)
            .toList();
        return Right(passDTOs);
      });
    } catch (e) {
      return Left(UnknownFailure('Failed to auto-expire boarding passes: $e'));
    }
  }
}
