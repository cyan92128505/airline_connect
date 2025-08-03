import 'package:app/features/boarding_pass/domain/value_objects/flight_schedule_snapshot.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:app/features/flight/domain/value_objects/airport_code.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:app/features/flight/domain/value_objects/gate.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/boarding_pass/application/use_cases/use_boarding_pass_use_case.dart';
import 'package:app/features/boarding_pass/domain/services/boarding_pass_service.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/domain/value_objects/seat_number.dart';
import 'package:timezone/timezone.dart';

import '../../../../../helpers/test_timezone_helper.dart';
import 'use_boarding_pass_use_case_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<BoardingPassService>(),
  MockSpec<BoardingPass>(),
  MockSpec<FlightScheduleSnapshot>(),
  MockSpec<FlightNumber>(),
  MockSpec<SeatNumber>(),
  MockSpec<Gate>(),
])
void main() {
  group('UseBoardingPassUseCase', () {
    late UseBoardingPassUseCase useCase;
    late MockBoardingPassService mockBoardingPassService;
    late MockBoardingPass mockBoardingPass;
    late MockFlightScheduleSnapshot mockScheduleSnapshot;
    late MockFlightNumber mockFlightNumber;
    late MockSeatNumber mockSeatNumber;
    late MockGate mockGate;
    setUpAll(() {
      TestTimezoneHelper.setupForTesting();
    });
    setUp(() {
      mockBoardingPassService = MockBoardingPassService();
      mockBoardingPass = MockBoardingPass();
      mockScheduleSnapshot = MockFlightScheduleSnapshot();
      mockFlightNumber = MockFlightNumber();
      mockSeatNumber = MockSeatNumber();
      mockGate = MockGate();

      useCase = UseBoardingPassUseCase(mockBoardingPassService);

      // Setup default mock behaviors
      final passId = PassId('BP12345678');
      final memberNumber = MemberNumber.create('MB100001');
      final flightNumber = FlightNumber.create('BR857');
      final seatNumber = SeatNumber.create('12A');
      final now = TZDateTime.now(local);
      final boardingTime = now.subtract(const Duration(minutes: 30));
      final departureTime = now.add(const Duration(minutes: 30));
      final snapshotTime = now.subtract(const Duration(hours: 1));
      final qrCode = QRCodeData.generate(
        passId: passId,
        flightNumber: flightNumber,
        seatNumber: seatNumber,
        memberNumber: memberNumber,
        departureTime: departureTime,
      );

      when(mockBoardingPass.passId).thenReturn(passId);
      when(mockBoardingPass.memberNumber).thenReturn(memberNumber);
      when(mockBoardingPass.flightNumber).thenReturn(flightNumber);
      when(mockBoardingPass.seatNumber).thenReturn(seatNumber);

      when(mockBoardingPass.qrCode).thenReturn(qrCode);
      when(mockBoardingPass.issueTime).thenReturn(now);
      when(mockBoardingPass.scheduleSnapshot).thenReturn(mockScheduleSnapshot);
      when(mockBoardingPass.flightNumber).thenReturn(mockFlightNumber);
      when(mockBoardingPass.seatNumber).thenReturn(mockSeatNumber);
      when(mockScheduleSnapshot.gate).thenReturn(mockGate);
      when(mockFlightNumber.value).thenReturn('BR857');
      when(mockSeatNumber.value).thenReturn('12A');
      when(mockGate.value).thenReturn('A12');

      when(mockScheduleSnapshot.departureTime).thenReturn(departureTime);
      when(mockScheduleSnapshot.boardingTime).thenReturn(boardingTime);
      when(mockScheduleSnapshot.departure).thenReturn(AirportCode('TPE'));
      when(mockScheduleSnapshot.arrival).thenReturn(AirportCode('NRT'));
      when(mockScheduleSnapshot.snapshotTime).thenReturn(snapshotTime);
      when(mockScheduleSnapshot.gate).thenReturn(mockGate);
      when(mockBoardingPass.scheduleSnapshot).thenReturn(mockScheduleSnapshot);
    });

    test('should use boarding pass successfully', () async {
      // Arrange
      const passId = 'BP12345678';

      // Add missing mock stubs for FlightScheduleSnapshot
      when(
        mockScheduleSnapshot.departureTime,
      ).thenReturn(TZDateTime.now(local).add(const Duration(minutes: 30)));
      when(
        mockScheduleSnapshot.boardingTime,
      ).thenReturn(TZDateTime.now(local).subtract(const Duration(minutes: 30)));
      when(mockScheduleSnapshot.departure).thenReturn(AirportCode('TPE'));
      when(mockScheduleSnapshot.arrival).thenReturn(AirportCode('NRT'));
      when(
        mockScheduleSnapshot.snapshotTime,
      ).thenReturn(TZDateTime.now(local).subtract(const Duration(hours: 1)));

      when(
        mockBoardingPassService.useBoardingPass(any),
      ).thenAnswer((_) async => Right(mockBoardingPass));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isTrue);
        expect(response.boardingPass, isNotNull);
        expect(response.errorMessage, isNull);
        expect(response.metadata?['usedAt'], isNotNull);
        expect(response.metadata?['gate'], equals('A12'));
        expect(response.metadata?['flightNumber'], equals('BR857'));
        expect(response.metadata?['seatNumber'], equals('12A'));
      });
    });

    test('should handle domain exception', () async {
      // Arrange
      const passId = 'BP12345678';

      when(
        mockBoardingPassService.useBoardingPass(any),
      ).thenThrow(DomainException('Boarding window closed'));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Boarding window closed'));
        expect(response.errorCode, equals('DOMAIN_VALIDATION_ERROR'));
      });
    });

    test('should handle unexpected exception', () async {
      // Arrange
      const passId = 'BP12345678';

      when(
        mockBoardingPassService.useBoardingPass(any),
      ).thenThrow(Exception('Unexpected error'));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (response) => fail('Should not return success'),
      );
    });

    test('should include all metadata in successful response', () async {
      // Arrange
      const passId = 'BP12345678';

      when(
        mockBoardingPassService.useBoardingPass(any),
      ).thenAnswer((_) async => Right(mockBoardingPass));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isTrue);
        expect(response.metadata?['usedAt'], isNotNull);
        expect(response.metadata?['gate'], equals('A12'));
        expect(response.metadata?['flightNumber'], equals('BR857'));
        expect(response.metadata?['seatNumber'], equals('12A'));
      });
    });

    test('should return error for empty pass ID', () async {
      // Act
      final result = await useCase('');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Pass ID cannot be empty'));
        expect(response.errorCode, equals('VALIDATION_ERROR'));
        expect(response.boardingPass, isNull);
      });

      // Verify service was not called
      verifyNever(mockBoardingPassService.useBoardingPass(any));
    });

    test('should return error for whitespace-only pass ID', () async {
      // Act
      final result = await useCase('   ');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Pass ID cannot be empty'));
        expect(response.errorCode, equals('VALIDATION_ERROR'));
      });

      verifyNever(mockBoardingPassService.useBoardingPass(any));
    });

    test('should handle boarding pass not found error', () async {
      // Arrange
      const passId = 'BP12345678';

      when(mockBoardingPassService.useBoardingPass(any)).thenAnswer(
        (_) async => Left(NotFoundFailure('Boarding pass not found')),
      );

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Boarding pass not found'));
        expect(response.errorCode, equals('PASS_NOT_FOUND'));
        expect(response.boardingPass, isNull);
      });
    });

    test('should handle validation failure from service', () async {
      // Arrange
      const passId = 'BP12345678';

      when(
        mockBoardingPassService.useBoardingPass(any),
      ).thenAnswer((_) async => Left(ValidationFailure('Pass not activated')));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Pass not activated'));
        expect(response.errorCode, equals('VALIDATION_ERROR'));
      });
    });

    test('should handle database failure from service', () async {
      // Arrange
      const passId = 'BP12345678';

      when(mockBoardingPassService.useBoardingPass(any)).thenAnswer(
        (_) async => Left(DatabaseFailure('Database connection error')),
      );

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Database connection error'));
        expect(response.errorCode, equals('DATABASE_ERROR'));
      });
    });

    test('should handle pass already used error', () async {
      // Arrange
      const passId = 'BP12345678';

      when(
        mockBoardingPassService.useBoardingPass(any),
      ).thenAnswer((_) async => Left(ValidationFailure('Pass already used')));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Pass already used'));
        expect(response.errorCode, equals('VALIDATION_ERROR'));
      });
    });

    test('should use boarding pass successfully', () async {
      // Arrange
      const passId = 'BP12345678';

      when(
        mockBoardingPassService.useBoardingPass(any),
      ).thenAnswer((_) async => Right(mockBoardingPass));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isTrue);
        expect(response.boardingPass, isNotNull);
        expect(response.errorMessage, isNull);
        expect(response.errorCode, isNull);
        expect(response.metadata?['usedAt'], isNotNull);
        expect(response.metadata?['gate'], equals('A12'));
        expect(response.metadata?['flightNumber'], equals('BR857'));
        expect(response.metadata?['seatNumber'], equals('12A'));
      });
    });

    test('should handle network failure from service', () async {
      // Arrange
      const passId = 'BP12345678';

      when(
        mockBoardingPassService.useBoardingPass(any),
      ).thenAnswer((_) async => Left(NetworkFailure('Network timeout')));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.boardingPass, isNull);
        expect(response.errorMessage, equals('Network timeout'));
        expect(response.errorCode, equals('NETWORK_ERROR'));
        expect(response.metadata, isNull);
      });
    });
  });
}
