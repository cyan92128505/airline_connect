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
import 'package:app/features/boarding_pass/application/use_cases/get_boarding_pass_details_use_case.dart';
import 'package:app/features/boarding_pass/domain/repositories/boarding_pass_repository.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:timezone/timezone.dart';

import '../../../../../helpers/test_timezone_helper.dart';
import 'get_boarding_pass_details_use_case_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<BoardingPassRepository>(),
  MockSpec<BoardingPass>(),
])
void main() {
  group('GetBoardingPassDetailsUseCase', () {
    late GetBoardingPassDetailsUseCase useCase;
    late MockBoardingPassRepository mockRepository;
    late MockBoardingPass mockBoardingPass;

    void setupMockBoardingPass(MockBoardingPass mockPass) {
      final passId = PassId('BP12345678');
      final memberNumber = MemberNumber.create('MB100001');
      final flightNumber = FlightNumber.create('BR857');
      final seatNumber = SeatNumber.create('12A');
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
      mockRepository = MockBoardingPassRepository();
      mockBoardingPass = MockBoardingPass();
      useCase = GetBoardingPassDetailsUseCase(mockRepository);

      // Setup default mock boarding pass
      setupMockBoardingPass(mockBoardingPass);
    });

    test('should get boarding pass details successfully', () async {
      // Arrange
      const passId = 'BP12345678';

      when(
        mockRepository.findByPassId(any),
      ).thenAnswer((_) async => Right(mockBoardingPass));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTO) {
        expect(passDTO.passId, equals('BP12345678'));
        expect(passDTO.memberNumber, equals('MB100001'));
        expect(passDTO.flightNumber, equals('BR857'));
        expect(passDTO.seatNumber, equals('12A'));
        expect(passDTO.issueTime, isNotNull);
      });

      verify(mockRepository.findByPassId(any)).called(1);
    });

    test('should return error for empty pass ID', () async {
      // Act
      final result = await useCase('');

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, equals('Pass ID cannot be empty'));
      }, (passDTO) => fail('Should not return success'));

      verifyNever(mockRepository.findByPassId(any));
    });

    test('should return error for whitespace-only pass ID', () async {
      // Act
      final result = await useCase('   ');

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, equals('Pass ID cannot be empty'));
      }, (passDTO) => fail('Should not return success'));

      verifyNever(mockRepository.findByPassId(any));
    });

    test(
      'should return not found error when boarding pass does not exist',
      () async {
        // Arrange
        const passId = 'BP99999999';

        when(
          mockRepository.findByPassId(any),
        ).thenAnswer((_) async => Right(null));

        // Act
        final result = await useCase(passId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<NotFoundFailure>());
          expect(failure.message, equals('Boarding pass not found: $passId'));
        }, (passDTO) => fail('Should not return success'));

        verify(mockRepository.findByPassId(any)).called(1);
      },
    );

    test('should handle database failure from repository', () async {
      // Arrange
      const passId = 'BP12345678';

      when(mockRepository.findByPassId(any)).thenAnswer(
        (_) async => Left(DatabaseFailure('Database connection error')),
      );

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<DatabaseFailure>());
        expect(failure.message, equals('Database connection error'));
      }, (passDTO) => fail('Should not return success'));
    });

    test('should handle network failure from repository', () async {
      // Arrange
      const passId = 'BP12345678';

      when(
        mockRepository.findByPassId(any),
      ).thenAnswer((_) async => Left(NetworkFailure('Network timeout')));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, equals('Network timeout'));
      }, (passDTO) => fail('Should not return success'));
    });

    test('should handle domain exception during pass ID creation', () async {
      // Arrange - Use a clearly invalid pass ID format
      const invalidPassId = 'INVALID';

      // Mock PassId.fromString to throw DomainException for invalid format
      // Note: In real implementation, this would happen in PassId.fromString()

      final result = await useCase(invalidPassId);
      result.isLeft();

      // Act & Assert
      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        // The DomainException should be caught and converted to ValidationFailure
        expect(failure, isA<ValidationFailure>());
        // The exact error message would depend on PassId.fromString() implementation
        expect(failure.message, isNotEmpty);
      }, (passDTO) => fail('Should not return success'));
    });

    test(
      'should handle domain exception and convert to validation failure',
      () async {
        // Arrange
        const passId = 'BP12345678';

        when(
          mockRepository.findByPassId(any),
        ).thenThrow(DomainException('Invalid pass ID format'));

        // Act
        final result = await useCase(passId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, equals('Invalid pass ID format'));
        }, (passDTO) => fail('Should not return success'));
      },
    );

    test('should handle unexpected exception', () async {
      // Arrange
      const passId = 'BP12345678';

      when(
        mockRepository.findByPassId(any),
      ).thenThrow(Exception('Unexpected database error'));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<UnknownFailure>());
        expect(
          failure.message,
          contains('Failed to get boarding pass details'),
        );
        expect(failure.message, contains('Unexpected database error'));
      }, (passDTO) => fail('Should not return success'));
    });

    test('should validate pass ID format correctly', () async {
      // Arrange
      const validPassId = 'BP12345678';

      when(
        mockRepository.findByPassId(any),
      ).thenAnswer((_) async => Right(mockBoardingPass));

      // Act
      final result = await useCase(validPassId);

      // Assert
      expect(result.isRight(), isTrue);

      // Verify that PassId.fromString was called with correct value
      // This is implicitly tested by successful execution
      verify(
        mockRepository.findByPassId(
          argThat(
            predicate<PassId>((passIdVO) => passIdVO.value == validPassId),
          ),
        ),
      ).called(1);
    });

    test('should convert domain entity to DTO correctly', () async {
      // Arrange
      const passId = 'BP12345678';

      when(
        mockRepository.findByPassId(any),
      ).thenAnswer((_) async => Right(mockBoardingPass));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTO) {
        // Verify all required DTO fields are populated
        expect(passDTO.passId, isNotEmpty);
        expect(passDTO.memberNumber, isNotEmpty);
        expect(passDTO.flightNumber, isNotEmpty);
        expect(passDTO.seatNumber, isNotEmpty);
        expect(passDTO.issueTime, isNotNull);

        // Verify specific values match mock setup
        expect(passDTO.passId, equals('BP12345678'));
        expect(passDTO.memberNumber, equals('MB100001'));
        expect(passDTO.flightNumber, equals('BR857'));
        expect(passDTO.seatNumber, equals('12A'));
      });
    });

    test('should handle valid pass ID with leading/trailing spaces', () async {
      // Arrange
      const passIdWithSpaces = '  BP12345678  ';
      const expectedPassId = 'BP12345678';

      when(
        mockRepository.findByPassId(any),
      ).thenAnswer((_) async => Right(mockBoardingPass));

      // Act
      final result = await useCase(passIdWithSpaces);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTO) {
        expect(passDTO.passId, equals(expectedPassId));
      });
    });

    test('should handle repository timeout gracefully', () async {
      // Arrange
      const passId = 'BP12345678';

      when(
        mockRepository.findByPassId(any),
      ).thenAnswer((_) async => Left(NetworkFailure('Request timeout')));

      // Act
      final result = await useCase(passId);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, equals('Request timeout'));
      }, (passDTO) => fail('Should not return success'));
    });
  });
}
