import 'dart:io';

import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';
import 'package:app/features/boarding_pass/domain/value_objects/flight_schedule_snapshot.dart';
import 'package:app/features/boarding_pass/domain/value_objects/pass_id.dart';
import 'package:app/features/boarding_pass/domain/value_objects/qr_code_data.dart';
import 'package:app/features/boarding_pass/domain/value_objects/seat_number.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:app/objectbox.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/boarding_pass/application/use_cases/get_boarding_passes_for_member_use_case.dart';
import 'package:app/features/boarding_pass/domain/services/boarding_pass_service.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../../helpers/test_qrcode_helper.dart';
import '../../../../../helpers/test_timezone_helper.dart';
import 'get_boarding_passes_for_member_use_case_test.mocks.dart';

class TestTimeConstants {
  static final baseTime = DateTime(
    2024,
    1,
    15,
    12,
    0,
    0,
  ); // Fixed reference time
  static final tomorrow = baseTime.add(const Duration(days: 1)); // 2024-01-16
  static final yesterday = baseTime.subtract(
    const Duration(days: 1),
  ); // 2024-01-14
  static final fiveDaysAgo = baseTime.subtract(
    const Duration(days: 5),
  ); // 2024-01-10

  static String formatDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

@GenerateNiceMocks([MockSpec<BoardingPassService>(), MockSpec<BoardingPass>()])
void main() {
  group('GetBoardingPassesForMemberUseCase', () {
    late GetBoardingPassesForMemberUseCase useCase;
    late MockBoardingPassService mockBoardingPassService;
    late List<MockBoardingPass> mockBoardingPasses;
    late Directory tempDir;
    late ObjectBox objectBox;
    late List<String> realQRCodes;

    void setupMockBoardingPass(
      MockBoardingPass mockPass,
      String passIdStr,
      String memberNumberStr,
      String flightNumberStr,
      String seatNumberStr,
      PassStatus status,
      DateTime departureDateTime,
    ) {
      final passId = PassId(passIdStr);
      final memberNumber = MemberNumber.create(memberNumberStr);
      final flightNumber = FlightNumber.create(flightNumberStr);
      final seatNumber = SeatNumber.create(seatNumberStr);
      final departureTime = tz.TZDateTime.from(departureDateTime, tz.local);
      final boardingTime = departureTime.subtract(const Duration(minutes: 30));
      final qrCode = QRCodeData.fromQRString(realQRCodes.first);

      when(mockPass.passId).thenReturn(passId);
      when(mockPass.memberNumber).thenReturn(memberNumber);
      when(mockPass.flightNumber).thenReturn(flightNumber);
      when(mockPass.seatNumber).thenReturn(seatNumber);
      when(mockPass.status).thenReturn(status);
      when(mockPass.scheduleSnapshot).thenReturn(
        FlightScheduleSnapshot.create(
          departureTime: departureTime,
          boardingTime: boardingTime,
          departureAirport: 'TPE',
          arrivalAirport: 'NRT',
          gateNumber: 'A12',
          snapshotTime: departureTime.subtract(const Duration(hours: 1)),
        ),
      );
      when(mockPass.qrCode).thenReturn(qrCode);
      when(
        mockPass.issueTime,
      ).thenReturn(departureTime.subtract(const Duration(hours: 3)));
    }

    setUpAll(() async {
      TestTimezoneHelper.setupForTesting();

      // Create test database in temporary directory
      tempDir = await Directory.systemTemp.createTemp(
        'objectbox_qr_scanner_test_',
      );

      try {
        // Initialize ObjectBox with test database
        final store = await openStore(directory: tempDir.path);
        objectBox = ObjectBox.createFromStore(store);

        // Seed test data with real QR codes
        await TestQrcodeHelper.seedTestDataWithRealQRCodes(objectBox);

        // Get real QR codes for testing
        realQRCodes = await TestQrcodeHelper.generateRealQRCodes(objectBox);

        debugPrint('Test ObjectBox initialized at: ${tempDir.path}');
        debugPrint('Generated ${realQRCodes.length} real QR codes for testing');
      } catch (e) {
        debugPrint('Failed to initialize test ObjectBox: $e');
        rethrow;
      }
    });

    tearDownAll(() async {
      // Cleanup test database
      objectBox.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    setUp(() {
      mockBoardingPassService = MockBoardingPassService();
      useCase = GetBoardingPassesForMemberUseCase(mockBoardingPassService);

      // Create multiple mock boarding passes
      mockBoardingPasses = [
        MockBoardingPass(),
        MockBoardingPass(),
        MockBoardingPass(),
      ];

      // Setup mock boarding passes with fixed times
      setupMockBoardingPass(
        mockBoardingPasses[0],
        'BP12345001',
        'MB100001',
        'BR101',
        '1A',
        PassStatus.activated,
        TestTimeConstants.tomorrow, // 2024-01-16
      );
      setupMockBoardingPass(
        mockBoardingPasses[1],
        'BP12345002',
        'MB100001',
        'BR102',
        '2B',
        PassStatus.used,
        TestTimeConstants.yesterday, // 2024-01-14
      );
      setupMockBoardingPass(
        mockBoardingPasses[2],
        'BP12345003',
        'MB100001',
        'BR103',
        '3C',
        PassStatus.expired,
        TestTimeConstants.fiveDaysAgo, // 2024-01-10
      );
    });

    test('should get all boarding passes for member successfully', () async {
      // Arrange
      final searchParams = BoardingPassSearchDTO(
        memberNumber: 'MB100001',
        activeOnly: false,
      );

      when(
        mockBoardingPassService.getBoardingPassesForMember(any),
      ).thenAnswer((_) async => Right(mockBoardingPasses));

      // Act
      final result = await useCase(searchParams);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTOs) {
        expect(passDTOs, hasLength(3));
        expect(passDTOs[0].passId, equals('BP12345001'));
        expect(passDTOs[1].passId, equals('BP12345002'));
        expect(passDTOs[2].passId, equals('BP12345003'));
      });

      verify(mockBoardingPassService.getBoardingPassesForMember(any)).called(1);
      verifyNever(
        mockBoardingPassService.getActiveBoardingPassesForMember(any),
      );
    });

    test(
      'should get only active boarding passes when activeOnly is true',
      () async {
        // Arrange
        final searchParams = BoardingPassSearchDTO(
          memberNumber: 'MB100001',
          activeOnly: true,
        );

        final activePasses = [mockBoardingPasses[0]]; // Only the active one

        when(
          mockBoardingPassService.getActiveBoardingPassesForMember(any),
        ).thenAnswer((_) async => Right(activePasses));

        // Act
        final result = await useCase(searchParams);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Should not return failure'), (passDTOs) {
          expect(passDTOs, hasLength(1));
          expect(passDTOs[0].passId, equals('BP12345001'));
        });

        verify(
          mockBoardingPassService.getActiveBoardingPassesForMember(any),
        ).called(1);
        verifyNever(mockBoardingPassService.getBoardingPassesForMember(any));
      },
    );

    test('should return error for empty member number', () async {
      // Arrange
      final searchParams = BoardingPassSearchDTO(memberNumber: '');

      // Act
      final result = await useCase(searchParams);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, equals('Member number is required'));
      }, (passDTOs) => fail('Should not return success'));

