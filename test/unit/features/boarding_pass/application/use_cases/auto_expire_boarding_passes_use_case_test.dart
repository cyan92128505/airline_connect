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
import 'package:app/features/boarding_pass/application/use_cases/auto_expire_boarding_passes_use_case.dart';
import 'package:app/features/boarding_pass/domain/services/boarding_pass_service.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:timezone/timezone.dart';

import '../../../../../helpers/test_timezone_helper.dart';
import 'auto_expire_boarding_passes_use_case_test.mocks.dart';

@GenerateNiceMocks([MockSpec<BoardingPassService>(), MockSpec<BoardingPass>()])
void main() {
  group('AutoExpireBoardingPassesUseCase', () {
    late AutoExpireBoardingPassesUseCase useCase;
    late MockBoardingPassService mockBoardingPassService;
    late List<MockBoardingPass> mockExpiredPasses;

    void setupMockBoardingPass(
      MockBoardingPass mockPass,
      String passIdStr,
      String memberNumberStr,
      String flightNumberStr,
      String seatNumberStr,
    ) {
      final passId = PassId(passIdStr);
      final memberNumber = MemberNumber.create(memberNumberStr);
      final flightNumber = FlightNumber.create(flightNumberStr);
      final seatNumber = SeatNumber.create(seatNumberStr);
      final now = TZDateTime.now(local);
      final pastDepartureTime = now.subtract(const Duration(hours: 2));
      final pastBoardingTime = now.subtract(const Duration(hours: 3));
      final qrCode = QRCodeData.generate(
        passId: passId,
        flightNumber: flightNumber,
        seatNumber: seatNumber,
        memberNumber: memberNumber,
        departureTime: pastDepartureTime,
      );

      when(mockPass.passId).thenReturn(passId);
      when(mockPass.memberNumber).thenReturn(memberNumber);
      when(mockPass.flightNumber).thenReturn(flightNumber);
      when(mockPass.seatNumber).thenReturn(seatNumber);
      when(mockPass.scheduleSnapshot).thenReturn(
        FlightScheduleSnapshot.create(
          departureTime: pastDepartureTime,
          boardingTime: pastBoardingTime,
          departureAirport: 'TPE',
          arrivalAirport: 'NRT',
          gateNumber: 'A12',
          snapshotTime: now.subtract(const Duration(hours: 4)),
        ),
      );
      when(mockPass.qrCode).thenReturn(qrCode);
      when(
        mockPass.issueTime,
      ).thenReturn(now.subtract(const Duration(hours: 5)));
    }

    setUpAll(() {
      TestTimezoneHelper.setupForTesting();
    });

    setUp(() {
      mockBoardingPassService = MockBoardingPassService();
      useCase = AutoExpireBoardingPassesUseCase(mockBoardingPassService);

      // Create mock expired boarding passes
      mockExpiredPasses = [
        MockBoardingPass(),
        MockBoardingPass(),
        MockBoardingPass(),
      ];

      // Setup mock boarding passes with realistic data
      setupMockBoardingPass(
        mockExpiredPasses[0],
        'BP12345001',
        'MB100001',
        'BR101',
        '1A',
      );
      setupMockBoardingPass(
        mockExpiredPasses[1],
        'BP12345002',
        'MB100002',
        'BR102',
        '2B',
      );
      setupMockBoardingPass(
        mockExpiredPasses[2],
        'BP12345003',
        'MB100003',
        'BR103',
        '3C',
      );
    });

    test('should auto-expire boarding passes successfully', () async {
      // Arrange
      when(
        mockBoardingPassService.autoExpireBoardingPasses(),
      ).thenAnswer((_) async => Right(mockExpiredPasses));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTOs) {
        expect(passDTOs, hasLength(3));
        expect(passDTOs[0].passId, equals('BP12345001'));
        expect(passDTOs[0].memberNumber, equals('MB100001'));
        expect(passDTOs[0].flightNumber, equals('BR101'));
        expect(passDTOs[0].seatNumber, equals('1A'));

        expect(passDTOs[1].passId, equals('BP12345002'));
        expect(passDTOs[1].memberNumber, equals('MB100002'));
        expect(passDTOs[1].flightNumber, equals('BR102'));
        expect(passDTOs[1].seatNumber, equals('2B'));

        expect(passDTOs[2].passId, equals('BP12345003'));
        expect(passDTOs[2].memberNumber, equals('MB100003'));
        expect(passDTOs[2].flightNumber, equals('BR103'));
        expect(passDTOs[2].seatNumber, equals('3C'));
      });

      verify(mockBoardingPassService.autoExpireBoardingPasses()).called(1);
    });

    test('should return empty list when no passes to expire', () async {
      // Arrange
      when(
        mockBoardingPassService.autoExpireBoardingPasses(),
      ).thenAnswer((_) async => Right(<BoardingPass>[]));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTOs) {
        expect(passDTOs, isEmpty);
      });

      verify(mockBoardingPassService.autoExpireBoardingPasses()).called(1);
    });

    test('should handle database failure from service', () async {
      // Arrange
      when(mockBoardingPassService.autoExpireBoardingPasses()).thenAnswer(
        (_) async => Left(DatabaseFailure('Database connection lost')),
      );

      // Act
      final result = await useCase();

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<DatabaseFailure>());
        expect(failure.message, equals('Database connection lost'));
      }, (passDTOs) => fail('Should not return success'));

      verify(mockBoardingPassService.autoExpireBoardingPasses()).called(1);
    });

    test('should handle network failure from service', () async {
      // Arrange
      when(
        mockBoardingPassService.autoExpireBoardingPasses(),
      ).thenAnswer((_) async => Left(NetworkFailure('Network timeout')));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, equals('Network timeout'));
      }, (passDTOs) => fail('Should not return success'));
    });

    test('should handle validation failure from service', () async {
      // Arrange
      when(mockBoardingPassService.autoExpireBoardingPasses()).thenAnswer(
        (_) async => Left(ValidationFailure('Invalid expiration criteria')),
      );

      // Act
      final result = await useCase();

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, equals('Invalid expiration criteria'));
      }, (passDTOs) => fail('Should not return success'));
    });

    test('should handle unexpected exception', () async {
      // Arrange
      when(
        mockBoardingPassService.autoExpireBoardingPasses(),
      ).thenThrow(Exception('Unexpected system error'));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<UnknownFailure>());
        expect(
          failure.message,
          contains('Failed to auto-expire boarding passes'),
        );
        expect(failure.message, contains('Unexpected system error'));
      }, (passDTOs) => fail('Should not return success'));
    });

    test('should handle single expired pass correctly', () async {
      // Arrange
      final singleMockPass = MockBoardingPass();
      setupMockBoardingPass(
        singleMockPass,
        'BP99999999',
        'MB999999',
        'BR999',
        '99A',
      );

      when(
        mockBoardingPassService.autoExpireBoardingPasses(),
      ).thenAnswer((_) async => Right([singleMockPass]));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTOs) {
        expect(passDTOs, hasLength(1));
        expect(passDTOs.first.passId, equals('BP99999999'));
        expect(passDTOs.first.memberNumber, equals('MB999999'));
        expect(passDTOs.first.flightNumber, equals('BR999'));
        expect(passDTOs.first.seatNumber, equals('99A'));
      });
    });

    test('should convert domain entities to DTOs correctly', () async {
      // Arrange
      when(
        mockBoardingPassService.autoExpireBoardingPasses(),
      ).thenAnswer((_) async => Right(mockExpiredPasses));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTOs) {
        // Verify all passes are converted to DTOs
        expect(passDTOs, hasLength(mockExpiredPasses.length));

        // Verify DTO properties are correctly mapped
        for (int i = 0; i < passDTOs.length; i++) {
          expect(passDTOs[i].passId, isNotEmpty);
          expect(passDTOs[i].memberNumber, isNotEmpty);
          expect(passDTOs[i].flightNumber, isNotEmpty);
          expect(passDTOs[i].seatNumber, isNotEmpty);
          expect(passDTOs[i].issueTime, isNotNull);
        }
      });
    });

    test('should maintain order of expired passes in result', () async {
      // Arrange
      when(
        mockBoardingPassService.autoExpireBoardingPasses(),
      ).thenAnswer((_) async => Right(mockExpiredPasses));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTOs) {
        // Verify order is maintained
        expect(passDTOs[0].passId, equals('BP12345001'));
        expect(passDTOs[1].passId, equals('BP12345002'));
        expect(passDTOs[2].passId, equals('BP12345003'));
      });
    });
  });
}
