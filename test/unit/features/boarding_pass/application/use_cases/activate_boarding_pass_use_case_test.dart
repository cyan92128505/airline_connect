import 'package:app/features/boarding_pass/domain/value_objects/flight_schedule_snapshot.dart';
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
import 'package:app/features/boarding_pass/application/use_cases/activate_boarding_pass_use_case.dart';
import 'package:app/features/boarding_pass/domain/services/boarding_pass_service.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'activate_boarding_pass_use_case_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<BoardingPassService>(),
  MockSpec<BoardingPass>(),
  MockSpec<FlightScheduleSnapshot>(),
  MockSpec<QRCodeData>(),
])
void main() {
  group('ActivateBoardingPassUseCase', () {
    late ActivateBoardingPassUseCase useCase;
    late MockBoardingPassService mockBoardingPassService;
    late MockBoardingPass mockBoardingPass;
    late MockFlightScheduleSnapshot mockScheduleSnapshot;
    late MockQRCodeData mockQRCode;

    setUpAll(() {
      tz.initializeTimeZones();
    });

    setUp(() {
      mockBoardingPassService = MockBoardingPassService();
      mockBoardingPass = MockBoardingPass();
      mockScheduleSnapshot = MockFlightScheduleSnapshot();
      mockQRCode = MockQRCodeData();

      useCase = ActivateBoardingPassUseCase(mockBoardingPassService);

      // Setup default mock behaviors
      when(mockBoardingPass.scheduleSnapshot).thenReturn(mockScheduleSnapshot);
      when(mockBoardingPass.qrCode).thenReturn(mockQRCode);
      when(
        mockBoardingPass.timeUntilDeparture,
      ).thenReturn(Duration(minutes: 90));
      when(mockScheduleSnapshot.isInBoardingWindow).thenReturn(true);
    });

    test('should activate boarding pass successfully', () async {
      // Arrange

      final passId = PassId.generate();
      final memberNumber = MemberNumber.create('MB100001');
      final flightNumber = FlightNumber.create('BR857');
      final seatNumber = SeatNumber.create('12A');
      final now = TZDateTime.now(local);
      final boardingTime = now.subtract(const Duration(minutes: 30));
      final departureTime = now.add(const Duration(minutes: 30));
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
      when(mockBoardingPass.scheduleSnapshot).thenReturn(
        FlightScheduleSnapshot.create(
          departureTime: departureTime,
          boardingTime: boardingTime,
          departureAirport: 'TPE',
          arrivalAirport: 'NRT',
          gateNumber: 'A12',
          snapshotTime: now.subtract(const Duration(hours: 1)),
        ),
      );
      when(mockBoardingPass.qrCode).thenReturn(qrCode);
      when(mockBoardingPass.issueTime).thenReturn(now);

      when(
        mockBoardingPassService.activateBoardingPass(any),
      ).thenAnswer((_) async => Right(mockBoardingPass));

      // Act
      final result = await useCase(passId.value);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isTrue);
        expect(response.boardingPass, isNotNull);
        expect(response.errorMessage, isNull);
        expect(response.metadata?['activatedAt'], isNotNull);
        expect(response.metadata?['timeUntilDeparture'], equals(90));
        expect(response.metadata?['isInBoardingWindow'], isTrue);
      });

      // Verify the service was called with correct PassId
      verify(
        mockBoardingPassService.activateBoardingPass(
          argThat(
            predicate<PassId>((passIdVO) => passIdVO.value == passId.value),
          ),
        ),
      ).called(1);
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
      verifyNever(mockBoardingPassService.activateBoardingPass(any));
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

      verifyNever(mockBoardingPassService.activateBoardingPass(any));
    });

    test('should handle boarding pass not found error', () async {
      // Arrange
      const passId = 'BP12345678';

      when(mockBoardingPassService.activateBoardingPass(any)).thenAnswer(
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

      when(mockBoardingPassService.activateBoardingPass(any)).thenAnswer(
        (_) async => Left(ValidationFailure('Pass already activated')),
      );

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Pass already activated'));
        expect(response.errorCode, equals('VALIDATION_ERROR'));
      });
    });

    test('should handle database failure from service', () async {
      // Arrange
      const passId = 'BP12345678';

      when(mockBoardingPassService.activateBoardingPass(any)).thenAnswer(
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

    test('should handle network failure from service', () async {
      // Arrange
      const passId = 'BP12345678';

      when(
        mockBoardingPassService.activateBoardingPass(any),
      ).thenAnswer((_) async => Left(NetworkFailure('Network timeout')));

      // Act
      final result = await useCase(passId);

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
      const passId = 'BP12345678';

      when(
        mockBoardingPassService.activateBoardingPass(any),
      ).thenThrow(DomainException('Invalid pass status for activation'));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(
          response.errorMessage,
          equals('Invalid pass status for activation'),
        );
        expect(response.errorCode, equals('DOMAIN_VALIDATION_ERROR'));
      });
    });

    test('should handle unexpected exception', () async {
      // Arrange
      const passId = 'BP12345678';

      when(
        mockBoardingPassService.activateBoardingPass(any),
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

    test('should include metadata in successful activation', () async {
      // Arrange
      const passId = PassId('BP12345678');
      final timeUntilDeparture = Duration(minutes: 45);

      when(mockBoardingPass.timeUntilDeparture).thenReturn(timeUntilDeparture);
      when(mockScheduleSnapshot.isInBoardingWindow).thenReturn(true);

      final memberNumber = MemberNumber.create('MB100001');
      final flightNumber = FlightNumber.create('BR857');
      final seatNumber = SeatNumber.create('12A');
      final now = TZDateTime.now(local);
      final boardingTime = now.subtract(const Duration(minutes: 30));
      final departureTime = now.add(const Duration(minutes: 30));
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
      when(mockBoardingPass.scheduleSnapshot).thenReturn(
        FlightScheduleSnapshot.create(
          departureTime: departureTime,
          boardingTime: boardingTime,
          departureAirport: 'TPE',
          arrivalAirport: 'NRT',
          gateNumber: 'A12',
          snapshotTime: now.subtract(const Duration(hours: 1)),
        ),
      );
      when(mockBoardingPass.qrCode).thenReturn(qrCode);
      when(mockBoardingPass.issueTime).thenReturn(now);

      when(
        mockBoardingPassService.activateBoardingPass(any),
      ).thenAnswer((_) async => Right(mockBoardingPass));

      // Act
      final result = await useCase(passId.value);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isTrue);
        expect(response.metadata?['timeUntilDeparture'], equals(45));
        expect(response.metadata?['isInBoardingWindow'], isTrue);
        expect(response.metadata?['activatedAt'], isNotNull);
      });
    });
  });
}
