import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/application/services/boarding_pass_application_service.dart';
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
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';

import 'boarding_pass_application_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<CreateBoardingPassUseCase>(),
  MockSpec<ActivateBoardingPassUseCase>(),
  MockSpec<UseBoardingPassUseCase>(),
  MockSpec<UpdateSeatAssignmentUseCase>(),
  MockSpec<ValidateQRCodeUseCase>(),
  MockSpec<GetBoardingPassesForMemberUseCase>(),
  MockSpec<GetBoardingPassDetailsUseCase>(),
  MockSpec<ValidateBoardingEligibilityUseCase>(),
  MockSpec<AutoExpireBoardingPassesUseCase>(),
])
void main() {
  late BoardingPassApplicationService service;
  late MockCreateBoardingPassUseCase mockCreateUseCase;
  late MockActivateBoardingPassUseCase mockActivateUseCase;
  late MockUseBoardingPassUseCase mockUseUseCase;
  late MockUpdateSeatAssignmentUseCase mockUpdateSeatUseCase;
  late MockValidateQRCodeUseCase mockValidateQRUseCase;
  late MockGetBoardingPassesForMemberUseCase mockGetPassesUseCase;
  late MockGetBoardingPassDetailsUseCase mockGetDetailsUseCase;
  late MockValidateBoardingEligibilityUseCase mockValidateEligibilityUseCase;
  late MockAutoExpireBoardingPassesUseCase mockAutoExpireUseCase;

  setUp(() {
    mockCreateUseCase = MockCreateBoardingPassUseCase();
    mockActivateUseCase = MockActivateBoardingPassUseCase();
    mockUseUseCase = MockUseBoardingPassUseCase();
    mockUpdateSeatUseCase = MockUpdateSeatAssignmentUseCase();
    mockValidateQRUseCase = MockValidateQRCodeUseCase();
    mockGetPassesUseCase = MockGetBoardingPassesForMemberUseCase();
    mockGetDetailsUseCase = MockGetBoardingPassDetailsUseCase();
    mockValidateEligibilityUseCase = MockValidateBoardingEligibilityUseCase();
    mockAutoExpireUseCase = MockAutoExpireBoardingPassesUseCase();

    service = BoardingPassApplicationService(
      mockCreateUseCase,
      mockActivateUseCase,
      mockUseUseCase,
      mockUpdateSeatUseCase,
      mockValidateQRUseCase,
      mockGetPassesUseCase,
      mockGetDetailsUseCase,
      mockValidateEligibilityUseCase,
      mockAutoExpireUseCase,
    );
  });

  /// Helper method to create sample BoardingPassDTO for testing
  BoardingPassDTO createSampleBoardingPassDTO() {
    return BoardingPassDTO(
      passId: 'BP123456789',
      memberNumber: 'M1001',
      flightNumber: 'BR857',
      seatNumber: '12A',
      scheduleSnapshot: FlightScheduleSnapshotDTO(
        departureTime: '2025-07-17T10:30:00Z',
        boardingTime: '2025-07-17T10:00:00Z',
        departure: 'TPE',
        arrival: 'NRT',
        gate: 'A12',
        snapshotTime: '2025-07-17T08:00:00Z',
        routeDescription: 'Taipei to Tokyo Narita',
        isInBoardingWindow: true,
        hasDeparted: false,
      ),
      status: PassStatus.activated,
      qrCode: QRCodeDataDTO(
        encryptedPayload: 'encrypted_data_123',
        checksum: 'checksum_abc',
        generatedAt: '2025-07-17T09:00:00Z',
        version: 1,
        isValid: true,
        timeRemainingMinutes: 30,
      ),
      issueTime: '2025-07-17T08:30:00Z',
      activatedAt: '2025-07-17T09:00:00Z',
      usedAt: null,
      isValidForBoarding: true,
      isActive: true,
      timeUntilDepartureMinutes: 90,
    );
  }

  group('BoardingPassApplicationService - Create Operations', () {
    test('should create boarding pass successfully', () async {
      // Arrange
      final successResponse = BoardingPassOperationResponseDTO.success(
        boardingPass: createSampleBoardingPassDTO(),
      );

      when(
        mockCreateUseCase.call(any),
      ).thenAnswer((_) async => Right(successResponse));

      // Act
      final result = await service.createBoardingPass(
        memberNumber: 'M1001',
        flightNumber: 'BR857',
        seatNumber: '12A',
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isTrue);
        expect(response.boardingPass?.passId, isNotNull);
      });

      verify(mockCreateUseCase.call(any)).called(1);
    });

    test('should handle create boarding pass failure', () async {
      // Arrange
      final errorResponse = BoardingPassOperationResponseDTO.error(
        errorMessage: 'Flight not found',
        errorCode: 'FLIGHT_NOT_FOUND',
      );

      when(
        mockCreateUseCase.call(any),
      ).thenAnswer((_) async => Right(errorResponse));

      // Act
      final result = await service.createBoardingPass(
        memberNumber: 'M1001',
        flightNumber: 'INVALID',
        seatNumber: '12A',
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Flight not found'));
        expect(response.errorCode, equals('FLIGHT_NOT_FOUND'));
      });
    });
  });

  group('BoardingPassApplicationService - Pass Operations', () {
    test('should activate boarding pass successfully', () async {
      // Arrange
      final successResponse = BoardingPassOperationResponseDTO.success(
        boardingPass: createSampleBoardingPassDTO(),
      );

      when(
        mockActivateUseCase.call('BP123456789'),
      ).thenAnswer((_) async => Right(successResponse));

      // Act
      final result = await service.activateBoardingPass('BP123456789');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (response) => expect(response.success, isTrue),
      );
    });

    test('should use boarding pass successfully', () async {
      // Arrange
      final usedPass = createSampleBoardingPassDTO().copyWith(
        status: PassStatus.used,
        usedAt: DateTime.now().toIso8601String(),
      );
      final successResponse = BoardingPassOperationResponseDTO.success(
        boardingPass: usedPass,
      );

      when(
        mockUseUseCase.call('BP123456789'),
      ).thenAnswer((_) async => Right(successResponse));

      // Act
      final result = await service.useBoardingPass('BP123456789');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isTrue);
        expect(response.boardingPass?.status, equals(PassStatus.used));
      });
    });

    test('should update seat assignment successfully', () async {
      // Arrange
      final updatedPass = createSampleBoardingPassDTO().copyWith(
        seatNumber: '15B',
      );
      final successResponse = BoardingPassOperationResponseDTO.success(
        boardingPass: updatedPass,
      );

      when(
        mockUpdateSeatUseCase.call(any),
      ).thenAnswer((_) async => Right(successResponse));

      // Act
      final result = await service.updateSeatAssignment(
        passId: 'BP123456789',
        newSeatNumber: '15B',
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isTrue);
        expect(response.boardingPass?.seatNumber, equals('15B'));
      });
    });
  });

  group('BoardingPassApplicationService - Query Operations', () {
    test('should get boarding passes for member successfully', () async {
      // Arrange
      final passes = [createSampleBoardingPassDTO()];
      when(
        mockGetPassesUseCase.call(any),
      ).thenAnswer((_) async => Right(passes));

      // Act
      final result = await service.getBoardingPassesForMember('M1001');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passList) {
        expect(passList.length, equals(1));
        expect(passList.first.memberNumber, equals('M1001'));
      });
    });

    test('should get boarding pass details successfully', () async {
      // Arrange
      final passDetails = createSampleBoardingPassDTO();
      when(
        mockGetDetailsUseCase.call('BP123456789'),
      ).thenAnswer((_) async => Right(passDetails));

      // Act
      final result = await service.getBoardingPassDetails('BP123456789');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (pass) => expect(pass.passId, equals('BP123456789')),
      );
    });

    test('should handle member not found error', () async {
      // Arrange
      when(
        mockGetPassesUseCase.call(any),
      ).thenAnswer((_) async => Left(NotFoundFailure('Member not found')));

      // Act
      final result = await service.getBoardingPassesForMember('INVALID');

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (passes) => fail('Should not return success'),
      );
    });
  });

  group('BoardingPassApplicationService - Validation Operations', () {
    test('should validate QR code successfully', () async {
      // Arrange
      final validResponse = QRCodeValidationResponseDTO.valid(
        passId: 'BP123456789',
        flightNumber: 'BR857',
        seatNumber: '12A',
        memberNumber: 'M1001',
        departureTime: '2025-07-17T10:30:00Z',
      );

      when(
        mockValidateQRUseCase.call(any),
      ).thenAnswer((_) async => Right(validResponse));

      // Act
      final result = await service.validateQRCode(
        encryptedPayload: 'encrypted_data_123',
        checksum: 'checksum_abc',
        generatedAt: '2025-07-17T09:00:00Z',
        version: 1,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isTrue);
        expect(response.passId, equals('BP123456789'));
      });
    });

    test('should validate boarding eligibility successfully', () async {
      // Arrange
      final eligibleResponse = BoardingEligibilityResponseDTO.eligible(
        passId: 'BP123456789',
        timeUntilDepartureMinutes: 90,
        isInBoardingWindow: true,
      );

      when(
        mockValidateEligibilityUseCase.call('BP123456789'),
      ).thenAnswer((_) async => Right(eligibleResponse));

      // Act
      final result = await service.validateBoardingEligibility('BP123456789');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isEligible, isTrue);
        expect(response.passId, equals('BP123456789'));
      });
    });

    test('should handle invalid QR code validation', () async {
      // Arrange
      final invalidResponse = QRCodeValidationResponseDTO.invalid(
        errorMessage: 'QR code expired',
      );

      when(
        mockValidateQRUseCase.call(any),
      ).thenAnswer((_) async => Right(invalidResponse));

      // Act
      final result = await service.validateQRCode(
        encryptedPayload: 'expired_data',
        checksum: 'invalid_checksum',
        generatedAt: '2025-07-16T09:00:00Z',
        version: 1,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isValid, isFalse);
        expect(response.errorMessage, equals('QR code expired'));
      });
    });
  });

  group('BoardingPassApplicationService - Convenience Methods', () {
    test('should check if member has boarding pass for flight', () async {
      // Arrange
      final passes = [createSampleBoardingPassDTO()];
      when(
        mockGetPassesUseCase.call(any),
      ).thenAnswer((_) async => Right(passes));

      // Act
      final result = await service.hasBoardingPassForFlight(
        memberNumber: 'M1001',
        flightNumber: 'BR857',
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (hasPass) => expect(hasPass, isTrue),
      );
    });

    test(
      'should return false when member has no boarding pass for flight',
      () async {
        // Arrange
        when(mockGetPassesUseCase.call(any)).thenAnswer((_) async => Right([]));

        // Act
        final result = await service.hasBoardingPassForFlight(
          memberNumber: 'M1001',
          flightNumber: 'BR999',
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not return failure'),
          (hasPass) => expect(hasPass, isFalse),
        );
      },
    );

    test('should get boarding pass statistics for member', () async {
      // Arrange
      final passes = [
        createSampleBoardingPassDTO().copyWith(status: PassStatus.activated),
        createSampleBoardingPassDTO().copyWith(status: PassStatus.used),
        createSampleBoardingPassDTO().copyWith(status: PassStatus.expired),
      ];
      when(
        mockGetPassesUseCase.call(any),
      ).thenAnswer((_) async => Right(passes));

      // Act
      final result = await service.getBoardingPassStatsForMember('M1001');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (stats) {
        expect(stats['total'], equals(3));
        expect(stats['used'], equals(1));
        expect(stats['expired'], equals(1));
        expect(stats['byStatus'], isA<Map<String, int>>());
      });
    });

    test('should batch validate multiple boarding passes', () async {
      // Arrange
      final eligibleResponse = BoardingEligibilityResponseDTO.eligible(
        passId: 'BP123456789',
        timeUntilDepartureMinutes: 90,
        isInBoardingWindow: true,
      );

      when(
        mockValidateEligibilityUseCase.call(any),
      ).thenAnswer((_) async => Right(eligibleResponse));

      // Act
      final results = await service.batchValidateBoardingEligibility([
        'BP123456789',
        'BP987654321',
      ]);

      // Assert
      expect(results.length, equals(2));
      expect(results['BP123456789']?.isRight(), isTrue);
      expect(results['BP987654321']?.isRight(), isTrue);
    });
  });

  group('BoardingPassApplicationService - Auto Expire', () {
    test('should auto expire boarding passes successfully', () async {
      // Arrange
      final expiredPasses = [
        createSampleBoardingPassDTO().copyWith(status: PassStatus.expired),
      ];
      when(
        mockAutoExpireUseCase.call(),
      ).thenAnswer((_) async => Right(expiredPasses));

      // Act
      final result = await service.autoExpireBoardingPasses();

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passes) {
        expect(passes.length, equals(1));
        expect(passes.first.status, equals(PassStatus.expired));
      });
    });

    test('should handle auto expire failure', () async {
      // Arrange
      when(
        mockAutoExpireUseCase.call(),
      ).thenAnswer((_) async => Left(DatabaseFailure('Database error')));

      // Act
      final result = await service.autoExpireBoardingPasses();

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (passes) => fail('Should not return success'),
      );
    });
  });
}
