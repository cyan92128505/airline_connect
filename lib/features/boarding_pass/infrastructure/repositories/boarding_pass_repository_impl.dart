import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/domain/datasources/boarding_pass_local_data_source.dart';
import 'package:app/features/boarding_pass/domain/datasources/boarding_pass_remote_dataSource.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/domain/repositories/boarding_pass_repository.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

/// Updated repository implementation that coordinates local and remote data sources
/// Implements offline-first strategy with background sync
class BoardingPassRepositoryImpl implements BoardingPassRepository {
  static final Logger _logger = Logger();

  final BoardingPassLocalDataSource _localDataSource;
  final BoardingPassRemoteDataSource _remoteDataSource;

  BoardingPassRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Future<Either<Failure, BoardingPass?>> findByPassId(PassId passId) async {
    try {
      // 1. Try local first (offline-first strategy)
      final localResult = await _localDataSource.findByPassId(passId);

      return localResult.fold(
        (localFailure) async {
          _logger.w('Local lookup failed, trying remote: $localFailure');

          // 2. If local fails, try remote
          final remoteResult = await _remoteDataSource.getBoardingPass(passId);

          return remoteResult.fold((remoteFailure) => Left(remoteFailure), (
            remoteBoardingPass,
          ) async {
            // 3. Cache remote result locally
            if (remoteBoardingPass != null) {
              await _localDataSource.save(remoteBoardingPass);
            }
            return Right(remoteBoardingPass);
          });
        },
        (localBoardingPass) async {
          // 4. Background sync if local found
          if (localBoardingPass != null) {
            _syncBoardingPassInBackground(passId);
          }
          return Right(localBoardingPass);
        },
      );
    } catch (e) {
      _logger.e('Error finding boarding pass by ID', error: e);
      return Left(UnknownFailure('Failed to find boarding pass: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BoardingPass>>> findByMemberNumber(
    MemberNumber memberNumber,
  ) async {
    try {
      // 1. Get local passes first
      final localResult = await _localDataSource.findByMemberNumber(
        memberNumber,
      );

      return localResult.fold(
        (localFailure) async {
          // 2. If local fails, try remote only
          _logger.w('Local lookup failed, trying remote only');
          return _remoteDataSource.getBoardingPassesForMember(memberNumber);
        },
        (localPasses) async {
          // 3. Background sync with remote
          _syncMemberPassesInBackground(memberNumber);
          return Right(localPasses);
        },
      );
    } catch (e) {
      _logger.e('Error finding boarding passes by member', error: e);
      return Left(UnknownFailure('Failed to find boarding passes: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BoardingPass>>> findByFlightNumber(
    FlightNumber flightNumber,
  ) async {
    // Flight queries are typically admin/staff functions, so try remote first
    try {
      final remoteResult = await _remoteDataSource.getBoardingPassesForMember(
        // This would need a different remote method for flight-based queries
        // For now, fallback to local
        MemberNumber.create('temp'), // TODO: Implement proper flight query
      );

      return remoteResult.fold(
        (failure) => _localDataSource.findByFlightNumber(flightNumber),
        (remotePasses) => Right(remotePasses),
      );
    } catch (e) {
      return _localDataSource.findByFlightNumber(flightNumber);
    }
  }

  @override
  Future<Either<Failure, List<BoardingPass>>> findActiveBoardingPasses(
    MemberNumber memberNumber,
  ) async {
    // Active passes are frequently accessed, so prioritize local
    final localResult = await _localDataSource.findActiveBoardingPasses(
      memberNumber,
    );

    return localResult.fold(
      (failure) => _remoteDataSource.getBoardingPassesForMember(memberNumber),
      (localPasses) {
        // Filter active passes and background sync
        final activePasses = localPasses
            .where((pass) => pass.isActive)
            .toList();
        _syncMemberPassesInBackground(memberNumber);
        return Right(activePasses);
      },
    );
  }

  @override
  Future<Either<Failure, void>> save(BoardingPass boardingPass) async {
    try {
      // 1. Save locally first (immediate response)
      final localResult = await _localDataSource.save(boardingPass);

      return localResult.fold((localFailure) => Left(localFailure), (_) async {
        // 2. Sync with remote in background
        _syncBoardingPassToRemoteInBackground(boardingPass);
        return const Right(null);
      });
    } catch (e) {
      _logger.e('Error saving boarding pass', error: e);
      return Left(UnknownFailure('Failed to save boarding pass: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveLocally(BoardingPass boardingPass) async {
    return _localDataSource.save(boardingPass);
  }

  @override
  Future<Either<Failure, bool>> exists(PassId passId) async {
    // Check local first, then remote if not found
    final localExists = await _localDataSource.exists(passId);

    return localExists.fold((failure) => Left(failure), (exists) async {
      if (exists) return const Right(true);

      // Check remote
      final remoteResult = await _remoteDataSource.getBoardingPass(passId);
      return remoteResult.fold(
        (failure) => const Right(false),
        (remoteBoardingPass) => Right(remoteBoardingPass != null),
      );
    });
  }

  @override
  Future<Either<Failure, void>> syncWithServer() async {
    try {
      // 1. Get all local passes that need syncing
      final localPasses = await _getAllLocalPasses();

      return localPasses.fold((failure) => Left(failure), (passes) async {
        // 2. Sync with remote
        final syncResult = await _remoteDataSource.syncBoardingPasses(passes);

        return syncResult.fold((syncFailure) => Left(syncFailure), (
          syncedPasses,
        ) async {
          // 3. Update local database with synced data
          for (final pass in syncedPasses) {
            await _localDataSource.save(pass);
          }

          return const Right(null);
        });
      });
    } catch (e) {
      _logger.e('Error syncing with server', error: e);
      return Left(NetworkFailure('Failed to sync with server: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(PassId passId) async {
    // Cancel the pass instead of hard delete
    final findResult = await findByPassId(passId);

    return findResult.fold((failure) => Left(failure), (boardingPass) async {
      if (boardingPass == null) {
        return Left(NotFoundFailure('Boarding pass not found'));
      }

      final cancelledPass = boardingPass.cancel();
      return save(cancelledPass);
    });
  }

  @override
  Future<Either<Failure, List<BoardingPass>>>
  findPassesRequiringStatusUpdate() async {
    return _localDataSource.findPassesRequiringStatusUpdate();
  }

  // =============================================================================
  // QR Code Specific Methods
  // =============================================================================

  /// Verify QR code with remote service and get boarding pass
  @override
  Future<Either<Failure, BoardingPass?>> verifyQRCodeWithRemote(
    String passId,
    String qrToken,
  ) async {
    try {
      final remoteResult = await _remoteDataSource.verifyQRCodeAndGetPass(
        passId,
        qrToken,
      );

      return remoteResult.fold((failure) => Left(failure), (
        remoteBoardingPass,
      ) async {
        // Cache the verified pass locally
        if (remoteBoardingPass != null) {
          await _localDataSource.save(remoteBoardingPass);
        }
        return Right(remoteBoardingPass);
      });
    } catch (e) {
      _logger.e('Error verifying QR code', error: e);
      return Left(NetworkFailure('Failed to verify QR code: $e'));
    }
  }

  /// Validate boarding pass for gate scanning
  Future<Either<Failure, BoardingPassValidationResponse>> validateForBoarding(
    String passId,
    String gateCode,
  ) async {
    try {
      return _remoteDataSource.validateForBoarding(passId, gateCode);
    } catch (e) {
      _logger.e('Error validating for boarding', error: e);
      return Left(NetworkFailure('Failed to validate for boarding: $e'));
    }
  }

  // =============================================================================
  // Private Helper Methods
  // =============================================================================

  Future<Either<Failure, List<BoardingPass>>> _getAllLocalPasses() async {
    // This would need to be implemented in the local data source
    // For now, return empty list
    return const Right([]);
  }

  /// Background sync for a single boarding pass
  void _syncBoardingPassInBackground(PassId passId) {
    Future.microtask(() async {
      try {
        final remoteResult = await _remoteDataSource.getBoardingPass(passId);
        remoteResult.fold(
          (failure) =>
              _logger.w('Background sync failed for $passId: $failure'),
          (remoteBoardingPass) async {
            if (remoteBoardingPass != null) {
              await _localDataSource.save(remoteBoardingPass);
            }
          },
        );
      } catch (e) {
        _logger.w('Background sync error for $passId: $e');
      }
    });
  }

  /// Background sync for member boarding passes
  void _syncMemberPassesInBackground(MemberNumber memberNumber) {
    Future.microtask(() async {
      try {
        final remoteResult = await _remoteDataSource.getBoardingPassesForMember(
          memberNumber,
        );
        remoteResult.fold(
          (failure) => _logger.w('Background member sync failed: $failure'),
          (remotePasses) async {
            for (final pass in remotePasses) {
              await _localDataSource.save(pass);
            }
            _logger.d(
              'Background member sync completed: ${remotePasses.length} passes',
            );
          },
        );
      } catch (e) {
        _logger.w('Background member sync error: $e');
      }
    });
  }

  /// Background sync to remote server
  void _syncBoardingPassToRemoteInBackground(BoardingPass boardingPass) {
    Future.microtask(() async {
      try {
        final remoteResult = await _remoteDataSource.updateBoardingPassStatus(
          boardingPass,
        );
        remoteResult.fold(
          (failure) => _logger.w('Background remote sync failed: $failure'),
          (updatedPass) => _logger.d('Background remote sync completed'),
        );
      } catch (e) {
        _logger.w('Background remote sync error: $e');
      }
    });
  }
}
