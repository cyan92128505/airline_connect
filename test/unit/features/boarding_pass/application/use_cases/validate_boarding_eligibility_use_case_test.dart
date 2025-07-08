import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';
import 'package:app/features/boarding_pass/domain/value_objects/flight_schedule_snapshot.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:app/features/boarding_pass/domain/value_objects/seat_number.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:app/features/flight/domain/value_objects/gate.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/boarding_pass/application/use_cases/validate_boarding_eligibility_use_case.dart';
import 'package:app/features/boarding_pass/domain/services/boarding_pass_service.dart';
import 'package:app/features/boarding_pass/domain/repositories/boarding_pass_repository.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'validate_boarding_eligibility_use_case_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<BoardingPassService>(),
  MockSpec<BoardingPassRepository>(),
  MockSpec<BoardingPass>(),
  MockSpec<QRCodeData>(),
  MockSpec<FlightScheduleSnapshot>(),
])
void main() {
  group('ValidateBoardingEligibilityUseCase', () {
    late ValidateBoardingEligibilityUseCase useCase;
    late MockBoardingPassService mockBoardingPassService;
    late MockBoardingPassRepository mockBoardingPassRepository;
    late MockBoardingPass mockBoardingPass;
    late MockQRCodeData mockQRCode;
    late MockFlightScheduleSnapshot mockScheduleSnapshot;

    void setupMockBoardingPass(
      MockBoardingPass mockPass,
      bool isActive,
      bool isInBoardingWindow,
      bool isQRCodeValid,
    ) {
      final passId = PassId('BP12345678');
      final memberNumber = MemberNumber.create('MB100001');
      final flightNumber = FlightNumber.create('BR857');
      final seatNumber = SeatNumber.create('12A');
      final now = TZDateTime.now(local);
      final departureTime = now.add(const Duration(hours: 1));

      // Setup basic boarding pass properties
      when(mockPass.passId).thenReturn(passId);
      when(mockPass.memberNumber).thenReturn(memberNumber);
      when(mockPass.flightNumber).thenReturn(flightNumber);
      when(mockPass.seatNumber).thenReturn(seatNumber);
      when(
        mockPass.status,
      ).thenReturn(isActive ? PassStatus.activated : PassStatus.expired);
      when(mockPass.isActive).thenReturn(isActive);
      when(mockPass.timeUntilDeparture).thenReturn(Duration(minutes: 60));
      when(
        mockPass.issueTime,
      ).thenReturn(now.subtract(const Duration(hours: 3)));

      // Setup QR code
      when(mockPass.qrCode).thenReturn(mockQRCode);
      when(mockQRCode.isValid).thenReturn(isQRCodeValid);

      // Setup schedule snapshot - THIS IS THE KEY FIX
      when(mockPass.scheduleSnapshot).thenReturn(mockScheduleSnapshot);
      when(
        mockScheduleSnapshot.isInBoardingWindow,
      ).thenReturn(isInBoardingWindow);
      when(mockScheduleSnapshot.departureTime).thenReturn(departureTime);
      when(mockScheduleSnapshot.gate).thenReturn(Gate('A12'));
    }

    setUpAll(() {
      tz.initializeTimeZones();
    });

    setUp(() {
      mockBoardingPassService = MockBoardingPassService();
      mockBoardingPassRepository = MockBoardingPassRepository();
      mockBoardingPass = MockBoardingPass();
      mockQRCode = MockQRCodeData();
      mockScheduleSnapshot = MockFlightScheduleSnapshot();

      useCase = ValidateBoardingEligibilityUseCase(
        mockBoardingPassService,
        mockBoardingPassRepository,
      );

      // Setup default mock boarding pass
      setupMockBoardingPass(mockBoardingPass, true, true, true);
    });

    test(
      'should validate boarding eligibility successfully when eligible',
      () async {
        // Arrange
        const passId = 'BP12345678';

        when(
          mockBoardingPassService.validateBoardingEligibility(any),
        ).thenAnswer((_) async => Right(true));
        when(
          mockBoardingPassRepository.findByPassId(any),
        ).thenAnswer((_) async => Right(mockBoardingPass));

        // Act
        final result = await useCase(passId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Should not return failure'), (response) {
          expect(response.isEligible, isTrue);
          expect(response.passId, equals(passId));
          expect(response.reason, isNull);
          expect(response.timeUntilDepartureMinutes, equals(60));
          expect(response.isInBoardingWindow, isTrue);
          expect(response.additionalInfo?['status'], equals('activated'));
          expect(response.additionalInfo?['qrCodeValid'], isTrue);
          expect(response.additionalInfo?['departureTime'], isNotNull);
          expect(response.additionalInfo?['gate'], equals('A12'));
        });
      },
    );

    test('should return ineligible when boarding pass not active', () async {
      // Arrange
      const passId = 'BP12345678';
      setupMockBoardingPass(mockBoardingPass, false, true, true);

      when(
        mockBoardingPassService.validateBoardingEligibility(any),
      ).thenAnswer((_) async => Right(false));
      when(
        mockBoardingPassRepository.findByPassId(any),
      ).thenAnswer((_) async => Right(mockBoardingPass));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isEligible, isFalse);
        expect(response.passId, equals(passId));
        expect(response.reason, contains('Boarding pass is not active'));
        expect(response.currentStatus, equals(PassStatus.expired));
        expect(response.isQRCodeValid, isTrue);
      });
    });

    test('should return ineligible when not in boarding window', () async {
      // Arrange
      const passId = 'BP12345678';
      setupMockBoardingPass(mockBoardingPass, true, false, true);

      when(
        mockBoardingPassService.validateBoardingEligibility(any),
      ).thenAnswer((_) async => Right(false));
      when(
        mockBoardingPassRepository.findByPassId(any),
      ).thenAnswer((_) async => Right(mockBoardingPass));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isEligible, isFalse);
        expect(response.passId, equals(passId));
        expect(response.reason, equals('Not within boarding window'));
        expect(response.additionalInfo?['isInBoardingWindow'], isFalse);
      });
    });

    test('should return ineligible when QR code is invalid', () async {
      // Arrange
      const passId = 'BP12345678';
      setupMockBoardingPass(mockBoardingPass, true, true, false);

      when(
        mockBoardingPassService.validateBoardingEligibility(any),
      ).thenAnswer((_) async => Right(false));
      when(
        mockBoardingPassRepository.findByPassId(any),
      ).thenAnswer((_) async => Right(mockBoardingPass));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isEligible, isFalse);
        expect(response.passId, equals(passId));
        expect(response.reason, equals('QR code is invalid or expired'));
        expect(response.isQRCodeValid, isFalse);
      });
    });

    test('should return error for empty pass ID', () async {
      // Act
      final result = await useCase('');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isEligible, isFalse);
        expect(response.passId, equals(''));
        expect(response.reason, equals('Pass ID cannot be empty'));
      });

      verifyNever(mockBoardingPassService.validateBoardingEligibility(any));
      verifyNever(mockBoardingPassRepository.findByPassId(any));
    });

    test('should return error for whitespace-only pass ID', () async {
      // Act
      final result = await useCase('   ');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isEligible, isFalse);
        expect(response.passId, equals('   '));
        expect(response.reason, equals('Pass ID cannot be empty'));
      });
    });

    test('should handle boarding pass not found', () async {
      // Arrange
      const passId = 'BP99999999';

      when(
        mockBoardingPassService.validateBoardingEligibility(any),
      ).thenAnswer((_) async => Right(true));
      when(
        mockBoardingPassRepository.findByPassId(any),
      ).thenAnswer((_) async => Right(null));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isEligible, isFalse);
        expect(response.passId, equals(passId));
        expect(response.reason, equals('Boarding pass not found'));
      });
    });

    test('should handle service failure', () async {
      // Arrange
      const passId = 'BP12345678';

      when(mockBoardingPassService.validateBoardingEligibility(any)).thenAnswer(
        (_) async => Left(DatabaseFailure('Database connection error')),
      );

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<DatabaseFailure>());
        expect(failure.message, equals('Database connection error'));
      }, (response) => fail('Should not return success'));
    });

    test(
      'should handle repository failure when retrieving boarding pass details',
      () async {
        // Arrange
        const passId = 'BP12345678';

        when(
          mockBoardingPassService.validateBoardingEligibility(any),
        ).thenAnswer((_) async => Right(true));
        when(
          mockBoardingPassRepository.findByPassId(any),
        ).thenAnswer((_) async => Left(NetworkFailure('Network timeout')));

        // Act
        final result = await useCase(passId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Should not return failure'), (response) {
          expect(response.isEligible, isFalse);
          expect(response.passId, equals(passId));
          expect(
            response.reason,
            contains('Unable to retrieve boarding pass details'),
          );
          expect(response.reason, contains('Network timeout'));
        });
      },
    );

    test('should handle domain exception', () async {
      // Arrange
      const passId = 'BP12345678';

      when(
        mockBoardingPassService.validateBoardingEligibility(any),
      ).thenThrow(DomainException('Invalid pass format'));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isEligible, isFalse);
        expect(response.passId, equals(passId));
        expect(response.reason, equals('Invalid pass format'));
      });
    });

    test('should handle unexpected exception', () async {
      // Arrange
      const passId = 'BP12345678';

      when(
        mockBoardingPassService.validateBoardingEligibility(any),
      ).thenThrow(Exception('Unexpected error'));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<UnknownFailure>());
        expect(
          failure.message,
          contains('Failed to validate boarding eligibility'),
        );
      }, (response) => fail('Should not return success'));
    });

    test(
      'should include complete additional info for eligible boarding pass',
      () async {
        // Arrange
        const passId = 'BP12345678';

        when(
          mockBoardingPassService.validateBoardingEligibility(any),
        ).thenAnswer((_) async => Right(true));
        when(
          mockBoardingPassRepository.findByPassId(any),
        ).thenAnswer((_) async => Right(mockBoardingPass));

        // Act
        final result = await useCase(passId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Should not return failure'), (response) {
          expect(response.isEligible, isTrue);
          expect(response.additionalInfo, isNotNull);
          expect(response.additionalInfo?['status'], isNotNull);
          expect(response.additionalInfo?['qrCodeValid'], isNotNull);
          expect(response.additionalInfo?['departureTime'], isNotNull);
          expect(response.additionalInfo?['gate'], isNotNull);
        });
      },
    );

    test(
      'should include complete additional info for ineligible boarding pass',
      () async {
        // Arrange
        const passId = 'BP12345678';
        setupMockBoardingPass(mockBoardingPass, false, false, false);

        when(
          mockBoardingPassService.validateBoardingEligibility(any),
        ).thenAnswer((_) async => Right(false));
        when(
          mockBoardingPassRepository.findByPassId(any),
        ).thenAnswer((_) async => Right(mockBoardingPass));

        // Act
        final result = await useCase(passId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Should not return failure'), (response) {
          expect(response.isEligible, isFalse);
          expect(response.additionalInfo, isNotNull);
          expect(response.additionalInfo?['timeUntilDeparture'], isNotNull);
          expect(response.additionalInfo?['isInBoardingWindow'], isNotNull);
          expect(response.additionalInfo?['departureTime'], isNotNull);
          expect(response.additionalInfo?['gate'], isNotNull);
        });
      },
    );

    test('should handle unknown eligibility issue', () async {
      // Arrange
      const passId = 'BP12345678';
      // Setup a boarding pass that appears valid but service says ineligible
      setupMockBoardingPass(mockBoardingPass, true, true, true);

      when(
        mockBoardingPassService.validateBoardingEligibility(any),
      ).thenAnswer((_) async => Right(false));
      when(
        mockBoardingPassRepository.findByPassId(any),
      ).thenAnswer((_) async => Right(mockBoardingPass));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.isEligible, isFalse);
        expect(response.passId, equals(passId));
        expect(response.reason, equals('Unknown eligibility issue'));
      });
    });

    test('should validate pass ID format correctly', () async {
      // Arrange
      const validPassId = 'BP12345678';

      when(
        mockBoardingPassService.validateBoardingEligibility(any),
      ).thenAnswer((_) async => Right(true));
      when(
        mockBoardingPassRepository.findByPassId(any),
      ).thenAnswer((_) async => Right(mockBoardingPass));

      // Act
      final result = await useCase(validPassId);

      // Assert
      expect(result.isRight(), isTrue);

      // Verify that PassId.fromString was called with correct value
      verify(
        mockBoardingPassService.validateBoardingEligibility(
          argThat(
            predicate<PassId>((passIdVO) => passIdVO.value == validPassId),
          ),
        ),
      ).called(1);

      verify(
        mockBoardingPassRepository.findByPassId(
          argThat(
            predicate<PassId>((passIdVO) => passIdVO.value == validPassId),
          ),
        ),
      ).called(1);
    });
  });
}
