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
import 'package:app/features/boarding_pass/application/use_cases/create_boarding_pass_use_case.dart';
import 'package:app/features/boarding_pass/domain/services/boarding_pass_service.dart';
import 'package:app/features/member/domain/repositories/member_repository.dart';
import 'package:app/features/flight/domain/repositories/flight_repository.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';
import 'package:app/features/boarding_pass/domain/entities/boarding_pass.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/flight/domain/entities/flight.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:app/features/flight/domain/enums/flight_status.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';
import 'create_boarding_pass_use_case_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<BoardingPassService>(),
  MockSpec<MemberRepository>(),
  MockSpec<FlightRepository>(),
  MockSpec<BoardingPass>(),
  MockSpec<Member>(),
  MockSpec<Flight>(),
])
void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('CreateBoardingPassUseCase', () {
    late CreateBoardingPassUseCase useCase;
    late MockBoardingPassService mockBoardingPassService;
    late MockMemberRepository mockMemberRepository;
    late MockFlightRepository mockFlightRepository;
    late MockBoardingPass mockBoardingPass;
    late MockMember mockMember;
    late MockFlight mockFlight;

    setUp(() {
      mockBoardingPassService = MockBoardingPassService();
      mockMemberRepository = MockMemberRepository();
      mockFlightRepository = MockFlightRepository();
      mockBoardingPass = MockBoardingPass();
      mockMember = MockMember();
      mockFlight = MockFlight();

      useCase = CreateBoardingPassUseCase(
        mockBoardingPassService,
        mockMemberRepository,
        mockFlightRepository,
      );

      // Setup default mock behaviors
      when(mockMember.tier).thenReturn(MemberTier.gold);
      when(mockFlight.status).thenReturn(FlightStatus.scheduled);
    });

    test('should create boarding pass successfully with valid data', () async {
      // Arrange
      final request = CreateBoardingPassDTO(
        memberNumber: 'MB100001',
        flightNumber: 'BR857',
        seatNumber: '12A',
      );

      when(
        mockMemberRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => Right(mockMember));
      when(
        mockFlightRepository.findByFlightNumber(any),
      ).thenAnswer((_) async => Right(mockFlight));
      when(
        mockBoardingPassService.createBoardingPass(
          member: anyNamed('member'),
          flight: anyNamed('flight'),
          seatNumber: anyNamed('seatNumber'),
        ),
      ).thenAnswer((_) async => Right(mockBoardingPass));

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

      // Act
      final result = await useCase(request);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isTrue);
        expect(response.boardingPass, isNotNull);
        expect(response.metadata?['memberTier'], equals('gold'));
        expect(response.metadata?['flightStatus'], equals('scheduled'));
      });

      verify(mockMemberRepository.findByMemberNumber(any)).called(1);
      verify(mockFlightRepository.findByFlightNumber(any)).called(1);
      verify(
        mockBoardingPassService.createBoardingPass(
          member: anyNamed('member'),
          flight: anyNamed('flight'),
          seatNumber: anyNamed('seatNumber'),
        ),
      ).called(1);
    });

    test('should return error when member not found', () async {
      // Arrange
      final request = CreateBoardingPassDTO(
        memberNumber: 'MB000000',
        flightNumber: 'BR857',
        seatNumber: '12A',
      );

      when(
        mockMemberRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => Right(null));

      // Act
      final result = await useCase(request);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Member not found: MB000000'));
        expect(response.errorCode, equals('MEMBER_NOT_FOUND'));
        expect(response.boardingPass, isNull);
      });

      verify(mockMemberRepository.findByMemberNumber(any)).called(1);
      verifyNever(mockFlightRepository.findByFlightNumber(any));
      verifyNever(
        mockBoardingPassService.createBoardingPass(
          member: anyNamed('member'),
          flight: anyNamed('flight'),
          seatNumber: anyNamed('seatNumber'),
        ),
      );
    });

    test('should return error when flight not found', () async {
      // Arrange
      final request = CreateBoardingPassDTO(
        memberNumber: 'MB100001',
        flightNumber: 'ZZ999',
        seatNumber: '12A',
      );

      when(
        mockMemberRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => Right(mockMember));
      when(
        mockFlightRepository.findByFlightNumber(any),
      ).thenAnswer((_) async => Right(null));

      // Act
      final result = await useCase(request);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Flight not found: ZZ999'));
        expect(response.errorCode, equals('FLIGHT_NOT_FOUND'));
        expect(response.boardingPass, isNull);
      });
    });

    test('should return validation error for empty member number', () async {
      // Arrange
      final request = CreateBoardingPassDTO(
        memberNumber: '',
        flightNumber: 'BR857',
        seatNumber: '12A',
      );

      // Act
      final result = await useCase(request);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Member number cannot be empty'));
        expect(response.errorCode, equals('VALIDATION_ERROR'));
      });

      verifyNever(mockMemberRepository.findByMemberNumber(any));
    });

    test('should return validation error for empty flight number', () async {
      // Arrange
      final request = CreateBoardingPassDTO(
        memberNumber: 'MB100001',
        flightNumber: '',
        seatNumber: '12A',
      );

      // Act
      final result = await useCase(request);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Flight number cannot be empty'));
        expect(response.errorCode, equals('VALIDATION_ERROR'));
      });
    });

    test('should return validation error for empty seat number', () async {
      // Arrange
      final request = CreateBoardingPassDTO(
        memberNumber: 'MB100001',
        flightNumber: 'BR857',
        seatNumber: '',
      );

      // Act
      final result = await useCase(request);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Seat number cannot be empty'));
        expect(response.errorCode, equals('VALIDATION_ERROR'));
      });
    });

    test('should handle domain exception from boarding pass service', () async {
      // Arrange
      final request = CreateBoardingPassDTO(
        memberNumber: 'MB100001',
        flightNumber: 'BR857',
        seatNumber: '12A',
      );

      when(
        mockMemberRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => Right(mockMember));
      when(
        mockFlightRepository.findByFlightNumber(any),
      ).thenAnswer((_) async => Right(mockFlight));
      when(
        mockBoardingPassService.createBoardingPass(
          member: anyNamed('member'),
          flight: anyNamed('flight'),
          seatNumber: anyNamed('seatNumber'),
        ),
      ).thenAnswer((_) async => Left(ValidationFailure('Seat already taken')));

      // Act
      final result = await useCase(request);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, equals('Seat already taken'));
        expect(response.errorCode, equals('VALIDATION_ERROR'));
      });
    });

    test('should handle member repository failure', () async {
      // Arrange
      final request = CreateBoardingPassDTO(
        memberNumber: 'MB100001',
        flightNumber: 'BR857',
        seatNumber: '12A',
      );

      when(mockMemberRepository.findByMemberNumber(any)).thenAnswer(
        (_) async => Left(DatabaseFailure('Database connection error')),
      );

      // Act
      final result = await useCase(request);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, contains('Failed to retrieve member'));
        expect(response.errorCode, equals('MEMBER_ERROR'));
      });
    });

    test('should handle flight repository failure', () async {
      // Arrange
      final request = CreateBoardingPassDTO(
        memberNumber: 'MB100001',
        flightNumber: 'BR857',
        seatNumber: '12A',
      );

      when(
        mockMemberRepository.findByMemberNumber(any),
      ).thenAnswer((_) async => Right(mockMember));
      when(
        mockFlightRepository.findByFlightNumber(any),
      ).thenAnswer((_) async => Left(NetworkFailure('Network timeout')));

      // Act
      final result = await useCase(request);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Should not return failure'), (response) {
        expect(response.success, isFalse);
        expect(response.errorMessage, contains('Failed to retrieve flight'));
        expect(response.errorCode, equals('FLIGHT_ERROR'));
      });
    });
  });
}