      verifyNever(mockBoardingPassService.getBoardingPassesForMember(any));
      verifyNever(
        mockBoardingPassService.getActiveBoardingPassesForMember(any),
      );
    });

    test('should return error for null member number', () async {
      // Arrange
      final searchParams = BoardingPassSearchDTO(memberNumber: null);

      // Act
      final result = await useCase(searchParams);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, equals('Member number is required'));
      }, (passDTOs) => fail('Should not return success'));
    });

    test('should return error for whitespace-only member number', () async {
      // Arrange
      final searchParams = BoardingPassSearchDTO(memberNumber: '   ');

      // Act
      final result = await useCase(searchParams);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, equals('Member number is required'));
      }, (passDTOs) => fail('Should not return success'));
    });

    test('should filter by status when provided', () async {
      // Arrange
      final searchParams = BoardingPassSearchDTO(
        memberNumber: 'MB100001',
        status: PassStatus.activated,
      );

      when(
        mockBoardingPassService.getBoardingPassesForMember(any),
      ).thenAnswer((_) async => Right(mockBoardingPasses));

      // Act
      final result = await useCase(searchParams);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTOs) {
        expect(passDTOs, hasLength(1));
        expect(passDTOs[0].passId, equals('BP12345001'));
      });
    });

    test('should filter by flight number when provided', () async {
      // Arrange
      final searchParams = BoardingPassSearchDTO(
        memberNumber: 'MB100001',
        flightNumber: 'BR102',
      );

      when(
        mockBoardingPassService.getBoardingPassesForMember(any),
      ).thenAnswer((_) async => Right(mockBoardingPasses));

      // Act
      final result = await useCase(searchParams);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTOs) {
        expect(passDTOs, hasLength(1));
        expect(passDTOs[0].passId, equals('BP12345002'));
      });
    });

    test('should filter by departure date when provided', () async {
      // Arrange
      final tomorrowDateStr = TestTimeConstants.formatDateString(
        TestTimeConstants.tomorrow,
      );

      final searchParams = BoardingPassSearchDTO(
        memberNumber: 'MB100001',
        departureDate: tomorrowDateStr,
      );

      when(
        mockBoardingPassService.getBoardingPassesForMember(any),
      ).thenAnswer((_) async => Right(mockBoardingPasses));

      // Act
      final result = await useCase(searchParams);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTOs) {
        expect(passDTOs, hasLength(1));
        expect(passDTOs[0].passId, equals('BP12345001'));
      });
    });

    test('should filter by departure date range when provided', () async {
      // Arrange
      final yesterday = TestTimeConstants.yesterday;
      final tomorrow = TestTimeConstants.tomorrow;

      final yesterdayStr = TestTimeConstants.formatDateString(
        yesterday,
      ); // '2024-01-14'
      final tomorrowStr = TestTimeConstants.formatDateString(
        tomorrow,
      ); // '2024-01-16'

      final searchParams = BoardingPassSearchDTO(
        memberNumber: 'MB100001',
        departureFromDate: yesterdayStr,
        departureToDate: tomorrowStr,
      );

      when(
        mockBoardingPassService.getBoardingPassesForMember(any),
      ).thenAnswer((_) async => Right(mockBoardingPasses));

      // Act
      final result = await useCase(searchParams);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTOs) {
        expect(passDTOs, hasLength(2));

        // Verify specific passes are included
        final passIds = passDTOs.map((dto) => dto.passId).toSet();
        expect(passIds, contains('BP12345001'));
        expect(passIds, contains('BP12345002'));
        expect(passIds, isNot(contains('BP12345003')));
      });
    });

    test('should apply pagination when offset and limit provided', () async {
      // Arrange
      final searchParams = BoardingPassSearchDTO(
        memberNumber: 'MB100001',
        offset: 1,
        limit: 1,
      );

      when(
        mockBoardingPassService.getBoardingPassesForMember(any),
      ).thenAnswer((_) async => Right(mockBoardingPasses));

      // Act
      final result = await useCase(searchParams);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTOs) {
        expect(passDTOs, hasLength(1));
        expect(
          passDTOs[0].passId,
          equals('BP12345002'),
        ); // Second item after offset
      });
    });

    test('should apply offset only when limit not provided', () async {
      // Arrange
      final searchParams = BoardingPassSearchDTO(
        memberNumber: 'MB100001',
        offset: 1,
      );

      when(
        mockBoardingPassService.getBoardingPassesForMember(any),
      ).thenAnswer((_) async => Right(mockBoardingPasses));

      // Act
      final result = await useCase(searchParams);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTOs) {
        expect(passDTOs, hasLength(2)); // Should return items after offset
        expect(passDTOs[0].passId, equals('BP12345002'));
        expect(passDTOs[1].passId, equals('BP12345003'));
      });
    });

    test('should handle service failure', () async {
      // Arrange
      final searchParams = BoardingPassSearchDTO(memberNumber: 'MB100001');

      when(mockBoardingPassService.getBoardingPassesForMember(any)).thenAnswer(
        (_) async => Left(DatabaseFailure('Database connection error')),
      );

      // Act
      final result = await useCase(searchParams);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<DatabaseFailure>());
        expect(failure.message, equals('Database connection error'));
      }, (passDTOs) => fail('Should not return success'));
    });

    test('should handle unexpected exception', () async {
      // Arrange
      final searchParams = BoardingPassSearchDTO(memberNumber: 'MB100001');

      when(
        mockBoardingPassService.getBoardingPassesForMember(any),
      ).thenThrow(Exception('Unexpected error'));

      // Act
      final result = await useCase(searchParams);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<UnknownFailure>());
        expect(failure.message, contains('Failed to get boarding passes'));
      }, (passDTOs) => fail('Should not return success'));
    });

    test('should return empty list when no passes found', () async {
      // Arrange
      final searchParams = BoardingPassSearchDTO(memberNumber: 'MB999999');

      when(
        mockBoardingPassService.getBoardingPassesForMember(any),
      ).thenAnswer((_) async => Right(<BoardingPass>[]));

      // Act
      final result = await useCase(searchParams);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTOs) {
        expect(passDTOs, isEmpty);
      });
    });

    test('should handle multiple filters combined', () async {
      // Arrange
      final searchParams = BoardingPassSearchDTO(
        memberNumber: 'MB100001',
        status: PassStatus.activated,
        flightNumber: 'BR101',
        limit: 5,
      );

      when(
        mockBoardingPassService.getBoardingPassesForMember(any),
      ).thenAnswer((_) async => Right(mockBoardingPasses));

      // Act
      final result = await useCase(searchParams);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTOs) {
        expect(passDTOs, hasLength(1));
        expect(passDTOs[0].passId, equals('BP12345001'));
      });
    });

    test('should ignore empty flight number filter', () async {
      // Arrange
      final searchParams = BoardingPassSearchDTO(
        memberNumber: 'MB100001',
        flightNumber: '',
      );

      when(
        mockBoardingPassService.getBoardingPassesForMember(any),
      ).thenAnswer((_) async => Right(mockBoardingPasses));

      // Act
      final result = await useCase(searchParams);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTOs) {
        expect(passDTOs, hasLength(3)); // Should return all passes
      });
    });

    test('should handle zero limit gracefully', () async {
      // Arrange
      final searchParams = BoardingPassSearchDTO(
        memberNumber: 'MB100001',
        limit: 0,
      );

      when(
        mockBoardingPassService.getBoardingPassesForMember(any),
      ).thenAnswer((_) async => Right(mockBoardingPasses));

      // Act
      final result = await useCase(searchParams);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (passDTOs) {
        expect(
          passDTOs,
          hasLength(3),
        ); // Should return all passes when limit is 0
      });
    });
  });
}
