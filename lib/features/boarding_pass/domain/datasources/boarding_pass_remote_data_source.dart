import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:dartz/dartz.dart';

/// Remote data source interface for boarding pass operations
/// Simulates backend API calls
abstract class BoardingPassRemoteDataSource {
  /// Verify QR code with backend and get boarding pass
  Future<Either<Failure, BoardingPass?>> verifyQRCodeAndGetPass(
    String passId,
    String qrToken,
  );

  /// Get boarding pass by ID from server
  Future<Either<Failure, BoardingPass?>> getBoardingPass(PassId passId);

  /// Get boarding passes for member from server
  Future<Either<Failure, List<BoardingPass>>> getBoardingPassesForMember(
    MemberNumber memberNumber,
  );

  /// Update boarding pass status on server
  Future<Either<Failure, BoardingPass>> updateBoardingPassStatus(
    BoardingPass boardingPass,
  );

  /// Sync local changes with server
  Future<Either<Failure, List<BoardingPass>>> syncBoardingPasses(
    List<BoardingPass> localPasses,
  );

  /// Validate boarding pass for gate scanning
  Future<Either<Failure, BoardingPassValidationResponse>> validateForBoarding(
    String passId,
    String gateCode,
  );
}

/// Response for boarding pass validation at gate
class BoardingPassValidationResponse {
  final bool isValid;
  final String reason;
  final BoardingPass? boardingPass;
  final Map<String, dynamic> metadata;

  const BoardingPassValidationResponse({
    required this.isValid,
    required this.reason,
    this.boardingPass,
    this.metadata = const {},
  });

  factory BoardingPassValidationResponse.valid(
    BoardingPass boardingPass, {
    Map<String, dynamic>? metadata,
  }) {
    return BoardingPassValidationResponse(
      isValid: true,
      reason: 'Valid for boarding',
      boardingPass: boardingPass,
      metadata: metadata ?? {},
    );
  }

  factory BoardingPassValidationResponse.invalid(
    String reason, {
    Map<String, dynamic>? metadata,
  }) {
    return BoardingPassValidationResponse(
      isValid: false,
      reason: reason,
      metadata: metadata ?? {},
    );
  }
}
