import 'dart:math';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';
import 'package:app/features/boarding_pass/domain/datasources/boarding_pass_remote_dataSource.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:dartz/dartz.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:logger/logger.dart';

/// Mock implementation that works with MockDataSeeder
/// Uses standardized test data and real QR code validation
class MockBoardingPassRemoteDataSource implements BoardingPassRemoteDataSource {
  static final Logger _logger = Logger();

  // Simulated database - populated by external seeder
  final Map<String, BoardingPass> _boardingPassDatabase = {};
  final Map<String, List<String>> _memberPassIndex = {};
  final Set<String> _usedTokens = {}; // Prevent replay attacks

  final Random _random = Random();
  final bool _simulateNetworkDelay;
  final bool _simulateErrors;

  MockBoardingPassRemoteDataSource({
    bool simulateNetworkDelay = true,
    bool simulateErrors = false,
  }) : _simulateNetworkDelay = simulateNetworkDelay,
       _simulateErrors = simulateErrors;

  /// Initialize with standardized test data that matches MockDataSeeder
  void initializeWithTestData(List<BoardingPass> boardingPasses) {
    _boardingPassDatabase.clear();
    _memberPassIndex.clear();
    _usedTokens.clear();

    for (final pass in boardingPasses) {
      _addBoardingPassToDatabase(pass);
    }
  }

  /// Add single boarding pass to the simulated database
  void addBoardingPass(BoardingPass boardingPass) {
    _addBoardingPassToDatabase(boardingPass);
    _logger.d(
      'Added boarding pass to remote database: ${boardingPass.passId.value}',
    );
  }

  @override
  Future<Either<Failure, BoardingPass?>> verifyQRCodeAndGetPass(
    String passId,
    String qrToken,
  ) async {
    await _simulateDelay();

    try {
      // Basic token validation
      if (!_isValidToken(qrToken)) {
        return Left(AuthenticationFailure('Invalid QR token format'));
      }

      // Check if token was already used (replay attack prevention)
      if (_usedTokens.contains(qrToken)) {
        return Left(ValidationFailure('QR token already used'));
      }

      final boardingPass = _boardingPassDatabase[passId];
      if (boardingPass == null) {
        _logger.w('Boarding pass not found in remote database: $passId');
        return const Right(null);
      }

      // Verify QR token matches the boarding pass QR code
      if (!_verifyQRTokenMatchesPass(qrToken, boardingPass)) {
        return Left(ValidationFailure('QR token does not match boarding pass'));
      }

      // Additional server-side validations
      if (!_isValidForRemoteAccess(boardingPass)) {
        return Left(
          ValidationFailure('Boarding pass not valid for remote access'),
        );
      }

      // Mark token as used
      _usedTokens.add(qrToken);

      return Right(boardingPass);
    } catch (e) {
      _logger.e('Error verifying QR code', error: e);
      return Left(NetworkFailure('Failed to verify QR code: $e'));
    }
  }

