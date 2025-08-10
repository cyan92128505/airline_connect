import 'dart:math';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';
import 'package:app/features/boarding_pass/domain/datasources/boarding_pass_remote_dataSource.dart';
import 'package:app/features/boarding_pass/domain/value_objects/flight_schedule_snapshot.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:dartz/dartz.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:logger/logger.dart';

/// Mock implementation simulating a real backend service
/// Includes business logic, authentication, and realistic delays
class MockBoardingPassRemoteDataSource implements BoardingPassRemoteDataSource {
  static final Logger _logger = Logger();

  // Simulated database
  final Map<String, BoardingPass> _boardingPassDatabase = {};
  final Map<String, List<String>> _memberPassIndex = {};
  final Map<String, String> _qrTokenIndex = {}; // QR token to pass ID mapping
  final Set<String> _usedTokens = {}; // Prevent replay attacks

  final Random _random = Random();
  final bool _simulateNetworkDelay;
  final bool _simulateErrors;

  MockBoardingPassRemoteDataSource({
    bool simulateNetworkDelay = true,
    bool simulateErrors = false,
  }) : _simulateNetworkDelay = simulateNetworkDelay,
       _simulateErrors = simulateErrors {
    _seedTestData();
  }

  @override
  Future<Either<Failure, BoardingPass?>> verifyQRCodeAndGetPass(
    String passId,
    String qrToken,
  ) async {
    await _simulateDelay();

    try {
      _logger.d('Verifying QR code for pass: $passId');

      // Simulate authentication check
      if (!_isValidToken(qrToken)) {
        return Left(AuthenticationFailure('Invalid QR token'));
      }

      // Check if token was already used (replay attack prevention)
      if (_usedTokens.contains(qrToken)) {
        return Left(ValidationFailure('QR token already used'));
      }

      // Verify token maps to the claimed pass ID
      final tokenPassId = _qrTokenIndex[qrToken];
      if (tokenPassId != passId) {
        return Left(ValidationFailure('QR token does not match pass ID'));
      }

      final boardingPass = _boardingPassDatabase[passId];
      if (boardingPass == null) {
        return const Right(null);
      }

      // Additional server-side validations
      if (!_isValidForRemoteAccess(boardingPass)) {
        return Left(
          ValidationFailure('Boarding pass not valid for remote access'),
        );
      }

      // Mark token as used
      _usedTokens.add(qrToken);

      _logger.d('QR code verified successfully for pass: $passId');
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
      _logger.d('Fetching boarding pass: ${passId.value}');

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
      _logger.d('Fetching boarding passes for member: ${memberNumber.value}');

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

      _logger.d('Found ${boardingPasses.length} boarding passes for member');
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
      _logger.d('Updating boarding pass status: ${boardingPass.passId.value}');

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

      _logger.d('Boarding pass status updated successfully');
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
      _logger.d('Syncing ${localPasses.length} boarding passes');

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

      _logger.d('Sync completed for ${syncedPasses.length} passes');
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
      _logger.d('Validating boarding pass $passId at gate $gateCode');

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
    // Simulate token validation logic
    return token.length > 10 && !token.contains('invalid');
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
    // Simulate gate validation logic
    final expectedGate = _getExpectedGate(boardingPass);
    return expectedGate == gateCode;
  }

  String _getExpectedGate(BoardingPass boardingPass) {
    // Simulate gate assignment logic based on flight number
    final flightNumber = boardingPass.flightNumber.value;
    final hashCode = flightNumber.hashCode.abs();
    final gateNumber = (hashCode % 20) + 1;
    return 'A$gateNumber';
  }

  BoardingPass _resolveConflict(BoardingPass local, BoardingPass server) {
    // Simple conflict resolution: use the one with latest modification
    // In real implementation, this would be more sophisticated
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

  /// Seed test data for development and demo
  void _seedTestData() {
    _logger.d('Seeding test data for mock remote datasource');

    final now = tz.TZDateTime.now(tz.local);

    // Create test boarding passes
    final testPasses = [
      _createTestBoardingPass(
        passId: 'test-pass-001',
        memberNumber: 'M123456',
        flightNumber: 'AC101',
        seatNumber: '12A',
        departureTime: now.add(const Duration(hours: 4)),
        status: PassStatus.issued,
      ),
      _createTestBoardingPass(
        passId: 'test-pass-002',
        memberNumber: 'M123456',
        flightNumber: 'AC201',
        seatNumber: '15B',
        departureTime: now.add(const Duration(days: 1, hours: 2)),
        status: PassStatus.activated,
      ),
      _createTestBoardingPass(
        passId: 'test-pass-003',
        memberNumber: 'M789012',
        flightNumber: 'WS501',
        seatNumber: '8C',
        departureTime: now.subtract(const Duration(hours: 2)),
        status: PassStatus.expired,
      ),
    ];

    for (final pass in testPasses) {
      _addBoardingPassToDatabase(pass);
      // Create mock QR tokens
      _qrTokenIndex['mock-token-${pass.passId.value}'] = pass.passId.value;
    }

    _logger.d('Seeded ${testPasses.length} test boarding passes');
  }

  BoardingPass _createTestBoardingPass({
    required String passId,
    required String memberNumber,
    required String flightNumber,
    required String seatNumber,
    required tz.TZDateTime departureTime,
    required PassStatus status,
  }) {
    final issueTime = tz.TZDateTime.now(
      tz.local,
    ).subtract(const Duration(hours: 12));

    final scheduleSnapshot = FlightScheduleSnapshot.create(
      departureTime: departureTime,
      boardingTime: departureTime.subtract(const Duration(minutes: 30)),
      departureAirport: 'YVR', // Vancouver
      arrivalAirport: 'YYZ', // Toronto
      gateNumber: 'A15',
      snapshotTime: issueTime,
    );

    return BoardingPass.fromPersistence(
      passId: passId,
      memberNumber: memberNumber,
      flightNumber: flightNumber,
      seatNumber: seatNumber,
      scheduleSnapshot: scheduleSnapshot,
      status: status,
      qrCode: QRCodeData.create(
        token: 'mock-token',
        signature: 'mock-signature',
        generatedAt: issueTime,
      ),
      issueTime: issueTime,
      activatedAt: status == PassStatus.activated
          ? issueTime.add(const Duration(hours: 1))
          : null,
    );
  }
}
