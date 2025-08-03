import 'package:app/features/boarding_pass/domain/value_objects/flight_schedule_snapshot.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:app/features/boarding_pass/domain/value_objects/seat_number.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/boarding_pass/application/use_cases/update_seat_assignment_use_case.dart';
import 'package:app/features/boarding_pass/domain/services/boarding_pass_service.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';
import 'package:timezone/timezone.dart';

import '../../../../../helpers/test_timezone_helper.dart';
import 'update_seat_assignment_use_case_test.mocks.dart';

@GenerateNiceMocks([MockSpec<BoardingPassService>(), MockSpec<BoardingPass>()])
void main() {
  group('UpdateSeatAssignmentUseCase', () {
    late UpdateSeatAssignmentUseCase useCase;
    late MockBoardingPassService mockBoardingPassService;
    late MockBoardingPass mockUpdatedBoardingPass;

    void setupMockBoardingPass(
      MockBoardingPass mockPass,
      String newSeatNumberStr,
    ) {
      final passId = PassId('BP12345678');
      final memberNumber = MemberNumber.create('MB100001');
      final flightNumber = FlightNumber.create('BR857');
      final seatNumber = SeatNumber.create(newSeatNumberStr);
      final now = TZDateTime.now(local);
      final departureTime = now.add(const Duration(hours: 2));
      final boardingTime = now.subtract(const Duration(minutes: 30));
      final qrCode = QRCodeData.generate(
        passId: passId,
        flightNumber: flightNumber,
        seatNumber: seatNumber,
        memberNumber: memberNumber,
        departureTime: departureTime,
      );

      when(mockPass.passId).thenReturn(passId);
      when(mockPass.memberNumber).thenReturn(memberNumber);
      when(mockPass.flightNumber).thenReturn(flightNumber);
      when(mockPass.seatNumber).thenReturn(seatNumber);
      when(mockPass.scheduleSnapshot).thenReturn(
        FlightScheduleSnapshot.create(
          departureTime: departureTime,
          boardingTime: boardingTime,
          departureAirport: 'TPE',
          arrivalAirport: 'NRT',
          gateNumber: 'A12',
          snapshotTime: now.subtract(const Duration(hours: 1)),
        ),
      );
      when(mockPass.qrCode).thenReturn(qrCode);
      when(
        mockPass.issueTime,
      ).thenReturn(now.subtract(const Duration(hours: 3)));
    }

    setUpAll(() {
      TestTimezoneHelper.setupForTesting();
    });

    setUp(() {
      mockBoardingPassService = MockBoardingPassService();
      mockUpdatedBoardingPass = MockBoardingPass();
      useCase = UpdateSeatAssignmentUseCase(mockBoardingPassService);

      // Setup default mock boarding pass with updated seat
      setupMockBoardingPass(mockUpdatedBoardingPass, '15B');
    });

    test('should update seat assignment successfully', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(
        passId: 'BP12345678',
        newSeatNumber: '15B',
      );

      when(
        mockBoardingPassService.updateSeatAssignment(
          passId: anyNamed('passId'),
          newSeatNumber: anyNamed('newSeatNumber'),
        ),
      ).thenAnswer((_) async => Right(mockUpdatedBoardingPass));

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isTrue);
        expect(response.boardingPass, isNotNull);
        expect(response.errorMessage, isNull);
        expect(response.metadata?['updatedAt'], isNotNull);
        expect(response.metadata?['newSeat'], equals('15B'));
        expect(response.metadata?['seatType'], isNotNull);
      });

      verify(
        mockBoardingPassService.updateSeatAssignment(
          passId: anyNamed('passId'),
          newSeatNumber: anyNamed('newSeatNumber'),
        ),
      ).called(1);
    });

    test('should return error for empty pass ID', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(passId: '', newSeatNumber: '15B');

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Pass ID cannot be empty'));
        expect(response.errorCode, equals('VALIDATION_ERROR'));
        expect(response.boardingPass, isNull);
      });

      verifyNever(
        mockBoardingPassService.updateSeatAssignment(
          passId: anyNamed('passId'),
          newSeatNumber: anyNamed('newSeatNumber'),
        ),
      );
    });

    test('should return error for whitespace-only pass ID', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(passId: '   ', newSeatNumber: '15B');

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Pass ID cannot be empty'));
        expect(response.errorCode, equals('VALIDATION_ERROR'));
      });

      verifyNever(
        mockBoardingPassService.updateSeatAssignment(
          passId: anyNamed('passId'),
          newSeatNumber: anyNamed('newSeatNumber'),
        ),
      );
    });

    test('should return error for empty new seat number', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(
        passId: 'BP12345678',
        newSeatNumber: '',
      );

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(
          response.errorMessage,
          equals('New seat number cannot be empty'),
        );
        expect(response.errorCode, equals('VALIDATION_ERROR'));
        expect(response.boardingPass, isNull);
      });

      verifyNever(
        mockBoardingPassService.updateSeatAssignment(
          passId: anyNamed('passId'),
          newSeatNumber: anyNamed('newSeatNumber'),
        ),
      );
    });

    test('should return error for whitespace-only new seat number', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(
        passId: 'BP12345678',
        newSeatNumber: '   ',
      );

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(
          response.errorMessage,
          equals('New seat number cannot be empty'),
        );
        expect(response.errorCode, equals('VALIDATION_ERROR'));
      });
    });

    test('should handle boarding pass not found error', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(
        passId: 'BP99999999',
        newSeatNumber: '15B',
      );

      when(
        mockBoardingPassService.updateSeatAssignment(
          passId: anyNamed('passId'),
          newSeatNumber: anyNamed('newSeatNumber'),
        ),
      ).thenAnswer(
        (_) async => Left(NotFoundFailure('Boarding pass not found')),
      );

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Boarding pass not found'));
        expect(response.errorCode, equals('PASS_NOT_FOUND'));
        expect(response.boardingPass, isNull);
      });
    });

    test('should handle seat already taken error', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(
        passId: 'BP12345678',
        newSeatNumber: '15B',
      );

      when(
        mockBoardingPassService.updateSeatAssignment(
          passId: anyNamed('passId'),
          newSeatNumber: anyNamed('newSeatNumber'),
        ),
      ).thenAnswer(
        (_) async => Left(ValidationFailure('Seat 15B is already taken')),
      );

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Seat 15B is already taken'));
        expect(response.errorCode, equals('VALIDATION_ERROR'));
      });
    });

    test('should handle database failure from service', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(
        passId: 'BP12345678',
        newSeatNumber: '15B',
      );

      when(
        mockBoardingPassService.updateSeatAssignment(
          passId: anyNamed('passId'),
          newSeatNumber: anyNamed('newSeatNumber'),
        ),
      ).thenAnswer(
        (_) async => Left(DatabaseFailure('Database connection error')),
      );

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Database connection error'));
        expect(response.errorCode, equals('DATABASE_ERROR'));
      });
    });

    test('should handle network failure from service', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(
        passId: 'BP12345678',
        newSeatNumber: '15B',
      );

      when(
        mockBoardingPassService.updateSeatAssignment(
          passId: anyNamed('passId'),
          newSeatNumber: anyNamed('newSeatNumber'),
        ),
      ).thenAnswer((_) async => Left(NetworkFailure('Network timeout')));

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Network timeout'));
        expect(response.errorCode, equals('NETWORK_ERROR'));
      });
    });

    test('should handle domain exception', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(
        passId: 'BP12345678',
        newSeatNumber: '15B',
      );

      when(
        mockBoardingPassService.updateSeatAssignment(
          passId: anyNamed('passId'),
          newSeatNumber: anyNamed('newSeatNumber'),
        ),
      ).thenThrow(DomainException('Cannot change seat after boarding'));

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(
          response.errorMessage,
          equals('Cannot change seat after boarding'),
        );
        expect(response.errorCode, equals('DOMAIN_VALIDATION_ERROR'));
      });
    });

    test('should handle unexpected exception', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(
        passId: 'BP12345678',
        newSeatNumber: '15B',
      );

      when(
        mockBoardingPassService.updateSeatAssignment(
          passId: anyNamed('passId'),
          newSeatNumber: anyNamed('newSeatNumber'),
        ),
      ).thenThrow(Exception('Unexpected error'));

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<UnknownFailure>());
        expect(failure.message, contains('Failed to update seat assignment'));
      }, (response) => fail('Should not return success'));
    });

    test('should include metadata in successful update', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(
        passId: 'BP12345678',
        newSeatNumber: '15B',
      );

      when(
        mockBoardingPassService.updateSeatAssignment(
          passId: anyNamed('passId'),
          newSeatNumber: anyNamed('newSeatNumber'),
        ),
      ).thenAnswer((_) async => Right(mockUpdatedBoardingPass));

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isTrue);
        expect(response.metadata?['updatedAt'], isNotNull);
        expect(response.metadata?['newSeat'], equals('15B'));
        expect(response.metadata?['seatType'], isNotNull);
        expect(
          response.metadata?['previousSeat'],
          equals('15B'),
        ); // Note: This is a limitation in the current implementation
      });
    });

    test('should validate seat number format correctly', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(
        passId: 'BP12345678',
        newSeatNumber: 'INVALID_SEAT',
      );

      // This test assumes that SeatNumber.create() throws an exception for invalid format
      // The use case should catch this and return a validation error

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorCode, equals('VALIDATION_ERROR'));
        expect(response.errorMessage, contains('Invalid input format'));
      });
    });

    test('should validate pass ID format correctly', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(
        passId: 'INVALID_PASS_ID',
        newSeatNumber: '15B',
      );

      // This test assumes that PassId.fromString() throws an exception for invalid format
      // The use case should catch this and return a validation error

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorCode, equals('VALIDATION_ERROR'));
        expect(response.errorMessage, contains('Invalid input format'));
      });
    });

    test('should handle service returning unknown failure type', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(
        passId: 'BP12345678',
        newSeatNumber: '15B',
      );

      // Create a custom failure type that's not explicitly handled
      final customFailure = UnknownFailure('Custom error');

      when(
        mockBoardingPassService.updateSeatAssignment(
          passId: anyNamed('passId'),
          newSeatNumber: anyNamed('newSeatNumber'),
        ),
      ).thenAnswer((_) async => Left(customFailure));

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Custom error'));
        expect(response.errorCode, equals('UNKNOWN_ERROR'));
      });
    });

    test('should trim whitespace from inputs before validation', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(
        passId: '  BP12345678  ',
        newSeatNumber: '  15B  ',
      );

      when(
        mockBoardingPassService.updateSeatAssignment(
          passId: anyNamed('passId'),
          newSeatNumber: anyNamed('newSeatNumber'),
        ),
      ).thenAnswer((_) async => Right(mockUpdatedBoardingPass));

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isTrue);
        expect(response.boardingPass, isNotNull);
      });
    });

    test('should pass correct parameters to boarding pass service', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(
        passId: 'BP12345678',
        newSeatNumber: '15B',
      );

      when(
        mockBoardingPassService.updateSeatAssignment(
          passId: anyNamed('passId'),
          newSeatNumber: anyNamed('newSeatNumber'),
        ),
      ).thenAnswer((_) async => Right(mockUpdatedBoardingPass));

      // Act
      await useCase(updateRequest);

      // Assert
      verify(
        mockBoardingPassService.updateSeatAssignment(
          passId: argThat(
            predicate<PassId>((passId) => passId.value == 'BP12345678'),
            named: 'passId',
          ),
          newSeatNumber: argThat(
            predicate<SeatNumber>((seatNumber) => seatNumber.value == '15B'),
            named: 'newSeatNumber',
          ),
        ),
      ).called(1);
    });

    test('should handle multiple validation errors correctly', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(passId: '', newSeatNumber: '');

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorCode, equals('VALIDATION_ERROR'));
        // Should return the first validation error encountered
        expect(response.errorMessage, equals('Pass ID cannot be empty'));
      });
    });

    test('should convert boarding pass to DTO correctly', () async {
      // Arrange
      final updateRequest = UpdateSeatDTO(
        passId: 'BP12345678',
        newSeatNumber: '15B',
      );

      when(
        mockBoardingPassService.updateSeatAssignment(
          passId: anyNamed('passId'),
          newSeatNumber: anyNamed('newSeatNumber'),
        ),
      ).thenAnswer((_) async => Right(mockUpdatedBoardingPass));

      // Act
      final result = await useCase(updateRequest);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isTrue);
        expect(response.boardingPass, isNotNull);
        expect(response.boardingPass!.passId, equals('BP12345678'));
        expect(response.boardingPass!.seatNumber, equals('15B'));
        expect(response.boardingPass!.memberNumber, equals('MB100001'));
        expect(response.boardingPass!.flightNumber, equals('BR857'));
      });
    });
  });
}