  @override
  Future<Either<Failure, BoardingPass?>> getBoardingPass(PassId passId) async {
    await _simulateDelay();

    if (_simulateErrors && _random.nextDouble() < 0.1) {
      return Left(NetworkFailure('Simulated network error'));
    }

    try {
      final boardingPass = _boardingPassDatabase[passId.value];

      _logger.d(
        boardingPass != null
            ? 'Boarding pass found: ${passId.value}'
            : 'Boarding pass not found: ${passId.value}',
      );

      return Right(boardingPass);
    } catch (e) {
      _logger.e('Error fetching boarding pass', error: e);
      return Left(NetworkFailure('Failed to fetch boarding pass: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BoardingPass>>> getBoardingPassesForMember(
    MemberNumber memberNumber,
  ) async {
    await _simulateDelay();

    try {
      final passIds = _memberPassIndex[memberNumber.value] ?? [];
      final boardingPasses = passIds
          .map((id) => _boardingPassDatabase[id])
          .where((pass) => pass != null)
          .cast<BoardingPass>()
          .toList();

      // Sort by departure time
      boardingPasses.sort(
        (a, b) => a.scheduleSnapshot.departureTime.compareTo(
          b.scheduleSnapshot.departureTime,
        ),
      );

      return Right(boardingPasses);
    } catch (e) {
      _logger.e('Error fetching member boarding passes', error: e);
      return Left(NetworkFailure('Failed to fetch boarding passes: $e'));
    }
  }

  @override
  Future<Either<Failure, BoardingPass>> updateBoardingPassStatus(
    BoardingPass boardingPass,
  ) async {
    await _simulateDelay();

    try {
      final existingPass = _boardingPassDatabase[boardingPass.passId.value];
      if (existingPass == null) {
        return Left(NotFoundFailure('Boarding pass not found'));
      }

      // Simulate server-side business rules
      if (!_canUpdateStatus(existingPass, boardingPass)) {
        return Left(ValidationFailure('Invalid status transition'));
      }

      // Update the database
      _boardingPassDatabase[boardingPass.passId.value] = boardingPass;

      return Right(boardingPass);
    } catch (e) {
      _logger.e('Error updating boarding pass status', error: e);
      return Left(NetworkFailure('Failed to update boarding pass: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BoardingPass>>> syncBoardingPasses(
    List<BoardingPass> localPasses,
  ) async {
    await _simulateDelay(
      Duration(milliseconds: 500 + localPasses.length * 100),
    );

    try {
      final syncedPasses = <BoardingPass>[];

      for (final localPass in localPasses) {
        final serverPass = _boardingPassDatabase[localPass.passId.value];

        if (serverPass == null) {
          // Local pass doesn't exist on server - upload it
          _addBoardingPassToDatabase(localPass);
          syncedPasses.add(localPass);
        } else {
          // Resolve conflicts based on last modified time
          final resolvedPass = _resolveConflict(localPass, serverPass);
          _boardingPassDatabase[resolvedPass.passId.value] = resolvedPass;
          syncedPasses.add(resolvedPass);
        }
      }

      return Right(syncedPasses);
    } catch (e) {
      _logger.e('Error syncing boarding passes', error: e);
      return Left(NetworkFailure('Failed to sync boarding passes: $e'));
    }
  }

  @override
  Future<Either<Failure, BoardingPassValidationResponse>> validateForBoarding(
    String passId,
    String gateCode,
  ) async {
    await _simulateDelay(const Duration(milliseconds: 300));

    try {
      final boardingPass = _boardingPassDatabase[passId];
      if (boardingPass == null) {
        return Right(
          BoardingPassValidationResponse.invalid('Boarding pass not found'),
        );
      }

      // Gate-specific validations
      if (!_isValidAtGate(boardingPass, gateCode)) {
        return Right(
          BoardingPassValidationResponse.invalid(
            'Not valid at this gate',
            metadata: {'expectedGate': _getExpectedGate(boardingPass)},
          ),
        );
      }

      if (!boardingPass.isValidForBoarding) {
        return Right(
          BoardingPassValidationResponse.invalid(
            'Not valid for boarding: ${boardingPass.status.name}',
          ),
        );
      }

      // Simulate successful validation
      final metadata = {
        'gateCode': gateCode,
        'validatedAt': tz.TZDateTime.now(tz.local).toIso8601String(),
        'flightNumber': boardingPass.flightNumber.value,
        'seatNumber': boardingPass.seatNumber.value,
      };

      return Right(
        BoardingPassValidationResponse.valid(boardingPass, metadata: metadata),
      );
    } catch (e) {
      _logger.e('Error validating for boarding', error: e);
      return Left(NetworkFailure('Failed to validate for boarding: $e'));
    }
  }

  // =============================================================================
  // Private Helper Methods
  // =============================================================================

  Future<void> _simulateDelay([Duration? customDelay]) async {
    if (!_simulateNetworkDelay) return;

    final delay =
        customDelay ?? Duration(milliseconds: 200 + _random.nextInt(300));
    await Future.delayed(delay);
  }

  bool _isValidToken(String token) {
    // Basic token validation - check format and length
    return token.isNotEmpty &&
        token.length >= 10 &&
        !token.contains('invalid') &&
        !token.contains(' ');
  }

  /// Verify that the QR token actually comes from the boarding pass
  bool _verifyQRTokenMatchesPass(String qrToken, BoardingPass boardingPass) {
    try {
      // Extract token from boarding pass QR code
      final passQRString = boardingPass.qrCode.toQRString();
      final passQRData = QRCodeData.fromQRString(passQRString);

      // Compare tokens
      return passQRData.token == qrToken;
    } catch (e) {
      _logger.w('Failed to verify QR token match: $e');
      return false;
    }
  }

  bool _isValidForRemoteAccess(BoardingPass boardingPass) {
    // Business rules for remote access
    return boardingPass.status != PassStatus.cancelled &&
        boardingPass.status != PassStatus.expired;
  }

  bool _canUpdateStatus(BoardingPass existing, BoardingPass updated) {
    // Simulate server-side status transition rules
    final validTransitions = {
      PassStatus.issued: [PassStatus.activated, PassStatus.cancelled],
      PassStatus.activated: [PassStatus.used, PassStatus.cancelled],
      PassStatus.used: <PassStatus>[],
      PassStatus.cancelled: <PassStatus>[],
      PassStatus.expired: <PassStatus>[],
    };

    return validTransitions[existing.status]?.contains(updated.status) ?? false;
  }

  bool _isValidAtGate(BoardingPass boardingPass, String gateCode) {
    // Use the gate from flight schedule snapshot
    final expectedGate = boardingPass.scheduleSnapshot.gate.value;
    return expectedGate == gateCode;
  }

  String _getExpectedGate(BoardingPass boardingPass) {
    return boardingPass.scheduleSnapshot.gate.value;
  }

  BoardingPass _resolveConflict(BoardingPass local, BoardingPass server) {
    // Simple conflict resolution: use the one with latest modification
    if (local.activatedAt != null && server.activatedAt != null) {
      return local.activatedAt!.isAfter(server.activatedAt!) ? local : server;
    }
    return local.issueTime.isAfter(server.issueTime) ? local : server;
  }

  void _addBoardingPassToDatabase(BoardingPass boardingPass) {
    _boardingPassDatabase[boardingPass.passId.value] = boardingPass;

    final memberNumber = boardingPass.memberNumber.value;
    _memberPassIndex[memberNumber] = [
      ...(_memberPassIndex[memberNumber] ?? []),
      boardingPass.passId.value,
    ];
  }

  // =============================================================================
  // Debug and Testing Methods
  // =============================================================================

  /// Get current database state for debugging
  Map<String, dynamic> getDebugInfo() {
    return {
      'totalBoardingPasses': _boardingPassDatabase.length,
      'totalMembers': _memberPassIndex.length,
      'usedTokensCount': _usedTokens.length,
      'passIds': _boardingPassDatabase.keys.toList(),
      'memberNumbers': _memberPassIndex.keys.toList(),
    };
  }

  /// Clear used tokens for testing
  void clearUsedTokens() {
    _usedTokens.clear();
  }

  /// Check if a boarding pass exists in remote database
  bool hasBoardingPass(String passId) {
    return _boardingPassDatabase.containsKey(passId);
  }
}
