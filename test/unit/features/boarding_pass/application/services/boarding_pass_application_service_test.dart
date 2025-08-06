import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/application/services/boarding_pass_application_service.dart';
import 'package:app/features/boarding_pass/application/use_cases/activate_boarding_pass_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/validate_qr_code_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/get_boarding_passes_for_member_use_case.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';
import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';

import 'boarding_pass_application_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ActivateBoardingPassUseCase>(),
  MockSpec<ValidateQRCodeUseCase>(),
  MockSpec<GetBoardingPassesForMemberUseCase>(),
])
void main() {
  late BoardingPassApplicationService service;
  late MockActivateBoardingPassUseCase mockActivateUseCase;
  late MockValidateQRCodeUseCase mockValidateQRUseCase;
  late MockGetBoardingPassesForMemberUseCase mockGetPassesUseCase;

  setUp(() {
    mockActivateUseCase = MockActivateBoardingPassUseCase();
    mockValidateQRUseCase = MockValidateQRCodeUseCase();
    mockGetPassesUseCase = MockGetBoardingPassesForMemberUseCase();

    service = BoardingPassApplicationService(
      mockActivateUseCase,
      mockValidateQRUseCase,
      mockGetPassesUseCase,
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
}
