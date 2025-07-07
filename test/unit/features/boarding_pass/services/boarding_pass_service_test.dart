import 'package:app/features/boarding_pass/enums/pass_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:app/features/boarding_pass/services/boarding_pass_service.dart';
import 'package:app/features/boarding_pass/repositories/boarding_pass_repository.dart';
import 'package:app/features/boarding_pass/entities/boarding_pass.dart';
import 'package:app/features/boarding_pass/value_objects/seat_number.dart';
import 'package:app/features/boarding_pass/value_objects/flight_schedule_snapshot.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:app/features/flight/domain/entities/flight.dart';
import 'package:app/features/flight/domain/value_objects/flight_schedule.dart';
import 'package:app/core/failures/failure.dart';

import 'boarding_pass_service_test.mocks.dart';

@GenerateMocks([BoardingPassRepository])
void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('BoardingPassService Tests', () {
    late BoardingPassService service;
    late MockBoardingPassRepository mockRepository;
    late Member testMember;
    late Flight testFlight;
    late SeatNumber testSeatNumber;

    setUp(() {
      mockRepository = MockBoardingPassRepository();
      service = BoardingPassService(mockRepository);

      testMember = Member.create(
        memberNumber: 'AA123456',
        fullName: '王小明',
        tier: MemberTier.gold,
        email: 'test@example.com',
        phone: '+886912345678',
      );

      final now = TZDateTime.now(local);
      final boardingTime = now.add(const Duration(hours: 2));
      final departureTime = boardingTime.add(const Duration(hours: 1));

      final schedule = FlightSchedule.create(
        departureTime: departureTime,
        boardingTime: boardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
      );

      testFlight = Flight.create(
        flightNumber: 'BR857',
        schedule: schedule,
        aircraftType: 'A350',
      );

      testSeatNumber = SeatNumber.create('12A');
    });

    test('should create boarding pass successfully', () async {
      when(
        mockRepository.findActiveBoardingPasses(any),
      ).thenAnswer((_) async => const Right([]));
      when(mockRepository.save(any)).thenAnswer((_) async => const Right(null));

      final result = await service.createBoardingPass(
        member: testMember,
        flight: testFlight,
        seatNumber: testSeatNumber,
      );

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (boardingPass) {
        expect(boardingPass.memberNumber, equals(testMember.memberNumber));
        expect(boardingPass.flightNumber, equals(testFlight.flightNumber));
        expect(boardingPass.seatNumber, equals(testSeatNumber));
      });

      verify(mockRepository.findActiveBoardingPasses(any)).called(1);
      verify(mockRepository.save(any)).called(1);
    });

    test('should fail to create boarding pass for ineligible member', () async {
      final suspendedMember = Member.create(
        memberNumber: 'BB123456',
        fullName: '李小華',
        tier: MemberTier.suspended,
        email: 'test2@example.com',
        phone: '+886987654321',
      );

      final result = await service.createBoardingPass(
        member: suspendedMember,
        flight: testFlight,
        seatNumber: testSeatNumber,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (boardingPass) => fail('Should fail'),
      );
    });

    test('should fail to create duplicate boarding pass', () async {
      final existingPass = BoardingPass.create(
        memberNumber: testMember.memberNumber,
        flightNumber: testFlight.flightNumber,
        seatNumber: testSeatNumber,
        scheduleSnapshot: FlightScheduleSnapshot.fromSchedule(
          testFlight.schedule,
          snapshotTime: TZDateTime.now(local),
        ),
      );

      when(
        mockRepository.findActiveBoardingPasses(any),
      ).thenAnswer((_) async => Right([existingPass]));

      final result = await service.createBoardingPass(
        member: testMember,
        flight: testFlight,
        seatNumber: testSeatNumber,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (boardingPass) => fail('Should fail'),
      );
    });

    test('should activate boarding pass successfully', () async {
      final now = TZDateTime.now(local);
      final departureTime = now.add(const Duration(hours: 2));
      final boardingTime = departureTime.subtract(const Duration(hours: 1));

      final snapshot = FlightScheduleSnapshot.create(
        departureTime: departureTime,
        boardingTime: boardingTime,
        departureAirport: 'TPE',
        arrivalAirport: 'NRT',
        gateNumber: 'A12',
        snapshotTime: now,
      );

      final boardingPass = BoardingPass.create(
        memberNumber: testMember.memberNumber,
        flightNumber: testFlight.flightNumber,
        seatNumber: testSeatNumber,
        scheduleSnapshot: snapshot,
      );

      when(
        mockRepository.findByPassId(any),
      ).thenAnswer((_) async => Right(boardingPass));
      when(mockRepository.save(any)).thenAnswer((_) async => const Right(null));

      final result = await service.activateBoardingPass(boardingPass.passId);

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not fail'), (activatedPass) {
        expect(activatedPass.status, equals(PassStatus.activated));
      });
    });

    test('should handle repository failure', () async {
      when(
        mockRepository.findActiveBoardingPasses(any),
      ).thenAnswer((_) async => const Left(NetworkFailure('Network error')));

      final result = await service.createBoardingPass(
        member: testMember,
        flight: testFlight,
        seatNumber: testSeatNumber,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (boardingPass) => fail('Should fail'),
      );
    });
  });
}
